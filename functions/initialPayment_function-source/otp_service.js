'use strict';

const crypto = require('node:crypto');

class OtpError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function normalizePhone(value) {
  if (typeof value !== 'string' || !/^\+?[1-9]\d{7,14}$/.test(value)) {
    throw new OtpError('invalid-argument', 'Invalid phone number.');
  }
  return value.replace(/^\+/, '');
}

function parseTestPhoneCodes(value) {
  const parsed = JSON.parse(value);
  if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('AUTH_TEST_PHONE_CODES must be a JSON object.');
  }
  const entries = Object.entries(parsed);
  if (entries.length > 20) throw new Error('Too many test phone numbers.');
  const codes = Object.create(null);
  for (const [phone, code] of entries) {
    if (normalizePhone(phone) !== phone || typeof code !== 'string' || !/^\d{6}$/.test(code)) {
      throw new Error('Invalid test phone configuration.');
    }
    codes[phone] = code;
  }
  return codes;
}

// Pure service dependencies let tests exercise transactions without sending SMS.
function createOtpService({ db, auth, sendSms, pepper, timestamp,
  now = Date.now, randomCode = () => String(crypto.randomInt(0, 1000000)).padStart(6, '0'),
  nonce = () => crypto.randomUUID(), testPhoneCodes = {} }) {
  if (typeof pepper !== 'string' || pepper.length < 32) {
    throw new Error('OTP_HMAC_KEY must contain at least 32 characters.');
  }
  const hash = value => crypto.createHmac('sha256', pepper).update(value).digest('hex');
  const challengeRef = phone => db.collection('_otp_challenges').doc(hash(`phone:${phone}`));
  const hour = 60 * 60 * 1000;
  const ttl = 5 * 60 * 1000;

  async function sendCode(phoneValue, ip) {
    const phone = normalizePhone(phoneValue);
    if (typeof ip !== 'string' || ip.length === 0) {
      throw new OtpError('unavailable', 'Unable to validate request origin.');
    }
    const time = now();
    const testCode = testPhoneCodes[phone];
    const code = testCode || randomCode();
    const challengeId = nonce();
    const ref = challengeRef(phone);
    const ipRef = db.collection('_otp_rate_limits').doc(hash(`ip:${ip}`));
    const budgetRef = db.collection('_otp_rate_limits').doc('daily_sms_budget');
    await db.runTransaction(async tx => {
      const [previousSnap, ipSnap, budgetSnap] = await Promise.all([
        tx.get(ref), tx.get(ipRef), tx.get(budgetRef),
      ]);
      const previous = previousSnap.data() || {};
      const origin = ipSnap.data() || {};
      const budget = budgetSnap.data() || {};
      const phoneCount = previous.windowStart > time - hour ? previous.sendCount || 0 : 0;
      const ipCount = origin.windowStart > time - hour ? origin.sendCount || 0 : 0;
      const day = Math.floor(time / (24 * hour));
      const dailyCount = budget.day === day ? budget.sendCount || 0 : 0;
      if (previous.nextSendAt > time || phoneCount >= 5 || ipCount >= 20 ||
          (!testCode && dailyCount >= 500)) {
        throw new OtpError('resource-exhausted', 'Wait before requesting another code.');
      }
      tx.set(ref, {
        challengeId, digest: hash(`${phone}:${challengeId}:${code}`), attempts: 0,
        status: 'sending', expiresAt: time + ttl, nextSendAt: time + 60000,
        windowStart: phoneCount ? previous.windowStart : time, sendCount: phoneCount + 1,
        cleanupAt: timestamp(time + 24 * hour),
      });
      tx.set(ipRef, {
        windowStart: ipCount ? origin.windowStart : time, sendCount: ipCount + 1,
        cleanupAt: timestamp(time + 24 * hour),
      });
      if (!testCode) tx.set(budgetRef, { day, sendCount: dailyCount + 1 });
    });

    try {
      if (!testCode) await sendSms(phone, code);
    } catch (_) {
      // Never log provider errors: they can contain API headers and the OTP.
      await db.runTransaction(async tx => {
        const current = (await tx.get(ref)).data();
        if (current?.challengeId === challengeId) {
          tx.update(ref, { status: 'failed', digest: null });
        }
      });
      throw new OtpError('unavailable', 'Failed to send code.');
    }

    const delivered = await db.runTransaction(async tx => {
      const current = (await tx.get(ref)).data();
      if (current?.challengeId !== challengeId || current.status !== 'sending') return false;
      tx.update(ref, { status: 'ready' });
      return true;
    });
    if (!delivered) throw new OtpError('aborted', 'A newer code has been requested.');
    return { sent: true, retry_after: 60 };
  }

  async function verifyCode(phoneValue, code) {
    const phone = normalizePhone(phoneValue);
    if (typeof code !== 'string' || !/^\d{6}$/.test(code)) {
      throw new OtpError('invalid-argument', 'Invalid code provided.');
    }
    const ref = challengeRef(phone);
    const verified = await db.runTransaction(async tx => {
      const data = (await tx.get(ref)).data();
      if (!data || data.status !== 'ready' || data.expiresAt <= now() || data.attempts >= 5) {
        return false;
      }
      const expected = hash(`${phone}:${data.challengeId}:${code}`);
      const matches = typeof data.digest === 'string' && data.digest.length === expected.length &&
        crypto.timingSafeEqual(Buffer.from(data.digest), Buffer.from(expected));
      // Commit failures too: throwing inside the transaction would undo the counter.
      tx.update(ref, matches
        ? { status: 'consumed', digest: null, attempts: data.attempts + 1 }
        : { attempts: data.attempts + 1 });
      return matches;
    });
    if (!verified) throw new OtpError('unauthenticated', 'Invalid code provided.');

    // Keep the legacy deterministic UID used by the existing client. Never trust
    // a client-editable users.phone query to decide which account to sign into.
    const legacyUid = `phone_${phone}`;
    let phoneUser;
    let legacyUser;
    try { phoneUser = await auth.getUserByPhoneNumber(`+${phone}`); }
    catch (error) { if (error.code !== 'auth/user-not-found') throw error; }
    try { legacyUser = await auth.getUser(legacyUid); }
    catch (error) { if (error.code !== 'auth/user-not-found') throw error; }
    if (phoneUser && legacyUser && phoneUser.uid !== legacyUser.uid) {
      throw new OtpError('failed-precondition', 'Account mapping requires review.');
    }
    const user = phoneUser || legacyUser;
    if (user?.disabled) throw new OtpError('permission-denied', 'Account is disabled.');
    if (legacyUser?.phoneNumber && legacyUser.phoneNumber !== `+${phone}`) {
      throw new OtpError('failed-precondition', 'Account mapping requires review.');
    }
    const uid = user?.uid || legacyUid;
    const profile = (await db.collection('users').doc(uid).get()).data();
    if (profile?.banned === true) throw new OtpError('permission-denied', 'Account is disabled.');
    const token = await auth.createCustomToken(uid);
    return { token };
  }

  return { sendCode, verifyCode };
}

module.exports = { createOtpService, normalizePhone, parseTestPhoneCodes, OtpError };
