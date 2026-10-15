'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createOtpService, normalizePhone, parseTestPhoneCodes } =
  require('../initialPayment_function-source/otp_service');

// Serialize commits like a Firestore transaction; changes apply only on success.
function memoryDb() {
  const documents = new Map();
  let queue = Promise.resolve();
  const snapshot = (ref, map) => ({ data: () => structuredClone(map.get(ref.path)) });
  return {
    documents,
    collection: collection => ({ doc: id => {
      const ref = { path: `${collection}/${id}` };
      ref.get = async () => snapshot(ref, documents);
      return ref;
    } }),
    runTransaction(action) {
      const result = queue.then(async () => {
        const pending = new Map(documents);
        const value = await action({
          get: async ref => snapshot(ref, pending),
          set: (ref, data) => pending.set(ref.path, structuredClone(data)),
          update: (ref, data) => pending.set(ref.path, { ...pending.get(ref.path), ...data }),
        });
        documents.clear();
        for (const [path, data] of pending) documents.set(path, data);
        return value;
      });
      queue = result.catch(() => {});
      return result;
    },
  };
}

function fixture(overrides = {}) {
  const db = memoryDb();
  const messages = [];
  const minted = [];
  let time = 100000000;
  let id = 0;
  const missing = async () => { throw Object.assign(new Error(), { code: 'auth/user-not-found' }); };
  const auth = {
    getUser: missing, getUserByPhoneNumber: missing,
    createCustomToken: async uid => { minted.push(uid); return `token:${uid}`; },
    ...overrides.auth,
  };
  const service = createOtpService({
    db, auth, pepper: 'unit-test-key-with-at-least-32-characters',
    testPhoneCodes: overrides.testPhoneCodes,
    timestamp: n => n, now: () => time, randomCode: () => '123456', nonce: () => `nonce-${++id}`,
    sendSms: overrides.sendSms || (async (phone, code) => { messages.push({ phone, code }); }),
  });
  return { db, service, messages, minted, advance: ms => { time += ms; } };
}

test('configured test phone codes work without sending SMS', async () => {
  const testPhoneCodes = Object.fromEntries(Array.from({ length: 15 }, (_, index) =>
    [String(16505550101 + index), String(index).padStart(6, '0')]));
  assert.equal(Object.keys(testPhoneCodes).length, 15);
  for (const [phone, code] of Object.entries(testPhoneCodes)) {
    const f = fixture({ testPhoneCodes });
    assert.deepEqual(await f.service.sendCode(`+${phone}`, '192.0.2.1'),
      { sent: true, retry_after: 60 });
    assert.equal(f.messages.length, 0);
    assert.equal(f.db.documents.has('_otp_rate_limits/daily_sms_budget'), false);
    assert.deepEqual(await f.service.verifyCode(phone, code), { token: `token:phone_${phone}` });
  }
});

test('test code cannot authenticate without a fresh challenge or with a wrong code', async () => {
  const f = fixture({ testPhoneCodes: { '16505550101': '000000' } });
  await assert.rejects(f.service.verifyCode('+16505550101', '000000'), { code: 'unauthenticated' });
  await f.service.sendCode('+16505550101', '192.0.2.1');
  await assert.rejects(f.service.verifyCode('+16505550101', '111111'), { code: 'unauthenticated' });
  assert.deepEqual(await f.service.verifyCode('+16505550101', '000000'),
    { token: 'token:phone_16505550101' });
});

test('without configured test codes the service sends a random OTP', async () => {
  const f = fixture();
  await f.service.sendCode('+16505550101', '192.0.2.1');
  assert.deepEqual(f.messages, [{ phone: '16505550101', code: '123456' }]);
  await assert.rejects(f.service.verifyCode('+16505550101', '000000'), { code: 'unauthenticated' });
});

test('test phone secret accepts only a bounded phone-to-six-digit-code object', () => {
  const codes = parseTestPhoneCodes('{"16505550101":"000000"}');
  assert.equal(codes['16505550101'], '000000');
  for (const value of ['[]', 'null', '{"+16505550101":"000000"}',
    '{"16505550101":123456}', '{"16505550101":"12345"}',
    JSON.stringify(Object.fromEntries(Array.from({ length: 21 }, (_, i) =>
      [String(79181000000 + i), '123456'])))]) {
    assert.throws(() => parseTestPhoneCodes(value));
  }
});

test('phone normalization preserves legacy UID digits and rejects paths/invalid inputs', () => {
  assert.equal(normalizePhone('+79991234567'), '79991234567');
  assert.equal(normalizePhone('79991234567'), '79991234567');
  for (const value of ['../user', '0', '', 79991234567, '+7 999 123 45 67']) {
    assert.throws(() => normalizePhone(value), { code: 'invalid-argument' });
  }
});

test('send response and stored challenge never contain plaintext OTP', async () => {
  const f = fixture();
  assert.deepEqual(await f.service.sendCode('79991234567', '192.0.2.1'), { sent: true, retry_after: 60 });
  assert.equal(f.messages[0].code, '123456');
  assert.ok(!JSON.stringify([...f.db.documents]).includes('123456'));
  assert.equal(f.minted.length, 0);
});

test('concurrent resend is limited atomically before billing provider', async () => {
  const f = fixture();
  const results = await Promise.allSettled([
    f.service.sendCode('79991234567', '192.0.2.1'), f.service.sendCode('79991234567', '192.0.2.1'),
  ]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(f.messages.length, 1);
  assert.equal(results.find(r => r.status === 'rejected').reason.code, 'resource-exhausted');
});

test('phone quota accepts five hourly sends and resets exactly at the hour boundary', async () => {
  const f = fixture();
  for (let i = 0; i < 5; i++) {
    if (i > 0) f.advance(60000);
    await f.service.sendCode('79991234567', `192.0.2.${i + 1}`);
  }
  f.advance(60000);
  await assert.rejects(f.service.sendCode('79991234567', '192.0.2.99'), { code: 'resource-exhausted' });
  assert.equal(f.messages.length, 5);
  f.advance(60 * 60 * 1000 - 5 * 60000);
  await f.service.sendCode('79991234567', '192.0.2.99');
  assert.equal(f.messages.length, 6);
});

test('resend cooldown blocks before one minute and permits the exact boundary', async () => {
  const f = fixture();
  await f.service.sendCode('79991234567', '192.0.2.1');
  f.advance(59999);
  await assert.rejects(f.service.sendCode('79991234567', '192.0.2.1'), { code: 'resource-exhausted' });
  f.advance(1);
  await f.service.sendCode('79991234567', '192.0.2.1');
  assert.equal(f.messages.length, 2);
});

test('IP quota accepts twenty distinct phones, rolls back rejected send, and resets hourly', async () => {
  const f = fixture();
  for (let i = 0; i < 20; i++) {
    await f.service.sendCode(String(79990000000 + i), '192.0.2.1');
  }
  await assert.rejects(f.service.sendCode('79990000020', '192.0.2.1'), { code: 'resource-exhausted' });
  assert.equal(f.messages.length, 20);
  // A rejected transaction must not consume that phone's own cooldown.
  await f.service.sendCode('79990000020', '192.0.2.2');
  f.advance(60 * 60 * 1000);
  await f.service.sendCode('79990000021', '192.0.2.1');
  assert.equal(f.messages.length, 22);
});

test('global daily budget blocks the next SMS and resets on the UTC day boundary', async () => {
  const f = fixture();
  await f.service.sendCode('79991234567', '192.0.2.1');
  const budgetPath = '_otp_rate_limits/daily_sms_budget';
  const budget = f.db.documents.get(budgetPath);
  f.db.documents.set(budgetPath, { ...budget, sendCount: 500 });
  await assert.rejects(f.service.sendCode('79991234568', '192.0.2.2'), { code: 'resource-exhausted' });
  assert.equal(f.messages.length, 1);
  f.advance((budget.day + 1) * 24 * 60 * 60 * 1000 - 100000000);
  await f.service.sendCode('79991234568', '192.0.2.2');
  assert.equal(f.db.documents.get(budgetPath).sendCount, 1);
  assert.equal(f.messages.length, 2);
});

test('provider failure cannot be reported as success or verified', async () => {
  const f = fixture({ sendSms: async () => { throw new Error('provider confidential response'); } });
  await assert.rejects(f.service.sendCode('79991234567', '192.0.2.1'), { code: 'unavailable' });
  await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'unauthenticated' });
  assert.equal(f.minted.length, 0);
});

test('five failed attempts remain committed and lock the challenge', async () => {
  const f = fixture();
  await f.service.sendCode('79991234567', '192.0.2.1');
  for (let i = 0; i < 5; i++) {
    await assert.rejects(f.service.verifyCode('79991234567', '000000'), { code: 'unauthenticated' });
  }
  await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'unauthenticated' });
  assert.equal(f.minted.length, 0);
});

test('expired challenge cannot mint a token', async () => {
  const f = fixture();
  await f.service.sendCode('79991234567', '192.0.2.1');
  f.advance(5 * 60 * 1000);
  await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'unauthenticated' });
});

test('parallel correct submissions mint exactly one token and keep existing UID scheme', async () => {
  const f = fixture();
  await f.service.sendCode('+79991234567', '192.0.2.1');
  const results = await Promise.allSettled([
    f.service.verifyCode('79991234567', '123456'), f.service.verifyCode('79991234567', '123456'),
  ]);
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.deepEqual(f.minted, ['phone_79991234567']);
  await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'unauthenticated' });
});

test('banned profile cannot mint a token even with correct code', async () => {
  const f = fixture();
  f.db.documents.set('users/phone_79991234567', { banned: true });
  await f.service.sendCode('79991234567', '192.0.2.1');
  await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'permission-denied' });
  assert.equal(f.minted.length, 0);
});

test('authoritative Firebase phone binding retains its UID', async () => {
  const f = fixture({ auth: { getUserByPhoneNumber: async () => ({ uid: 'existing-uid' }) } });
  await f.service.sendCode('79991234567', '192.0.2.1');
  await f.service.verifyCode('79991234567', '123456');
  assert.deepEqual(f.minted, ['existing-uid']);
});

test('existing legacy custom-token account keeps its UID and profile without a Firebase phone binding', async () => {
  const uid = 'phone_79991234567';
  const f = fixture({ auth: { getUser: async requestedUid => {
    assert.equal(requestedUid, uid);
    return { uid, disabled: false };
  } } });
  const profile = { name: 'Existing user', points: 250, profile_filled: true };
  f.db.documents.set(`users/${uid}`, profile);
  await f.service.sendCode('79991234567', '192.0.2.1');
  await f.service.verifyCode('79991234567', '123456');
  assert.deepEqual(f.minted, [uid]);
  assert.deepEqual(f.db.documents.get(`users/${uid}`), profile);
});

test('legacy plaintext phone_verifications cannot authenticate through the secure endpoint', async () => {
  const f = fixture();
  const legacy = { code: '123456', attempts: 0, createdAt: 100000000 };
  f.db.documents.set('phone_verifications/79991234567', legacy);
  await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'unauthenticated' });
  assert.equal(f.minted.length, 0);
  assert.deepEqual(f.db.documents.get('phone_verifications/79991234567'), legacy);
});

test('ambiguous existing accounts are never silently merged', async () => {
  const f = fixture({ auth: {
    getUserByPhoneNumber: async () => ({ uid: 'existing-uid' }),
    getUser: async uid => ({ uid }),
  } });
  await f.service.sendCode('79991234567', '192.0.2.1');
  await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'failed-precondition' });
  assert.equal(f.minted.length, 0);
});

test('disabled Firebase users cannot obtain custom tokens through either UID lookup', async () => {
  for (const method of ['getUser', 'getUserByPhoneNumber']) {
    const f = fixture({ auth: {
      [method]: async () => ({ uid: 'phone_79991234567', disabled: true }),
    } });
    await f.service.sendCode('79991234567', '192.0.2.1');
    await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'permission-denied' });
    assert.equal(f.minted.length, 0);
  }
});

test('legacy UID bound to another Firebase phone cannot be taken over', async () => {
  const f = fixture({ auth: {
    getUser: async uid => ({ uid, phoneNumber: '+79999999999' }),
  } });
  await f.service.sendCode('79991234567', '192.0.2.1');
  await assert.rejects(f.service.verifyCode('79991234567', '123456'), { code: 'failed-precondition' });
  assert.equal(f.minted.length, 0);
});
