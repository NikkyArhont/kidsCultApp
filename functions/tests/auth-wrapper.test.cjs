'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function loadWrapper(directory, overrides = {}) {
  const calls = [];
  const stringDefaults = {};
  let requireAppCheck = false;
  let serviceOptions;
  class HttpsError extends Error {
    constructor(code, message) { super(message); this.code = code; }
  }
  class OtpError extends Error {
    constructor(code, message) { super(message); this.code = code; }
  }
  const modules = {
    'firebase-admin': { firestore: () => ({}), auth: () => ({}) },
    axios: { post: async () => { throw new Error('Tests must not send SMS'); } },
    'node:crypto': require('node:crypto'),
    'firebase-functions/v2/https': {
      onCall: (options, handler) => ({ options, run: handler }), HttpsError,
    },
    'firebase-functions/params': {
      defineSecret: name => ({ name, value: () => name === 'AUTH_TEST_PHONE_CODES'
        ? (overrides.testPhoneCodes || '{}') : 'test-secret-with-more-than-32-characters' }),
      defineString: (name, options) => {
        stringDefaults[name] = options.default;
        return { value: () => options.default };
      },
      defineBoolean: () => ({ value: () => requireAppCheck }),
    },
    './otp_service': {
      OtpError,
      parseTestPhoneCodes: raw => JSON.parse(raw),
      createOtpService: options => {
        calls.push('service');
        serviceOptions = options;
        return {
          sendCode: async (phone, ip) => {
            calls.push({ phone, ip });
            if (overrides.fail) throw overrides.fail(OtpError);
            return { sent: true };
          },
          verifyCode: async (phone, code) => {
            calls.push({ phone, code });
            return { token: 'test-token' };
          },
        };
      },
    },
  };
  const filename = path.join(__dirname, '..', directory, 'auth.js');
  const module = { exports: {} };
  vm.runInNewContext(fs.readFileSync(filename, 'utf8'), {
    exports: module.exports, module,
    require: name => {
      assert.ok(Object.hasOwn(modules, name), `Unexpected dependency: ${name}`);
      return modules[name];
    },
  }, { filename });
  return {
    ...module.exports, calls, stringDefaults,
    get serviceOptions() { return serviceOptions; },
    enableAppCheck: () => { requireAppCheck = true; },
  };
}

for (const directory of ['initialPayment_function-source', 'ukassaWebHook_function-source']) {
  test(`${directory}: fixed phone codes come from the server secret, not the app`, async () => {
    const request = { data: { phone: '+16505550101' }, rawRequest: { ip: '192.0.2.1' } };
    const empty = loadWrapper(directory);
    await empty.sendCodeSecure.run(request);
    assert.equal(Object.keys(empty.serviceOptions.testPhoneCodes).length, 0);
    const configured = loadWrapper(directory, {
      testPhoneCodes: '{"16505550101":"000000"}',
    });
    await configured.sendCodeSecure.run(request);
    assert.equal(configured.serviceOptions.testPhoneCodes['16505550101'], '000000');
    assert.ok(configured.sendCodeSecure.options.secrets.some(secret =>
      secret.name === 'AUTH_TEST_PHONE_CODES'));
    assert.ok(configured.verifyCodeSecure.options.secrets.every(secret =>
      secret.name !== 'AUTH_TEST_PHONE_CODES'));
  });

  test(`${directory}: default SMS sender matches the currently shipped real SMS path`, () => {
    assert.equal(loadWrapper(directory).stringDefaults.REDSMS_SENDER, 'FamilyCult');
  });

  test(`${directory}: App Check defaults off without passing a truthy parameter object`, async () => {
    const wrapper = loadWrapper(directory);
    assert.equal(wrapper.sendCodeSecure.options.enforceAppCheck, undefined);
    assert.equal(wrapper.verifyCodeSecure.options.enforceAppCheck, undefined);
    assert.deepEqual(await wrapper.sendCodeSecure.run({
      data: { phone: '79991234567' }, rawRequest: { ip: '192.0.2.1' },
    }), { sent: true });
    assert.deepEqual(wrapper.calls, ['service', { phone: '79991234567', ip: '192.0.2.1' }]);
  });

  test(`${directory}: enabled App Check rejects both endpoints before constructing services`, async () => {
    const wrapper = loadWrapper(directory);
    wrapper.enableAppCheck();
    for (const endpoint of [wrapper.sendCodeSecure, wrapper.verifyCodeSecure]) {
      await assert.rejects(endpoint.run({
        data: { phone: '79991234567', code: '123456' }, rawRequest: { ip: '192.0.2.1' },
      }), { code: 'unauthenticated' });
    }
    assert.deepEqual(wrapper.calls, []);
  });

  test(`${directory}: valid app attestation allows verification when enforcement is enabled`, async () => {
    const wrapper = loadWrapper(directory);
    wrapper.enableAppCheck();
    const result = await wrapper.verifyCodeSecure.run({
      app: { appId: 'test-app' }, data: { phone: '79991234567', code: '123456' },
    });
    assert.deepEqual(result, { token: 'test-token' });
    assert.deepEqual(wrapper.calls, ['service', { phone: '79991234567', code: '123456' }]);
  });

  test(`${directory}: expected errors retain codes and unexpected errors hide secrets`, async () => {
    const request = { data: { phone: '79991234567' }, rawRequest: { ip: '192.0.2.1' } };
    const limited = loadWrapper(directory, {
      fail: OtpError => new OtpError('resource-exhausted', 'Wait before requesting another code.'),
    });
    await assert.rejects(limited.sendCodeSecure.run(request), { code: 'resource-exhausted' });
    const failed = loadWrapper(directory, { fail: () => new Error('secret-credentials') });
    await assert.rejects(failed.sendCodeSecure.run(request), error => {
      assert.equal(error.code, 'internal');
      assert.ok(!error.message.includes('secret-credentials'));
      return true;
    });
  });
}
