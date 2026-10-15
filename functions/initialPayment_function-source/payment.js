const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const axios = require('axios');
const { createPaymentService, PaymentError } = require('./payment-core');
const { sendPushNotificationToUser } = require('./sendPush');

const shopId = defineSecret('YOOKASSA_SHOP_ID');
const secretKey = defineSecret('YOOKASSA_SECRET_KEY');
const options = { secrets: [shopId, secretKey] };

function service() {
    const shop = shopId.value();
    const secret = secretKey.value();
    if (!shop || !secret) throw new PaymentError('failed-precondition', 'Оплата временно недоступна.');
    const api = axios.create({
        baseURL: 'https://api.yookassa.ru/v3',
        auth: { username: shop, password: secret },
        timeout: 20000,
    });
    return createPaymentService({
        db: admin.firestore(),
        now: () => new Date(),
        timestamp: date => admin.firestore.Timestamp.fromDate(date),
        notifyGift: async ({ recipientUid, title, body }) => {
            try {
                await sendPushNotificationToUser(recipientUid, title, body, { type: 'gift' });
            } catch (_) {
                logger.warn('Gift push was not delivered; the in-app notification is saved.');
            }
        },
        returnUrl: process.env.PAYMENT_RETURN_URL || 'https://telegram-app-kidscult.web.app/#/payment_web_redirect/',
        gateway: {
            create: async (body, key) => (await api.post('/payments', body, { headers: { 'Idempotence-Key': key } })).data,
            get: async id => (await api.get('/payments/' + encodeURIComponent(id))).data,
            capture: async (id, body, key) => (await api.post('/payments/' + encodeURIComponent(id) + '/capture', body, {
                headers: { 'Idempotence-Key': key },
            })).data,
        },
    });
}

exports.initialPayment = onCall(options, async request => {
    try {
        return await service().initialPayment(request.auth?.uid, request.data);
    } catch (error) {
        if (error instanceof PaymentError) throw new HttpsError(error.code, error.message);
        // Axios errors contain merchant credentials; never log the error/config/body.
        logger.error('Payment provider request failed', { code: error.code || 'unknown' });
        throw new HttpsError('unavailable', 'Не удалось проверить оплату. Повторите попытку позже.');
    }
});

exports.UkassaWebHook = onRequest(options, async (request, response) => {
    if (request.method !== 'POST') return response.status(405).send('Method Not Allowed');
    const id = request.body?.object?.id;
    if (typeof id !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(id)) return response.status(400).send('Invalid payment');
    try {
        // The notification is untrusted. Fetch the object using our merchant credentials.
        await service().reconcilePayment(id);
        return response.status(200).send('OK');
    } catch (error) {
        logger.error('Payment reconciliation failed', { code: error.code || 'unknown', paymentId: id });
        // Non-2xx makes YooKassa retry a transient error instead of losing a paid order.
        return response.status(503).send('Retry later');
    }
});
