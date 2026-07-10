const admin = require('firebase-admin');
const db = admin.firestore();

/**
 * Отправка push пользователю по ID
 */
async function sendPushNotificationToUser(userId, title, body = '', data = {}) {
  const userDoc = await db.collection('users').doc(userId).get();

  if (!userDoc.exists) {
    throw new Error(`Пользователь с ID ${userId} не найден`);
  }

  const userData = userDoc.data();

  if (!userData.notification) {
    throw new Error('Уведомления отключены');
  }

  if (!userData.fcm_token) {
    throw new Error('Отсутствует fcm_token');
  }

  const message = {
    token: userData.fcm_token,
    notification: { title, body },
    data: data,
    android: {
      priority: 'high',
      notification: { sound: 'default' },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
      headers: {
        'apns-priority': '10',
      },
    },
  };

  return admin.messaging().send(message);
}

module.exports = { sendPushNotificationToUser };
