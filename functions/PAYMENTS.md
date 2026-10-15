# Payment changes and release prerequisites

These sources have been changed locally; they have not been deployed or exercised
against a merchant account. Both function export directories deliberately contain
identical `payment.js` and `payment-core.js`; the parity test prevents drift.
Deploy only the selected source directory for the existing functions, not two
competing copies. Existing exported names remain `initialPayment` and `ukassaWebHook`.

## Configuration and security boundary

- Rotate the merchant key previously committed in both `payment.js` files. Removing
  it from working files does not remove it from Git history or revoke it.
- Configure `YOOKASSA_SHOP_ID` and `YOOKASSA_SECRET_KEY` as Firebase Secret Manager
  secrets for the target project. They are bound explicitly to both payment handlers
  and read only at invocation. Use test shop credentials for staging first.
- Optionally set `PAYMENT_RETURN_URL` in the deployed function environment. Default
  remains `https://telegram-app-kidscult.web.app/#/payment_web_redirect/`; `orderId`
  is appended. Verify the actual hosted page and approved domain before release.
- Deny all client reads/writes of `payment_intents`, all client writes of `orders`
  and `tariffs`, and client modifications of entitlement fields on `users`.
  Private intents are immutable inputs for fulfillment. **Their safety depends
  on deployed Firestore Rules; permissive deployed rules would defeat this boundary.**
- Allow authenticated order reads to its payer (`owner_uid`) and recipient (`user`),
  preserving sender-based gift-history queries for legacy orders. Existing gifts
  remain readable and are not migrated or modified.
- Register the actual webhook URL for `payment.waiting_for_capture`,
  `payment.succeeded`, and `payment.canceled` in the YooKassa merchant dashboard.
  The handler fetches the payment with merchant credentials before trusting status.
  Capture errors or failed transactions return 503 so delivery is retried.

The new client sends `order_id`, `tariff_id` and `recipient_uid`; only the server
reads a tariff's price and creates an order. The optional tariff field `active: false`
disables sales; absent `active` preserves the old catalogue. A calendar month is added
to the later of current UTC time or current expiry, with month-end clamping.
Only `succeeded` grants a subscription. Intent, user expiry and public order markers
commit in one transaction. Duplicate webhooks, concurrent calls and repeated screen
events cannot grant that order twice. The client retains ambiguous order IDs for
retries in the current service session, and periodically rechecks provider status
through the authenticated callable when its payment screen is open.

Gift fulfillment also writes a deterministic in-app notification in the same
transaction. Only the winner sends a best-effort server FCM push; disabled/missing
tokens or delivery errors cannot prevent entitlement. If the process stops between
commit and FCM, the in-app notification still exists, but FCM is not retried.

## Coordinated rollout and old orders

This is a coordinated backend/rules/client release: old clients create Firestore
orders directly and grant subscriptions locally. Strict rules intentionally reject
those writes. Stage and verify the complete release first; arrange an upgrade or
maintenance window for older clients before enforcing the new contract.

Before changing production, export/backup existing orders and reconcile open legacy
payments in the merchant dashboard. The old implementation stored a payment-method
ID as `payment_id`, accepted client-set `paid`, and did not record fulfillment.
Consequently it is unsafe to automatically infer a genuine payment, re-charge an
existing order, or grant it again. Legacy orders without a private intent remain
untouched and are rejected for new checkout/automatic fulfillment. Reconcile them
using actual provider payment IDs and known granted periods, then perform a reviewed
one-time migration. Alert on legacy webhook failures rather than silently dropping
them. No migration script with guessed financial state is provided.

Stable create/capture keys are retained across retries. Because YooKassa's documented
idempotency window is 24 hours, an intent with no saved payment ID is never recreated
after 23 hours; an operator must reconcile the ambiguous result instead. The default
flow remains a two-step card payment (authorization, then capture).

The existing App Store branch applied only to a demo account and treated opening the
purchase sheet as payment success. That branch now displays a temporary-unavailable
message before initiating any charge. It requires a real Apple receipt/transaction
verification backend and restore flow before it can safely be enabled. The existing
IAP provider remains untrusted and is no longer instantiated by this screen.

## Checks

From the Flutter project directory:

```sh
node --test functions/initialPayment_function-source/payment.test.js
```

The tests use an atomic Firestore fake and a merchant fake, with no credentials or
network. Coverage includes auth/ownership, server pricing, tampering, capture failure,
duplicate/concurrent fulfillment, rollback, gift renewal, calendar boundaries,
legacy-order rejection, timeout retries, 24-hour safety, and copied-source parity.
They do not replace Firebase emulator Rules tests or a staging sandbox checkout.

Before production, exercise own subscription, gift, repeated callback, cancellation,
browser return, app resume, and retry after connection loss with test credentials.
Confirm gift-history queries, merchant fiscal receipt settings, actual function
generation/region, return URL hosting and recipient permissions in the target project.

Official references consulted:

- [Firebase secret parameters](https://firebase.google.com/docs/functions/config-env?gen=2nd#secret_parameters)
- [YooKassa notifications and status verification](https://yookassa.ru/developers/using-api/webhooks)
- [YooKassa idempotency retention](https://yookassa.ru/developers/using-api/interaction-format#idempotence)
