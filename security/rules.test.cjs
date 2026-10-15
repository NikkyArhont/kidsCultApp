'use strict';
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const {
  initializeTestEnvironment, assertSucceeds, assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, getDoc, getDocs, collection, updateDoc, deleteDoc,
  serverTimestamp, query, orderBy, writeBatch, where,
} = require('firebase/firestore');
const { ref, uploadBytes, getBytes, deleteObject } = require('firebase/storage');

let env;
const projectId = 'demo-kidscult-rules';
const signed = uid => env.authenticatedContext(uid, { email: `${uid}@example.test` });
const registration = uid => ({
  name: 'Неизвестно', email: `${uid}@example.test`, profle_filled: true,
  role: 'admin', status: 'wait', created_at: serverTimestamp(),
});

before(async () => {
  // Refuse any non-loopback host rather than accidentally exercising production.
  assert.match(process.env.FIRESTORE_EMULATOR_HOST || '', /^(127\.0\.0\.1|localhost):\d+$/);
  assert.match(process.env.FIREBASE_STORAGE_EMULATOR_HOST || '', /^(127\.0\.0\.1|localhost):\d+$/);
  env = await initializeTestEnvironment({ projectId });
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    for (const [uid, status] of [['approved', 'accept'], ['waiting', 'wait'], ['rejected', 'reject']]) {
      await setDoc(doc(db, 'admins', uid), { name: uid, role: 'admin', status });
    }
    await setDoc(doc(db, 'config/sms_settings'), { login: 'test-only', api_key: 'fake-key' });
    await setDoc(doc(db, 'users/kid'), { name: 'Kid', points: 100 });
    await setDoc(doc(db, 'tasks/existing'), { used_counter: 1, kid: doc(db, 'users/kid') });
    await setDoc(doc(db, 'games/game'), { name: 'Game', status: 'active' });
    await setDoc(doc(db, 'chats/support'), { type: 'support', last_edit_time: serverTimestamp() });
    for (const path of ['phone_verifications/79991234567', '_otp_challenges/test', '_otp_rate_limits/test', 'payment_intents/test']) {
      await setDoc(doc(db, path), { value: 'test-only' });
    }
    for (const path of ['admins/existing.png', 'users/kid/existing.png', 'chats/chat/existing.png', 'task/task/existing.png']) {
      await uploadBytes(ref(context.storage(), path), new Uint8Array([1, 2]), { contentType: 'image/png' });
    }
  });
});

after(async () => { if (env) await env.cleanup(); });

test('anonymous access to users, tasks and chat messages is denied', async () => {
  const db = env.unauthenticatedContext().firestore();
  for (const path of ['users/kid', 'tasks/existing', 'chats/support/messages/message']) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(setDoc(doc(db, path), { forged: true }));
  }
});

test('registration remains a pending self-owned request, not admin approval', async () => {
  const db = signed('new-admin').firestore();
  await assertSucceeds(setDoc(doc(db, 'admins/new-admin'), registration('new-admin')));
  await assertSucceeds(getDoc(doc(db, 'admins/new-admin')));
  await assertSucceeds(updateDoc(doc(db, 'admins/new-admin'), { name: 'New name' }));
  await assertFails(updateDoc(doc(db, 'admins/new-admin'), { status: 'accept' }));
  await assertFails(updateDoc(doc(db, 'admins/new-admin'), { role: 'owner' }));
  await assertFails(deleteDoc(doc(db, 'admins/new-admin')));
  await assertFails(getDocs(collection(db, 'admins')));
});

test('registration cannot create an accepted admin, use someone else UID or inject privileges', async () => {
  const db = signed('attacker').firestore();
  await assertFails(setDoc(doc(db, 'admins/attacker'), { ...registration('attacker'), status: 'accept' }));
  await assertFails(setDoc(doc(db, 'admins/someone-else'), registration('attacker')));
  await assertFails(setDoc(doc(db, 'admins/attacker'), { ...registration('attacker'), superuser: true }));
  await assertFails(setDoc(doc(db, 'admins/attacker'), { ...registration('attacker'), email: 'someone@example.test' }));
  await assertFails(updateDoc(doc(db, 'admins/approved'), { status: 'reject' }));
});

test('approved administrators cannot approve other accounts from client code', async () => {
  const db = signed('approved').firestore();
  await assertFails(updateDoc(doc(db, 'admins/waiting'), { status: 'accept' }));
  await assertFails(getDoc(doc(db, 'admins/waiting')));
});

test('only approved admins can change top-level content and tariffs', async () => {
  for (const name of ['games', 'quizzes', 'levels', 'articles', 'tariffs']) {
    for (const uid of ['kid', 'waiting', 'rejected']) {
      await assertFails(setDoc(doc(signed(uid).firestore(), name, 'forged'), { name: 'Forged' }));
    }
    const target = doc(signed('approved').firestore(), name, 'approved-content');
    await assertSucceeds(setDoc(target, { name: 'Created' }));
    await assertSucceeds(updateDoc(target, { name: 'Edited' }));
    await assertSucceeds(deleteDoc(target));
  }
  await assertSucceeds(getDoc(doc(signed('kid').firestore(), 'games/game')));
});

test('atomic self-approval plus content creation cannot bypass approval', async () => {
  const db = signed('waiting').firestore();
  const batch = writeBatch(db);
  batch.update(doc(db, 'admins/waiting'), { status: 'accept' });
  batch.set(doc(db, 'games/batch-forged'), { name: 'Forged' });
  await assertFails(batch.commit());
});

test('private server documents stay denied even to an approved admin and in subcollections', async () => {
  for (const context of [env.unauthenticatedContext(), signed('kid'), signed('approved')]) {
    const db = context.firestore();
    for (const parent of ['phone_verifications', '_otp_challenges', '_otp_rate_limits', 'payment_intents']) {
      for (const path of [`${parent}/test`, `${parent}/test/nested/test`]) {
        await assertFails(getDoc(doc(db, path)));
        await assertFails(setDoc(doc(db, path), { forged: true }));
      }
    }
    await assertFails(setDoc(doc(db, 'unknown_collection/test'), { forged: true }));
  }
});

test('legacy SMS config remains readable but never writable; no broad config access', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(db, 'config/sms_settings')));
  await assertFails(getDocs(collection(db, 'config')));
  await assertFails(setDoc(doc(signed('approved').firestore(), 'config/sms_settings'), { api_key: 'forged' }));
  await assertFails(getDoc(doc(signed('kid').firestore(), 'config/other_secret')));
});

test('legacy queries and paired writes are preserved, explicitly NOT ownership-protected', async () => {
  const db = signed('mentor').firestore();
  await assertSucceeds(getDocs(query(collection(db, 'tasks'), orderBy('used_counter', 'desc'))));
  await assertSucceeds(getDocs(collection(db, 'users')));
  await assertSucceeds(getDocs(query(collection(db, 'chats'), where('type', '==', 'support'))));
  const batch = writeBatch(db);
  batch.set(doc(db, 'orders/legacy'), { paid: true, user: doc(db, 'users/kid') });
  batch.update(doc(db, 'users/kid'), { points: 200 });
  batch.set(doc(db, 'coin_changes/legacy'), { coin: 100, kid: doc(db, 'users/kid') });
  await assertSucceeds(batch.commit());
});

test('personal level progress does not open the catalogue or other users progress', async () => {
  const db = signed('kid').firestore();
  await assertSucceeds(setDoc(doc(db, 'levels/level/users/kid'), { completed: true }));
  await assertFails(setDoc(doc(db, 'levels/level/users/other'), { completed: true }));
  await assertFails(setDoc(doc(db, 'levels/level'), { name: 'Forged' }));
});

test('anonymous storage access is denied', async () => {
  const storage = env.unauthenticatedContext().storage();
  for (const path of ['admins/existing.png', 'users/kid/existing.png', 'chats/chat/existing.png', 'task/task/existing.png']) {
    await assertFails(getBytes(ref(storage, path)));
    await assertFails(uploadBytes(ref(storage, path), new Uint8Array([3])));
    await assertFails(deleteObject(ref(storage, path)));
  }
});

test('admin assets require accepted status, not merely a login or role=admin', async () => {
  for (const uid of ['kid', 'waiting', 'rejected']) {
    await assertFails(uploadBytes(ref(signed(uid).storage(), 'admins/forged.png'), new Uint8Array([3])));
    await assertFails(deleteObject(ref(signed(uid).storage(), 'admins/existing.png')));
  }
  const target = ref(signed('approved').storage(), 'admins/approved.png');
  await assertSucceeds(uploadBytes(target, new Uint8Array([3])));
  await assertSucceeds(deleteObject(target));
  await assertSucceeds(getBytes(ref(signed('kid').storage(), 'admins/existing.png')));
});

test('profile assets can only be uploaded or deleted by their path owner', async () => {
  const mine = ref(signed('kid').storage(), 'users/kid/mine.png');
  await assertSucceeds(uploadBytes(mine, new Uint8Array([3])));
  await assertSucceeds(deleteObject(mine));
  await assertFails(uploadBytes(ref(signed('other').storage(), 'users/kid/forged.png'), new Uint8Array([3])));
  await assertFails(deleteObject(ref(signed('other').storage(), 'users/kid/existing.png')));
  await assertSucceeds(getBytes(ref(signed('other').storage(), 'users/kid/existing.png')));
});

test('legacy pre-document chat uploads and task evidence stay allowed; unknown paths denied', async () => {
  const storage = signed('kid').storage();
  for (const path of ['chats/not-created-yet/photo.png', 'task/task/evidence.png']) {
    await assertSucceeds(uploadBytes(ref(storage, path), new Uint8Array([3])));
    await assertSucceeds(deleteObject(ref(storage, path)));
  }
  await assertFails(uploadBytes(ref(storage, 'unknown/forged.png'), new Uint8Array([3])));
});
