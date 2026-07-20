# Easy Basket — Production Readiness Audit

**Date:** 2026-07-15
**Scope:** Full end-to-end review of backend (`backend/`) and mobile (`mobile/`) across all major flows — Auth/Session, Order+Payment, Delivery/Rider, Cancellation+Refund, Admin/Catalog.
**Method:** Parallel per-flow code review (backend route → controller → service, and mobile provider → screen).

## Verdict

**Not production-ready as-is (~6/10).** The core architecture (money state machines, idempotency, webhook + reconciler, wallet guards) is genuinely solid. However, the audit found **confirmed money-losing races, a live authentication bypass, and one broken admin flow** that must be fixed before go-live. The blocker list is finite and mostly surgical — not a rewrite.

**Legend:** 🔴 Blocker (fix before live) · 🟠 Should-fix-soon · 🟡 Lower priority
**Status:** `CONFIRMED` (verified in code) · `SUSPECTED` (needs runtime/config confirmation)

---

## Fix status (2026-07-15)

| Blocker | State |
|---|---|
| B1 — test-OTP bypass | ⏳ **Owner to fix** (disable env flags in prod) |
| B2 — admin role change no-op | ✅ Fixed |
| B3 — pay-after-auto-cancel no refund | ✅ Fixed |
| B4 — COD switch-to-UPI deadlock | ✅ Fixed |
| B5 — refund_pending clobbered | ✅ Fixed |
| B6 — approve refunds after packing | ✅ Fixed |
| B7 — legacy delivery status bypass | ✅ Fixed (route removed) |
| B8 — order-create idempotency | ✅ Fixed |

**🟠 Should-fix-soon status:**

| Item | State |
|---|---|
| S1 — clear stale cancel-request on status change | ✅ Fixed |
| S2 — admin list "PAID" badge accuracy | ✅ Fixed |
| S3 — admin detail refund badge | ✅ Fixed |
| S4 — block transitions out of terminal states | ✅ Fixed |
| S5/S6 — 401 auto-refresh on writes | ⏳ Needs decision (auth refactor) |
| S7 — `reportIssue` transition guard | ✅ Fixed |
| S8 — payment success shown too early | ⚠️ Partial (raised 5s→grace+15s; success-wording on `success_unverified` still open) |
| S9 — GPS anti-fraud | ⏳ Needs decision (implement vs drop claim) |
| S10 — Razorpay `payment_capture` | ⏳ Config check (not code) |
| S11 — stock-restore concurrency | ⏳ Open (SUSPECTED, concurrency-only) |
| S12 — refund wording for unpaid orders | ✅ Fixed |

🟡 Lower priority items are **not yet addressed**.
Backend `tsc --noEmit` passes; mobile diagnostics clean. Deploy requires: backend `npm run build` + `pm2 restart`, and a mobile rebuild. (Migration 003 from the earlier cancellation work still applies.)

---

## 🔴 Blockers — fix before going live

- [ ] **B1 · Login OTP `123456` bypass is LIVE in production** — `CONFIRMED`
  - **Where:** `backend/src/controllers/auth.controller.ts:98-105,145-150`
  - **Problem:** Production logs show `LOGIN_USE_TEST_OTP` enabled → anyone can log in as **any** user (including `admin`) using `123456`. `/auth/login` even returns the OTP in the response body. Also auto-opens (mode C) if any Twilio env var is missing — no `NODE_ENV==='production'` guard.
  - **Impact:** Full account takeover for every role.
  - **Fix:** Disable `LOGIN_USE_TEST_OTP` and `DELIVERY_USE_TEST_OTP` in the production env NOW; guard the test-OTP branch behind an explicit non-production flag; never return the OTP in a response.

- [ ] **B2 · Admin "Change User Role" silently does nothing** — `CONFIRMED`
  - **Where:** `mobile/lib/providers/admin_provider.dart:203-237` → `backend/src/controllers/admin.controller.ts:335-358`
  - **Problem:** Mobile sends `{role}` to `PUT /admin/users/:id`, but `updateUser` only reads `{name,email,isActive}` — `role` is ignored. The real endpoint `POST /admin/users/:id/role` is never called by the app.
  - **Impact:** Cannot create `delivery` agents from the app → rider-assignment flow starves (empty "Assign Delivery Agent" dialog). UI shows false "role updated" success.
  - **Fix:** Point the mobile role change at `POST /admin/users/:id/role`.

- [ ] **B3 · Pay-after-auto-cancel → customer charged, no refund** — `CONFIRMED`
  - **Where:** `backend/src/services/order-auto-cancel.service.ts:58-75`, `backend/src/services/payments-v2.service.ts:295-323` (`markPaymentPaid`)
  - **Problem:** A UPI order auto-cancels at 30 min while still `pending`. If the customer pays afterwards, the webhook sets `isPaid=true`/`paymentStatus='paid'` on the already-cancelled order (status change is skipped, but payment fields are still written). Stock already released; no refund fired.
  - **Impact:** Money taken, no goods, no auto-refund.
  - **Fix:** In `markPaymentPaid`, detect terminal/cancelled order state and enqueue a refund instead of marking paid.

- [ ] **B4 · COD "Switch to UPI" deadlock — unclosable order** — `CONFIRMED`
  - **Where:** `backend/src/services/delivery-state.service.ts:483` (switchToUpi), `:338` (collectCash guard), `:409` (markPrepaidDelivered COD guard); `backend/src/services/payments-v2.service.ts:295`
  - **Problem:** Rider taps "Switch to UPI" on a COD order; customer pays. `markPaymentPaid` never touches `deliveryStatus`/`status`. Order stuck in `payment_pending`: `collect-cash` → 409 (order already paid), `mark-prepaid-delivered` → 400 (COD not allowed).
  - **Impact:** Customer charged, goods handed over, order can never reach `delivered`.
  - **Fix:** After a switch-to-UPI payment confirms, transition the order to delivered (or re-route the rider UI to a valid close path).

- [ ] **B5 · Refund-in-progress state never shows (breaks the shipped cancellation feature)** — `CONFIRMED`
  - **Where:** `backend/src/controllers/admin.controller.ts:234` (updateOrderStatus), `:1030` (approveCancellation)
  - **Problem:** `createRefund` sets `paymentStatus='refund_pending'` via a separate DB update, then the controller calls `save(order)` on the stale in-memory entity (`paymentStatus='paid'`), overwriting it back to `paid`.
  - **Impact:** The "Refund in progress" badge never appears; customer sees "Paid Online" for the whole 2–7 day window (self-corrects only when `refund.processed` webhook runs).
  - **Fix:** Re-read or set `order.paymentStatus` after `createRefund`, or use a targeted column update instead of `save(order)`.

- [ ] **B6 · `approveCancellation` refunds AFTER packing (violates policy)** — `CONFIRMED`
  - **Where:** `backend/src/controllers/admin.controller.ts:992-999`
  - **Problem:** Only guards are `cancelRequestStatus==='requested'` and status not `cancelled`/`delivered`. Nothing blocks `preparing`/`out_for_delivery`. A request raised while `pending` survives (see B7) and can be approved after packing → full refund.
  - **Impact:** Refund given for a packed order — contradicts "after packing, no refund."
  - **Fix:** Gate `approveCancellation` to `pending`/`accepted` only (mirror `requestCancellation`).

- [ ] **B7 · Legacy `PUT /delivery/orders/:id/status` bypasses the state machine** — `CONFIRMED`
  - **Where:** `backend/src/routes/delivery.routes.ts:15`, `backend/src/controllers/delivery.controller.ts:51-144`
  - **Problem:** Still mounted under `authorize('delivery')`; directly sets `status='delivered'` with no OTP, no `deliveryStatus`, no `isPaid`, no wallet debit/credit.
  - **Impact:** Rider (or anyone with a rider token) can mark COD orders delivered and pocket cash with zero wallet liability. Cash-theft vector.
  - **Fix:** Remove/deprecate the endpoint, or restrict it to non-terminal admin-only transitions.

- [ ] **B8 · Order-create sends no `Idempotency-Key` → duplicate orders** — `CONFIRMED`
  - **Where:** `mobile/lib/providers/order_provider.dart:294-303`; `backend/src/middleware/idempotency.middleware.ts:101-114`
  - **Problem:** Mobile never sends the header, so orders store `idempotencyKey=NULL` (MySQL allows unlimited NULLs → unique constraint dead). Redis fingerprint fallback fails open on Redis error and buckets by minute, so retries across a minute boundary aren't deduped.
  - **Impact:** A 30s timeout on a committed create-order + a re-tap → second order + double stock decrement.
  - **Fix:** Generate one stable UUID per checkout on mobile and send it as `Idempotency-Key`.

---

## 🟠 Should-fix-soon

- [ ] **S1 · `cancel_request_status` never cleared by `updateOrderStatus`** — `CONFIRMED`
  - `backend/src/controllers/admin.controller.ts:92-234`. Customer keeps seeing false "awaiting approval" banner and loses the cancel button (e.g. once `out_for_delivery`); admin sees a stale approve/refund card on already-advanced/cancelled orders. Fix: normalize `cancel_request_status` on status transitions.

- [ ] **S2 · Admin orders list shows "PAID" for every UPI order** — `CONFIRMED`
  - `mobile/lib/screens/admin/admin_orders_screen.dart:570-587`. Badge keys off `paymentMethod=='upi'`, not `isPaid`/`paymentStatus`. An abandoned/failed UPI order shows green "PAID" → admin dispatches unpaid goods. (Order detail is correct — the two screens disagree.)

- [ ] **S3 · Admin order detail shows "Paid" for refunded orders** — `CONFIRMED`
  - `mobile/lib/screens/admin/admin_order_detail_screen.dart:313-339,831-846`. Badge derives from `order.isPaid`, which is never reset on refund → refunded/refund-pending orders show green "Paid" with no refund indication.

- [ ] **S4 · Admin status endpoint accepts arbitrary transitions** — `CONFIRMED`
  - `backend/src/controllers/admin.controller.ts:92-234`. Only validates the string is one of 6 values; no transition rules on the legacy `status`. `cancelled→delivered`, `delivered→pending`, etc. allowed → inventory/refund ledger desync (no re-decrement, refunded-but-delivered).

- [ ] **S5 · Auto-refresh on 401 only implemented for GET** — `CONFIRMED`
  - `mobile/lib/services/api_service.dart` — `get()` (:42-64) refreshes+retries; `post()`/`put()`/`delete()` just rethrow. After the 15-min token expiry, any write (place order, update profile, add/delete address, fcm-token, logout) throws to the UI instead of refreshing.

- [ ] **S6 · GET retry no-ops unless caller passes `getUpdatedToken`** — `CONFIRMED`
  - `mobile/lib/services/api_service.dart:44-64`. Most callers pass a fixed `token:` but no `getUpdatedToken`, so after refresh the retry is skipped and the user still sees an auth error.

- [ ] **S7 · `reportIssue` has no transition guard** — `CONFIRMED`
  - `backend/src/services/delivery-state.service.ts:525-585`. Unlike other transitions, it never calls `canTransition`; can force a `delivered` order to `rto_pending` → later `completeRto` re-restores stock and refunds an already-delivered order. Add `canTransition(from,'rto_pending')`.

- [ ] **S8 · Payment success shown too early / 5s resume fallback pre-empts callback** — `CONFIRMED`
  - `mobile/lib/screens/payment/payment_screen.dart:50-101,210-235`. (a) On resume after >5s, it navigates to "pending — check your orders" before the plugin `onSuccess` fires, so client `verify` is skipped and successful payers see a confusing message. (b) A `success_unverified` verify response renders "Payment successful! Order placed" + clears cart, but the webhook can still flip it to failed/cancelled. Fix: raise the threshold; word it "payment received, confirming" until `paymentStatus='paid'`.

- [ ] **S9 · GPS anti-fraud is non-functional** — `CONFIRMED`
  - `backend/src/services/delivery-state.service.ts:277` (comment "within 200m") — no distance computation server-side, and the mobile app never sends `lat`/`lng` on `arrived`/`collect-cash`/`mark-prepaid-delivered`. The advertised proximity guard does not exist.

- [ ] **S10 · Razorpay order created without `payment_capture`** — `SUSPECTED`
  - `backend/src/services/razorpay.service.ts:35-47`. Confirmation depends on the account-level auto-capture setting. If off, payments sit `authorized` (never `captured`), order never confirms, auto-cancels at 30 min. Verify the Razorpay account setting or set `payment_capture` explicitly.

- [ ] **S11 · Non-idempotent stock restore under concurrency** — `SUSPECTED`
  - `backend/src/services/order-inventory.service.ts:24-38`. Plain read-add-save with no conditional UPDATE; two concurrent approve/cancel requests for the same order both pass the check-then-act guard and both restore stock → inventory inflation. (Monetary refund itself is protected by the SUM cap.)

- [ ] **S12 · Refund wording shown for COD / unpaid pre-packed orders** — `CONFIRMED`
  - `mobile/lib/models/order_model.dart:127` (`isRefundEligible` is status-only) → `order_tracking_screen.dart`. A COD/unpaid order shows "Cancel & Request Refund" and "full amount will be refunded" though nothing was paid. Cosmetic but customer-facing money messaging.

---

## 🟡 Lower priority

- [ ] **L1 · User `birthday` wiped on every token refresh** — `CONFIRMED` — `auth.controller.ts:367-377` refresh response omits `birthday`; `auth_provider.dart:193-199` overwrites persisted user. Lost every ~15 min until re-login.
- [ ] **L2 · RTO not mirrored to customer `status`** — `CONFIRMED` — `delivery-state.service.ts:555-558`. Customer sees "Out for Delivery" while the order is actually returning to hub.
- [ ] **L3 · Two divergent delete-product endpoints (soft vs hard)** — `CONFIRMED` — `admin.controller.ts:637-658` (soft) vs `product.controller.ts:428-446` (hard `remove`, 500s on FK for products with order history).
- [ ] **L4 · Deactivated users invisible with no re-activate path** — `CONFIRMED` — `admin.controller.ts:309-317` hardcodes `WHERE isActive=true`.
- [ ] **L5 · Mobile order parsing not null-safe for required relations** — `CONFIRMED` — `order_model.dart:193-194,56`. A null `user`/`deliveryAddress`/`product` crashes the whole list parse (no per-item try/catch).
- [ ] **L6 · Doorstep OTP keyed to phone, not order** — `SUSPECTED` — `delivery-otp.service.ts:44-113`. A customer with two concurrent deliveries has one shared phone verification; last-writer-wins.
- [ ] **L7 · Refresh tokens never rotated/pruned** — `CONFIRMED` — `auth.controller.ts:200-206,357`. Table grows unbounded; no stolen-token reuse detection.
- [ ] **L8 · `verify` uses non-canonicalized phone number** — `SUSPECTED` — `auth.controller.ts:117,161-166`. Different normalization than `login`; latent duplicate-user risk (masked today by 10-digit-only input).
- [ ] **L9 · Refresh in-flight coordination is a 500ms timeout guess** — `SUSPECTED` — `api_service.dart:263-282`. Concurrent caller returns failure if refresh exceeds 500 ms.
- [ ] **L10 · Legacy self-assign `POST /orders/:id/accept` never sets `deliveryStatus`** — `CONFIRMED (latent)` — `delivery.controller.ts:241-313`. Rider claiming via this path is dead-ended (no action buttons). App doesn't wire it today, but endpoint + admin copy imply it exists.
- [ ] **L11 · Customer can't delete an address used on an order** — `SUSPECTED` — `address.controller.ts:288-314` hard `remove` vs FK on `Order.deliveryAddress` → opaque 500.

---

## What's solid (verified, not bugs)

- Payment double-refund guards: per-payment lock + `SUM(refunds) ≤ amount` cap + same-key idempotency.
- Webhook: raw-body signature (mounted before `express.json()`), constant-time compare, `UNIQUE(event_id)` dedupe with crash-recovery replay.
- Reconciler + BullMQ fallback (post-fix): `reconcile-${id}` jobId, `maxRetriesPerRequest:null`, idempotent transitions.
- Paise/rupee conversion consistent at boundaries.
- `JWT_SECRET` enforced at boot (≥32 chars); `authenticate`/`authorize` re-fetch user + check `isActive`.
- All admin routes gated by `authenticate`+`authorize('admin')`; order/address endpoints enforce ownership in the query.
- Server-side price recompute on order create (no cart-tampering exposure).
- Wallet credit is single-shot/atomic with the `delivered` transition; `isPaid`/`from==='delivered'` guards prevent double-credit.
- `payment-method` aliasing (`razorpay→upi`, `cash→cod`) works; migration `003` matches the `Order` entity columns exactly.

---

## Suggested fix order

1. **B1** (disable test-OTP env in prod) — zero-code, do immediately.
2. **B5, B6, S1** — refund state + policy gate (repairs the cancellation feature just shipped).
3. **B3, B4** — payment/delivery money races.
4. **B2** — restore admin role-change / delivery-agent creation.
5. **B7, B8** — close the legacy delivery bypass; add order-create idempotency key.
6. 🟠 batch, then 🟡 as time allows.
