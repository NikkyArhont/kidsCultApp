const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createPaymentService, amountInKopecks, addOneMonth } = require('./payment-core');

const timestamp = date => ({ toDate: () => new Date(date) });

// Serializes transactions and only applies staged writes on success. Also enforces
// Firestore's read-before-write rule; no live Firebase or merchant account is used.
function fakeFirestore() {
    const docs = new Map();
    let queue = Promise.resolve();
    let failCommit = false;
    function ref(collection, id) {
        return { id, path: `${collection}/${id}`, get: async () => snapshot(`${collection}/${id}`) };
    }
    function snapshot(key) {
        return { id: key.split('/').at(-1), exists: docs.has(key), data: () => ({ ...docs.get(key) }) };
    }
    return {
        docs,
        failNextCommit() { failCommit = true; },
        collection: collection => ({ doc: id => ref(collection, id) }),
        runTransaction: callback => {
            const result = queue.then(async () => {
                const writes = [];
                const result = await callback({
                    get: async ref => {
                        assert.equal(writes.length, 0, 'read after write');
                        return snapshot(ref.path);
                    },
                    set: (ref, data) => writes.push({ ref, data }),
                    update: (ref, data) => {
                        assert(docs.has(ref.path), `missing document: ${ref.path}`);
                        writes.push({ ref, data: { ...docs.get(ref.path), ...data } });
                    },
                });
                if (failCommit) { failCommit = false; throw new Error('transaction unavailable'); }
                writes.forEach(({ ref, data }) => docs.set(ref.path, data));
                return result;
            });
            queue = result.catch(() => {});
            return result;
        },
    };
}

function fixture() {
    const db = fakeFirestore();
    db.docs.set('users/payer', { name: 'Payer' });
    db.docs.set('users/recipient', { name: 'Recipient' });
    db.docs.set('tariffs/month', { price: 599 });
    let clock = new Date('2026-01-31T12:00:00Z');
    const payments = new Map();
    const calls = { creates: [], gets: [], captures: [], notifications: [] };
    const gateway = {
        create: async (body, key) => {
            calls.creates.push({ body, key });
            if (!payments.has(key)) payments.set(key, {
                id: `payment-${payments.size + 1}`, status: 'pending', ...body,
                confirmation: { confirmation_url: 'https://yookassa.ru/pay' },
                payment_method: { id: 'this-is-not-the-payment-id' },
            });
            return payments.get(key);
        },
        get: async id => {
            calls.gets.push(id);
            const payment = [...payments.values()].find(payment => payment.id === id);
            assert(payment, 'unknown merchant payment');
            return payment;
        },
        capture: async (id, body, key) => {
            calls.captures.push({ id, body, key });
            const payment = [...payments.values()].find(payment => payment.id === id);
            payment.status = 'succeeded';
            return payment;
        },
    };
    const service = createPaymentService({
        db, gateway, now: () => clock, timestamp,
        returnUrl: 'https://telegram-app-kidscult.web.app/#/payment_web_redirect/',
        notifyGift: async data => calls.notifications.push(data),
    });
    const start = (extra = {}) => service.initialPayment('payer', { order_id: 'order-1', tariff_id: 'month', ...extra });
    return { db, gateway, service, calls, start, payments, tick: date => { clock = new Date(date); }, payment: () => [...payments.values()][0] };
}

test('both independently deployable function directories use identical payment implementation', () => {
    for (const name of ['payment.js', 'payment-core.js']) {
        assert.equal(fs.readFileSync(path.join(__dirname, name), 'utf8'),
            fs.readFileSync(path.join(__dirname, '../ukassaWebHook_function-source', name), 'utf8'));
    }
});

test('requires authentication and ignores client prices', async () => {
    const f = fixture();
    await assert.rejects(f.service.initialPayment(null, { order_id: 'order-1' }), { code: 'unauthenticated' });
    assert.equal(f.calls.creates.length, 0);
    await f.start({ price: 1, paid: true, fulfilled: true });
    assert.equal(f.calls.creates[0].body.amount.value, '599.00');
    assert.equal(f.db.docs.get('orders/order-1').paid, false);
    assert.equal(f.db.docs.get('orders/order-1').payment_id, 'payment-1');
    assert.match(f.calls.creates[0].body.confirmation.return_url, /#\/payment_web_redirect\/\?orderId=order-1$/);
});

test('owner and frozen tariff/recipient cannot be changed on retry', async () => {
    const f = fixture();
    await f.start();
    await assert.rejects(f.service.initialPayment('recipient', { order_id: 'order-1' }), { code: 'permission-denied' });
    await assert.rejects(f.start({ recipient_uid: 'recipient' }), { code: 'failed-precondition' });
    await assert.rejects(f.start({ tariff_id: 'other' }), { code: 'failed-precondition' });
    assert.equal(f.calls.creates.length, 1);
});

test('rejects missing/disabled tariff, invalid price and unknown recipient before charging', async () => {
    for (const tariff of [undefined, { active: false, price: 100 }, { price: 0 }, { price: -1 }, { price: 1.001 }]) {
        const f = fixture();
        if (tariff) f.db.docs.set('tariffs/month', tariff); else f.db.docs.delete('tariffs/month');
        await assert.rejects(f.start());
        assert.equal(f.calls.creates.length, 0);
    }
    const f = fixture();
    await assert.rejects(f.start({ recipient_uid: 'missing' }), { code: 'not-found' });
});

test('fetches real status, captures with stable key, and fulfills concurrent notifications once', async () => {
    const f = fixture();
    await f.start();
    f.payment().status = 'waiting_for_capture';
    await Promise.all(Array.from({ length: 5 }, () => f.service.reconcilePayment('payment-1')));
    assert(f.calls.gets.length >= 5);
    assert.equal(new Set(f.calls.captures.map(call => call.key)).size, 1);
    assert.equal(f.db.docs.get('users/payer').premium_subscription.toDate().toISOString(), '2026-02-28T12:00:00.000Z');
    assert.equal(f.db.docs.get('orders/order-1').fulfilled, true);
    assert.equal(f.db.docs.get('payment_intents/order-1').fulfilled, true);
    f.payment().status = 'pending';
    await f.service.reconcilePayment('payment-1');
    assert.equal(f.db.docs.get('orders/order-1').paid, true);
});

test('provider pending or cancellation never grants subscription', async () => {
    const f = fixture();
    await f.start();
    await f.service.reconcilePayment('payment-1');
    assert.equal(f.db.docs.get('users/payer').premium_subscription, undefined);
    f.payment().status = 'canceled';
    await f.service.reconcilePayment('payment-1');
    assert.equal(f.db.docs.get('orders/order-1').paid, false);
    assert.equal(f.db.docs.get('users/payer').premium_subscription, undefined);
});

test('capture failure does not mark order paid; retry can fulfill', async () => {
    const f = fixture();
    await f.start();
    f.payment().status = 'waiting_for_capture';
    const capture = f.gateway.capture;
    f.gateway.capture = async () => { throw new Error('capture unavailable'); };
    await assert.rejects(f.service.reconcilePayment('payment-1'));
    assert.equal(f.db.docs.get('orders/order-1').paid, false);
    assert.equal(f.db.docs.get('users/payer').premium_subscription, undefined);
    f.gateway.capture = capture;
    await f.service.reconcilePayment('payment-1');
    assert.equal(f.db.docs.get('orders/order-1').paid, true);
});

test('amount, currency, metadata or payment ID mismatch prevents capture and entitlement', async () => {
    for (const mutate of [
        p => { p.amount.value = '1.00'; }, p => { p.amount.currency = 'USD'; },
        p => { p.metadata.order_id = 'missing'; }, p => { p.id = 'different'; },
    ]) {
        const f = fixture();
        await f.start();
        f.payment().status = 'waiting_for_capture';
        mutate(f.payment());
        await assert.rejects(f.service.reconcilePayment('payment-1'));
        assert.equal(f.calls.captures.length, 0);
        assert.equal(f.db.docs.get('users/payer').premium_subscription, undefined);
    }
});

test('gift recipient and price come from private snapshot, not mutable public order', async () => {
    const f = fixture();
    const existingExpiry = new Date('2026-04-30T12:00:00Z');
    f.db.docs.set('users/recipient', { premium_subscription: timestamp(existingExpiry) });
    await f.start({ recipient_uid: 'recipient' });
    Object.assign(f.db.docs.get('orders/order-1'), { user: f.db.collection('users').doc('payer'), price: 1 });
    f.payment().status = 'succeeded';
    await f.service.reconcilePayment('payment-1');
    await f.service.reconcilePayment('payment-1');
    assert.equal(f.db.docs.get('users/recipient').premium_subscription.toDate().toISOString(), '2026-05-30T12:00:00.000Z');
    assert.equal(f.db.docs.get('users/payer').premium_subscription, undefined);
    assert.equal(f.calls.notifications.length, 1);
    assert.equal(f.db.docs.get('notifications/payment-gift-order-1').user.path, 'users/recipient');
    assert.equal(f.db.docs.get('notifications/payment-gift-order-1').type, 'gift');
});

test('does not charge banned or deleted accounts', async () => {
    for (const field of ['banned', 'deleted']) {
        for (const uid of ['payer', 'recipient']) {
            const f = fixture();
            f.db.docs.get('users/' + uid)[field] = true;
            await assert.rejects(f.start({ recipient_uid: 'recipient' }), { code: 'permission-denied' });
            assert.equal(f.calls.creates.length, 0);
        }
    }
});

test('transaction failure rolls back both paid marker and entitlement; webhook retry succeeds once', async () => {
    const f = fixture();
    await f.start();
    f.payment().status = 'succeeded';
    f.db.failNextCommit();
    await assert.rejects(f.service.reconcilePayment('payment-1'));
    assert.equal(f.db.docs.get('orders/order-1').paid, false);
    assert.equal(f.db.docs.get('users/payer').premium_subscription, undefined);
    await f.service.reconcilePayment('payment-1');
    await f.service.reconcilePayment('payment-1');
    assert.equal(f.db.docs.get('users/payer').premium_subscription.toDate().toISOString(), '2026-02-28T12:00:00.000Z');
});

test('ambiguous provider timeout retries with identical payload and idempotency key', async () => {
    const f = fixture();
    const create = f.gateway.create;
    let once = true;
    f.gateway.create = async (...args) => {
        const payment = await create(...args);
        if (once) { once = false; throw new Error('response lost after payment creation'); }
        return payment;
    };
    await assert.rejects(f.start());
    f.db.docs.get('tariffs/month').price = 999;
    await f.start();
    assert.deepEqual(f.calls.creates[0], f.calls.creates[1]);
    assert.equal(f.payments.size, 1);
});

test('does not recreate ambiguous payment after provider idempotency retention', async () => {
    const f = fixture();
    f.gateway.create = async () => { throw new Error('timeout'); };
    await assert.rejects(f.start());
    f.tick('2026-02-02T12:00:00Z');
    await assert.rejects(f.start(), { code: 'failed-precondition' });
});

test('legacy orders are preserved for reconciliation and never charged again', async () => {
    const f = fixture();
    const legacy = { paid: true, payment_id: 'old-method-id' };
    f.db.docs.set('orders/order-1', legacy);
    await assert.rejects(f.start(), { code: 'failed-precondition' });
    assert.deepEqual(f.db.docs.get('orders/order-1'), legacy);
    assert.equal(f.calls.creates.length, 0);
});

test('status-only request cannot create or charge an order', async () => {
    const f = fixture();
    await assert.rejects(f.start({ status_only: true }), { code: 'not-found' });
    assert.equal(f.calls.creates.length, 0);
    await f.start();
    const result = await f.start({ status_only: true });
    assert.equal(result.status, 'pending');
    assert.equal(f.calls.creates.length, 1);
});

test('calendar renewal clamps month end and handles leap/year boundaries', () => {
    assert.equal(addOneMonth(new Date('2028-01-31T12:30:00Z')).toISOString(), '2028-02-29T12:30:00.000Z');
    assert.equal(addOneMonth(new Date('2026-12-31T00:00:00Z')).toISOString(), '2027-01-31T00:00:00.000Z');
    assert.equal(amountInKopecks('599.01'), 59901);
    assert.throws(() => amountInKopecks('NaN'));
});
