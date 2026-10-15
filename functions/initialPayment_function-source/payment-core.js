const { createHash } = require('node:crypto');

class PaymentError extends Error {
    constructor(code, message) { super(message); this.code = code; }
}
const fail = (code, message) => { throw new PaymentError(code, message); };
const keyFor = (operation, id) => createHash('sha256').update(operation + ':' + id).digest('hex');
const validId = value => typeof value === 'string' && /^[a-zA-Z0-9_+-]{1,128}$/.test(value);

function amountInKopecks(value) {
    const text = String(value);
    if (!/^\d+(\.\d{1,2})?$/.test(text)) fail('failed-precondition', 'Некорректная цена тарифа.');
    const [rubles, fraction = ''] = text.split('.');
    const result = Number(rubles) * 100 + Number(fraction.padEnd(2, '0'));
    if (!Number.isSafeInteger(result) || result <= 0) fail('failed-precondition', 'Некорректная цена тарифа.');
    return result;
}

function addOneMonth(date) {
    const result = new Date(date);
    const day = result.getUTCDate();
    result.setUTCDate(1);
    result.setUTCMonth(result.getUTCMonth() + 1);
    const lastDay = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)).getUTCDate();
    result.setUTCDate(Math.min(day, lastDay));
    return result;
}

function createPaymentService({ db, gateway, now, timestamp, returnUrl, notifyGift = async () => {} }) {
    const intentRef = id => db.collection('payment_intents').doc(id);
    const orderRef = id => db.collection('orders').doc(id);

    async function prepare(uid, data) {
        if (!uid) fail('unauthenticated', 'Необходимо войти в аккаунт.');
        const id = data?.order_id;
        if (!validId(id)) fail('invalid-argument', 'Некорректный заказ.');
        return db.runTransaction(async tx => {
            const previous = await tx.get(intentRef(id));
            if (previous.exists) {
                const intent = previous.data();
                if (intent.ownerUid !== uid) fail('permission-denied', 'Заказ недоступен.');
                if ((data.tariff_id && data.tariff_id !== intent.tariffId) ||
                    (data.recipient_uid && data.recipient_uid !== intent.recipientUid)) {
                    fail('failed-precondition', 'Параметры заказа уже зафиксированы.');
                }
                return intent;
            }
            if (data.status_only === true) fail('not-found', 'Заказ не найден.');
            // Old client-written orders cannot prove whether an entitlement was already granted.
            // Keep them untouched for provider-side reconciliation; never charge them a second time.
            if ((await tx.get(orderRef(id))).exists) {
                fail('failed-precondition', 'Старый заказ требует проверки. Обратитесь в поддержку перед новой оплатой.');
            }
            const recipientUid = data.recipient_uid || uid;
            if (!validId(data.tariff_id) || !validId(recipientUid)) fail('invalid-argument', 'Некорректный тариф или получатель.');
            const tariffRef = db.collection('tariffs').doc(data.tariff_id);
            const recipientRef = db.collection('users').doc(recipientUid);
            const ownerRef = db.collection('users').doc(uid);
            const [tariff, recipient, owner] = await Promise.all([tx.get(tariffRef), tx.get(recipientRef), tx.get(ownerRef)]);
            if (!tariff.exists || tariff.data().active === false) fail('not-found', 'Тариф недоступен.');
            if (!recipient.exists || !owner.exists) fail('not-found', 'Пользователь не найден.');
            if (recipient.data().banned || recipient.data().deleted || owner.data().banned || owner.data().deleted) {
                fail('permission-denied', 'Аккаунт недоступен для оплаты.');
            }
            const amount = amountInKopecks(tariff.data().price);
            const intent = {
                ownerUid: uid, recipientUid, tariffId: tariff.id, amount,
                currency: 'RUB', createdAt: timestamp(now()), status: 'created', fulfilled: false,
                senderName: String(owner.data().name || '-'),
            };
            tx.set(intentRef(id), intent);
            tx.set(orderRef(id), {
                owner_uid: uid, user: recipientRef, tariff: tariffRef, price: amount / 100,
                paid: false, fulfilled: false, status: 'created', is_gift: recipientUid !== uid,
                ...(recipientUid !== uid ? { sender: ownerRef } : {}), time: intent.createdAt,
            });
            return intent;
        });
    }

    function validatePayment(payment, id, intent) {
        if (!validId(payment?.id) || payment.metadata?.order_id !== id ||
            payment.amount?.currency !== intent.currency ||
            amountInKopecks(payment.amount?.value) !== intent.amount ||
            (intent.paymentId && intent.paymentId !== payment.id)) {
            fail('failed-precondition', 'Платеж не соответствует заказу.');
        }
    }

    async function recordPayment(id, payment) {
        const result = await db.runTransaction(async tx => {
            const snapshot = await tx.get(intentRef(id));
            if (!snapshot.exists) fail('not-found', 'Заказ не найден.');
            const intent = snapshot.data();
            validatePayment(payment, id, intent);
            // A delayed pending/canceled notification must never undo a completed payment.
            if (intent.fulfilled) return { ...intent, status: 'succeeded' };
            const succeeded = payment.status === 'succeeded';
            if (!['pending', 'waiting_for_capture', 'succeeded', 'canceled'].includes(payment.status)) {
                fail('failed-precondition', 'Неизвестный статус платежа.');
            }
            let recipient;
            const userRef = db.collection('users').doc(intent.recipientUid);
            if (succeeded) {
                recipient = await tx.get(userRef);
                if (!recipient.exists) fail('not-found', 'Получатель не найден.');
            }
            const update = {
                paymentId: payment.id, status: payment.status,
                confirmationUrl: payment.confirmation?.confirmation_url || intent.confirmationUrl || null,
            };
            const publicUpdate = {
                payment_id: payment.id, status: payment.status, paid: succeeded, fulfilled: succeeded,
            };
            let giftNotification;
            if (succeeded) {
                const previousExpiry = recipient.data().premium_subscription?.toDate();
                const start = previousExpiry && previousExpiry > now() ? previousExpiry : now();
                const expiry = timestamp(addOneMonth(start));
                update.fulfilled = true;
                update.fulfilledAt = timestamp(now());
                publicUpdate.fulfilled_at = update.fulfilledAt;
                publicUpdate.subscription_expires_at = expiry;
                tx.update(userRef, {
                    premium_subscription_ref: db.collection('tariffs').doc(intent.tariffId),
                    premium_subscription: expiry, trial_subscription: null,
                });
                if (intent.ownerUid !== intent.recipientUid) {
                    giftNotification = {
                        recipientUid: intent.recipientUid,
                        title: intent.senderName + ' подарил Вам подписку!',
                        body: 'Теперь вы можете создавать задания и бонусы в течение 1 месяца',
                    };
                    tx.set(db.collection('notifications').doc('payment-gift-' + id), {
                        user: userRef, time: update.fulfilledAt,
                        title: giftNotification.title, body: giftNotification.body,
                        type: 'gift', payload: { type: 'gift' }, is_read: false,
                    });
                }
            }
            // Private intent, entitlement and public order commit atomically.
            tx.update(intentRef(id), update);
            tx.update(orderRef(id), publicUpdate);
            return { ...intent, ...update, giftNotification };
        });
        // Only the transaction winner sends FCM. Durable in-app notification is
        // already committed; notification delivery must never undo a paid order.
        if (result.giftNotification) await notifyGift(result.giftNotification);
        return result;
    }

    async function reconcilePayment(paymentId) {
        let payment = await gateway.get(paymentId);
        if (payment.id !== paymentId) fail('failed-precondition', 'Неверный идентификатор платежа.');
        const id = payment.metadata?.order_id;
        if (!validId(id)) fail('failed-precondition', 'Платеж старого формата требует ручной сверки.');
        const snapshot = await intentRef(id).get();
        if (!snapshot.exists) fail('not-found', 'Доверенный заказ не найден.');
        const intent = snapshot.data();
        validatePayment(payment, id, intent);
        if (payment.status === 'waiting_for_capture') {
            payment = await gateway.capture(paymentId, {
                amount: { value: (intent.amount / 100).toFixed(2), currency: intent.currency },
            }, keyFor('capture', paymentId));
            if (payment.id !== paymentId) fail('failed-precondition', 'Неверный идентификатор платежа.');
            validatePayment(payment, id, intent);
        }
        return recordPayment(id, payment);
    }

    async function initialPayment(uid, data) {
        let intent = await prepare(uid, data);
        const id = data.order_id;
        if (intent.paymentId && !intent.fulfilled) {
            intent = await reconcilePayment(intent.paymentId);
        } else if (!intent.paymentId && data.status_only !== true) {
            // YooKassa retains an idempotency key for 24 hours. Do not recreate an
            // ambiguous payment after that window, even if the original HTTP call timed out.
            if (now() - intent.createdAt.toDate() > 23 * 60 * 60 * 1000) {
                fail('failed-precondition', 'Заказ требует проверки статуса оплаты.');
            }
            const separator = returnUrl.includes('?') ? '&' : '?';
            const payment = await gateway.create({
                amount: { value: (intent.amount / 100).toFixed(2), currency: intent.currency },
                capture: false,
                payment_method_data: { type: 'bank_card' },
                confirmation: { type: 'redirect', return_url: returnUrl + separator + 'orderId=' + encodeURIComponent(id) },
                description: 'Списываем оплату за подписку',
                save_payment_method: false,
                metadata: { order_id: id },
            }, keyFor('create', id));
            intent = await recordPayment(id, payment);
            if (payment.status === 'waiting_for_capture') intent = await reconcilePayment(payment.id);
        }
        return { order_id: id, status: intent.status, fulfilled: intent.fulfilled, url: intent.confirmationUrl || null };
    }

    return { initialPayment, reconcilePayment };
}

module.exports = { createPaymentService, PaymentError, amountInKopecks, addOneMonth, keyFor };
