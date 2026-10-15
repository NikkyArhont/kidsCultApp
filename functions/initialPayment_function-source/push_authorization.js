'use strict';

// Authentication alone must not grant arbitrary push access to another user.
async function maySendPush(db, uid, recipient, payload) {
  const validId = value => typeof value === 'string' && value.length > 0 &&
    value.length <= 128 && !value.includes('/');
  if (!validId(uid) || !validId(recipient) || !payload || typeof payload !== 'object') return false;
  const senderPath = `users/${uid}`;
  const recipientPath = `users/${recipient}`;
  const profile = (await db.collection('users').doc(uid).get()).data();
  if (!profile || profile.banned || profile.deleted) return false;
  const get = async (collection, id) => validId(id)
    ? (await db.collection(collection).doc(id).get()).data() : null;
  if (payload.type === 'chat') {
    const chat = await get('chats', payload.chat_id);
    const members = chat?.members?.map(ref => ref.path) || [];
    return members.includes(senderPath) && members.includes(recipientPath);
  }
  if (payload.type === 'coinChange') {
    return profile.type === 'mentor' &&
      (profile.connections || []).some(ref => ref.path === recipientPath);
  }
  if (payload.type === 'taskReview') {
    const task = await get('tasks', payload.task_id);
    return task?.kid?.path === senderPath && task?.owner?.path === recipientPath;
  }
  if (['taskComplete', 'taskRework', 'taskCanceled', 'taskDeleted', 'taskCreated'].includes(payload.type)) {
    const task = await get('tasks', payload.task_id);
    return task?.owner?.path === senderPath && task?.kid?.path === recipientPath;
  }
  if (['bonusNeedApprove', 'bonusRequested'].includes(payload.type)) {
    const bonus = await get('bonuses', payload.bonus_id);
    return bonus?.kid?.path === senderPath && bonus?.mentor?.path === recipientPath;
  }
  if (['bonusCreated', 'bonusCanceled', 'bonusRejected', 'bonusApproved', 'bonusRequestApproved'].includes(payload.type)) {
    const bonus = await get('bonuses', payload.bonus_id);
    return bonus?.mentor?.path === senderPath && bonus?.kid?.path === recipientPath;
  }
  // Reminders and paid gift notifications may only be emitted server-side.
  return false;
}

module.exports = { maySendPush };
