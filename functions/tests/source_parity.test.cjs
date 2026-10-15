'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('independently deployable function exports use identical critical implementations', () => {
  for (const file of ['index.js', 'auth.js', 'otp_service.js', 'push_authorization.js', 'payment.js', 'payment-core.js']) {
    const read = folder => fs.readFileSync(path.join(__dirname, '..', folder, file), 'utf8').replace(/\r\n/g, '\n');
    assert.equal(read('initialPayment_function-source'), read('ukassaWebHook_function-source'), file);
  }
});

test('dedicated auth deployment uses the reviewed OTP service unchanged', () => {
  const read = folder => fs.readFileSync(
    path.join(__dirname, '..', folder, 'otp_service.js'), 'utf8').replace(/\r\n/g, '\n');
  assert.equal(read('initialPayment_function-source'), read('auth_function-source'));
});
