'use strict';

const { initializeApp } = require('firebase-admin/app');
initializeApp();

const phoneAuth = require('./auth');
exports.sendCodeSecure = phoneAuth.sendCodeSecure;
exports.verifyCodeSecure = phoneAuth.verifyCodeSecure;
