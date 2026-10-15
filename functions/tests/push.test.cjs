'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { maySendPush } = require('../initialPayment_function-source/push_authorization');

function fixture() {
  const ref = id => ({ path: `users/${id}` });
  const docs = {
    'users/mentor': { type: 'mentor', connections: [ref('kid')] },
    'users/kid': { type: 'kid' },
    'users/outsider': { type: 'mentor' },
    'tasks/task': { owner: ref('mentor'), kid: ref('kid') },
    'bonuses/bonus': { mentor: ref('mentor'), kid: ref('kid') },
    'chats/chat': { members: [ref('mentor'), ref('kid')] },
  };
  const db = { collection: collection => ({ doc: id => ({ get: async () => ({
    data: () => docs[`${collection}/${id}`],
  }) }) }) };
  return { db, docs };
}

test('task notification permits only the correct sender and recipient', async () => {
  const { db } = fixture();
  assert.equal(await maySendPush(db, 'mentor', 'kid', { type: 'taskComplete', task_id: 'task' }), true);
  assert.equal(await maySendPush(db, 'outsider', 'kid', { type: 'taskComplete', task_id: 'task' }), false);
  assert.equal(await maySendPush(db, 'kid', 'mentor', { type: 'taskComplete', task_id: 'task' }), false);
  assert.equal(await maySendPush(db, 'kid', 'mentor', { type: 'taskReview', task_id: 'task' }), true);
});

test('chat push requires both parties to be current members', async () => {
  const { db } = fixture();
  assert.equal(await maySendPush(db, 'kid', 'mentor', { type: 'chat', chat_id: 'chat' }), true);
  assert.equal(await maySendPush(db, 'kid', 'outsider', { type: 'chat', chat_id: 'chat' }), false);
});

test('bonus push preserves both directions without permitting unrelated users', async () => {
  const { db } = fixture();
  assert.equal(await maySendPush(db, 'mentor', 'kid', { type: 'bonusApproved', bonus_id: 'bonus' }), true);
  assert.equal(await maySendPush(db, 'kid', 'mentor', { type: 'bonusRequested', bonus_id: 'bonus' }), true);
  assert.equal(await maySendPush(db, 'outsider', 'kid', { type: 'bonusApproved', bonus_id: 'bonus' }), false);
});

test('banned sender, unknown payload and client-claimed gifts are denied', async () => {
  const { db, docs } = fixture();
  assert.equal(await maySendPush(db, 'mentor', 'kid', { type: 'gift' }), false);
  assert.equal(await maySendPush(db, 'mentor', 'kid', { type: 'unknown' }), false);
  docs['users/mentor'].banned = true;
  assert.equal(await maySendPush(db, 'mentor', 'kid', { type: 'taskCreated', task_id: 'task' }), false);
});
