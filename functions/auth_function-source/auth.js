'use strict';

const axios = require('axios');
const crypto = require('node:crypto');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret, defineString, defineBoolean } = require('firebase-functions/params');
const { createOtpService, parseTestPhoneCodes, OtpError } = require('./otp_service');

const smsLogin = defineSecret('REDSMS_LOGIN');
const smsKey = defineSecret('REDSMS_API_KEY');
const otpKey = defineSecret('OTP_HMAC_KEY');
const testPhoneCodes = defineSecret('AUTH_TEST_PHONE_CODES');
const sender = defineString('REDSMS_SENDER', { default: 'FamilyCult' });
const appCheck = defineBoolean('AUTH_ENFORCE_APP_CHECK', { default: false });

function service(codes = {}) {
  return createOtpService({
    db: getFirestore(), auth: getAuth(), pepper: otpKey.value(), testPhoneCodes: codes,
    timestamp: millis => Timestamp.fromMillis(millis),
    sendSms: async (phone, code) => {
      const ts = crypto.randomUUID();
      const secret = crypto.createHash('md5').update(ts + smsKey.value()).digest('hex');
      const result = await axios.post('https://cp.redsms.ru/api/message', {
        from: sender.value(), to: `+${phone}`, route: 'sms',
        text: `Код для входа в приложение KidsCult: ${code}`,
      }, { headers: { login: smsLogin.value(), ts, secret }, timeout: 15000 });
      if (result.data?.success !== true || result.data?.errors?.length > 0 ||
          !Array.isArray(result.data?.items) || result.data.items.length !== 1) {
        throw new Error('SMS provider did not accept the message.');
      }
    },
  });
}

async function handle(request, action) {
  if (appCheck.value() && !request.app) {
    throw new HttpsError('unauthenticated', 'App Check verification is required.');
  }
  try { return await action(); }
  catch (error) {
    if (error instanceof OtpError) throw new HttpsError(error.code, error.message);
    throw new HttpsError('internal', 'Authentication could not be completed.');
  }
}

exports.sendCodeSecure = onCall({
  secrets: [smsLogin, smsKey, otpKey, testPhoneCodes],
}, request => handle(request, () => service(parseTestPhoneCodes(testPhoneCodes.value()))
  .sendCode(request.data?.phone, request.rawRequest.ip)));

exports.verifyCodeSecure = onCall({ secrets: [otpKey] },
  request => handle(request, () => service().verifyCode(request.data?.phone, request.data?.code)));
