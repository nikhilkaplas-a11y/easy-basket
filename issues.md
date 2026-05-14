# Easy Basket — Code Review Issues

> Generated 2026-05-13 from a senior-engineer review of both `/backend` and `/mobile` folders.
> Every issue includes file:line references, root cause, impact, and a concrete fix.

## Summary

| Area | CRITICAL | HIGH | MEDIUM | LOW | Total |
|---|---:|---:|---:|---:|---:|
| Backend | 8 | 13 | 9 | 10 | 40 |
| Mobile  | 4 | 14 | 12 | 10 | 40 |
| **Total** | **12** | **27** | **21** | **20** | **80** |

## Top 10 Fix-This-Week List

1. **Backend** — Remove the JWT default-secret fallback (`'your-secret-key'`); fail-closed on missing env.
2. **Backend** — Add per-phone/per-IP rate limits on `/auth/login` + `/auth/verify` (Twilio SMS-pump risk).
3. **Backend** — Wrap order creation in a transaction with `UPDATE … WHERE stock >= :q`; apply the existing `idempotency` middleware to `POST /api/orders`.
4. **Backend** — Gate `OrderAutoCancelService` + `PaymentsReconcilerService` behind `NODE_APP_INSTANCE === '0'` (PM2 cluster runs them N times → double stock restore, double Razorpay polls).
5. **Backend** — Make webhook secret required at boot; add `RAZORPAY_WEBHOOK_SECRET` to `ecosystem.config.js` env block.
6. **Backend** — Lock down public `GET /api/orders/status/:id` (IDOR enumeration of order velocity / GMV).
7. **Mobile** — Rotate the Android signing key. Remove the hardcoded fallback password `"nik3122@@"` from `build.gradle.kts`. Add `*.jks` to `.gitignore`.
8. **Mobile** — Move JWT + refresh token from SharedPreferences to `flutter_secure_storage`.
9. **Mobile** — Add iOS `Info.plist` usage description strings for Location, Camera, Photos, Microphone (app crashes on iOS today).
10. **Mobile** — Don't create the order before Razorpay success; rely on the webhook `payment.captured` as source of truth.

---

# BACKEND ISSUES

## CRITICAL — Backend

### B-C1. JWT secret falls back to a hardcoded default string
- **File:** `backend/src/middleware/auth.middleware.ts:23`, `backend/src/controllers/auth.controller.ts:150,325`
- **Category:** Auth / Security
- **Issue:** Both signing and verification do `process.env.JWT_SECRET || 'your-secret-key'`. A missing/typoed env var silently signs with the literal default.
- **Impact:** Anyone who reads the source can mint valid JWTs for any `userId` (including admins) and bypass auth entirely.
- **Fix:** Load `JWT_SECRET` once at boot. If missing or length < 32, `console.error` and `process.exit(1)`. Never use a default.

### B-C2. Admin can change any user's `role` to any string — persistent privilege escalation
- **File:** `backend/src/controllers/admin.controller.ts:333-357`, `backend/src/entities/User.ts:30`
- **Category:** Auth
- **Issue:** `AdminController.updateUser` lets an admin set `role` to any free-form string. No enum, no audit, no 4-eyes check.
- **Impact:** Single compromised admin token = permanent backdoor by promoting another account.
- **Fix:** Restrict role to a TS + DB enum. Move role transitions to a dedicated endpoint with audit logging.

### B-C3. No rate limit on `/api/auth/login` — Twilio SMS-pump / cost-drain attack
- **File:** `backend/src/routes/auth.routes.ts:7`, `backend/src/controllers/auth.controller.ts:39-76`
- **Category:** Security / Cost
- **Issue:** No `express-rate-limit`, no helmet, no CAPTCHA. Each request triggers a Twilio SMS at ~₹4–25/SMS.
- **Impact:** Attacker can drain Twilio balance in minutes; can also harass arbitrary users with OTP spam.
- **Fix:** Redis-backed rate limit (3 OTPs/phone/15min; 10/IP/hour). Reject obviously-malformed phones before hitting Twilio. Validate phone format server-side.

### B-C4. Order creation has no transaction; stock decrement runs after `save` — concurrent oversell + orphan orders
- **File:** `backend/src/controllers/order.controller.ts:147-177`
- **Category:** Payment / Data
- **Issue:** Order is saved first, then each item's stock is mutated via separate `findOneBy → variant.stock -= qty → save()`. No row lock, no transaction, no version column.
- **Impact:** Two simultaneous orders for the last unit both succeed → overselling. Partial failure leaves orders with un-deducted stock; later cancel over-credits.
- **Fix:** Wrap in `AppDataSource.manager.transaction`. Use `UPDATE product_variant SET stock = stock - :q WHERE id = :id AND stock >= :q` and assert `affected === 1`; rollback otherwise.

### B-C5. Order creation has no idempotency wired — double-tap = duplicate orders + double-charge
- **File:** `backend/src/controllers/order.controller.ts:16`, `backend/src/routes/order.routes.ts:13`
- **Category:** Payment
- **Issue:** `POST /api/orders/` is mounted with no `idempotency(...)` middleware (which exists in the codebase). `Order.idempotencyKey` column exists with a unique constraint but is never populated.
- **Impact:** Network blips, slow Razorpay callbacks, or impatient users will double-charge. Each duplicate kicks off its own auto-cancel timer that restores inventory you never had.
- **Fix:** `router.post('/', idempotency('order-create', 60), OrderController.createOrder)`. Persist the `Idempotency-Key` header into `Order.idempotencyKey` inside the transaction.

### B-C6. Payments reconciler bypasses the amount-mismatch guard via synthetic webhook events
- **File:** `backend/src/services/payments-reconciler.service.ts:107-110,182-204`, `backend/src/services/payments-v2.service.ts:284-306`
- **Category:** Payment
- **Issue:** Reconciler reads `latest.amount` from Razorpay, builds a synthetic event with that same `latestAmount`, then calls `handleWebhook → onPaymentCaptured`. The mismatch check compares Razorpay's amount to itself → guard silently passes.
- **Impact:** A real Razorpay capture for a wrong amount would normally cancel + refund + restore inventory. Via the reconciler path, it's rubber-stamped as paid.
- **Fix:** Don't synthesize. In the reconciler, compare `latestAmount` to `payment.amountPaise` directly before calling the transition; call `markPaymentFailed` on mismatch.

### B-C7. `paymentMethod` is unvalidated free-form string — `"Cash"` vs `"cash"` desynchronizes the flow
- **File:** `backend/src/controllers/order.controller.ts:153,183`, `backend/src/services/delivery-state.service.ts:262,408`, `backend/src/entities/Order.ts:107`
- **Category:** Payment
- **Issue:** Creation uses `=== 'UPI'` (strict). Delivery uses `.toLowerCase() === 'cash'`. Column is free-form `string`. `"Cash"` creates a Razorpay order at checkout but later branches as COD at the rider → cash collected on a Razorpay-paid order. `"upi"` (lowercase) bypasses Razorpay → order auto-cancels.
- **Impact:** Double-billing OR silent cancellation of legit orders.
- **Fix:** Normalize and validate at the API boundary against an enum `'upi' | 'cod'`. Convert column to MySQL ENUM. Use the normalized value throughout.

### B-C8. Firebase service-account JSON loaded from env var with stack-trace dumps on parse failure
- **File:** `backend/src/services/fcm.service.ts:91-100`
- **Category:** Security
- **Issue:** `FIREBASE_SERVICE_ACCOUNT` carries a private key in an env var. PM2 env is readable by anyone with shell access (`pm2 env <id>`). On parse failure, the catch logs `error` which may include the raw value.
- **Impact:** Service-account JSON allows arbitrary FCM pushes to all users.
- **Fix:** Load from a file path (`FIREBASE_SERVICE_ACCOUNT_PATH`) with `0600` perms. Strip stack traces from the catch. Never log env keys at startup.

## HIGH — Backend

### B-H1. `GET /api/orders/status/:id` is public — IDOR enumeration of business metrics
- **File:** `backend/src/controllers/order.controller.ts:356-381`, `backend/src/routes/order.routes.ts:8`
- **Category:** Security (IDOR)
- **Issue:** Endpoint mounted before `router.use(authenticate)`. Returns `id, status, totalAmount, createdAt, updatedAt` for any integer id. PK is sequential auto-increment.
- **Impact:** Scraping `/1..N` leaks order count, daily velocity, GMV, per-order amounts. Competitor intel + fraud targeting.
- **Fix:** Require auth + ownership check. For unauth tracking links, generate an opaque short token per order.

### B-H2. Refund endpoint can issue two refund rows → double refund via Razorpay
- **File:** `backend/src/controllers/payment.controller.ts:178-235`, `backend/src/services/payments-v2.service.ts:438-522`
- **Category:** Payment
- **Issue:** No check for existing pending/processed refunds against the same payment. Customer-initiated refund (client-provided idempotency key) + admin-initiated cancel (key `admin-cancel-${id}`) → two refund rows, two Razorpay calls, both for full `payment.amountPaise`.
- **Impact:** Customer refunded twice; direct money loss.
- **Fix:** Before creating a refund, sum existing `pending+processed` refunds for the payment; reject if `sum + new ≥ payment.amountPaise`. Or ban customer-initiated refunds entirely.

### B-H3. Failed webhook processing returns 500 → Razorpay retries → already-inserted row dedupes → original work never reruns
- **File:** `backend/src/services/payments-v2.service.ts:217-269`
- **Category:** Payment
- **Issue:** WebhookEvent row is inserted, then processed. If processing throws after insert, row exists with `processedAt = null`. Retries return `duplicate_event` and skip.
- **Impact:** Stuck payments, missing FCM notifications, customers thinking payment failed.
- **Fix:** Either (a) insert the row inside the same transaction as processing so failure rolls back, or (b) add a reconciler tick scanning `webhook_events WHERE processed_at IS NULL AND received_at < NOW() - INTERVAL 5 MINUTE`.

### B-H4. Delivery OTP / login accept the magic string `'123456'` when Twilio is misconfigured
- **File:** `backend/src/services/delivery-otp.service.ts:67-72,109-112`, `backend/src/controllers/auth.controller.ts:107`
- **Category:** Auth
- **Issue:** "Mode C" branch fires when `TwilioService.isConfigured()` is false. Also writeable via `*_USE_TEST_OTP` flags (case-tolerant boolean parse).
- **Impact:** A typo in `.env` silently disables real OTP across the platform — riders can mark every order delivered, anyone can log in as anyone with `123456`.
- **Fix:** In `NODE_ENV === 'production'`, refuse to boot if Twilio creds are unset. Ignore `*_USE_TEST_OTP` in prod. Return 503 if OTP cannot be verified.

### B-H5. No migration runner; schema drift undetected
- **File:** `backend/src/config/database.ts:30,52`
- **Category:** Data / Deploy
- **Issue:** `synchronize: false` is correct, but `migrations: []`. Two manual `.sql` files exist; nothing tracks which have been applied.
- **Impact:** Future schema changes get deployed without DB migration; queries fail at runtime on whichever env didn't get the SQL.
- **Fix:** Enable TypeORM migrations (`migrations: ['dist/migrations/*.js']`, `migrationsRun: true`) or adopt `node-pg-migrate`.

### B-H6. Background timers run on every PM2 worker → double stock restore, double Razorpay polls
- **File:** `backend/src/index.ts:142-145`, `backend/ecosystem.config.js:9` (`instances: 'max'`, `exec_mode: 'cluster'`)
- **Category:** Deploy / Data
- **Issue:** Each worker imports `index.ts` and calls `OrderAutoCancelService.start()` + `PaymentsReconcilerService.start()`. With N workers, the auto-cancel scan returns the same row to multiple workers → `restoreReservedStockForItems` runs N times → stock is doubled back.
- **Impact:** Severe inventory drift the longer the app runs. Doubled Razorpay API spend.
- **Fix:** Gate both services on `process.env.NODE_APP_INSTANCE === '0'`, or move to a dedicated worker / cron, or use Redis `SET NX EX` lock keyed by the cron name.

### B-H7. `RAZORPAY_WEBHOOK_SECRET` missing from `ecosystem.config.js` env block
- **File:** `backend/ecosystem.config.js:11-38`
- **Category:** Deploy / Payment
- **Issue:** Explicit env list forwards Razorpay key+secret but not the webhook secret. If PM2 env shadows `.env`, the var is `undefined` → every webhook signature check fails → all webhooks 401.
- **Impact:** Payments stuck in `success_unverified`; only the reconciler eventually recovers them.
- **Fix:** Add it. Better: drop the explicit env list and let `dotenv` inside the app load everything.

### B-H8. Refresh tokens are plaintext, never rotated, never revoked
- **File:** `backend/src/entities/RefreshToken.ts`, `backend/src/controllers/auth.controller.ts:155-168,283-339`
- **Category:** Auth
- **Issue:** `token` column is plaintext. `/refresh` issues new access token without rotating refresh token. Login creates a new RT without revoking older ones.
- **Impact:** DB-read leak → all active sessions stolen. No way to detect token theft via rotation flag.
- **Fix:** Store SHA-256 of the token; compare hashes. Rotate on every refresh. Track `lastUsedAt`, `userAgent`. Revoke all on phone change.

### B-H9. Phone numbers not normalized at storage → duplicate accounts for same human
- **File:** `backend/src/entities/User.ts:17`, `backend/src/controllers/auth.controller.ts:17-22,123`
- **Category:** Auth / Data
- **Issue:** DB column is `varchar unique`, but normalization only strips whitespace. `9876543210`, `+919876543210`, `09876543210` create separate users.
- **Impact:** Identity confusion, split order history, account merging requires manual DB ops.
- **Fix:** Normalize to E.164 server-side before lookup/save (`TwilioService.normalizePhoneToE164` or `libphonenumber-js`). Reject malformed phones with 400.

### B-H10. CORS reflects any origin with `credentials: true`
- **File:** `backend/src/index.ts:37-44`
- **Category:** Security
- **Issue:** "Allow all origins for development" ships to prod. With `credentials: true`, any site can call your API with the user's cookies (if used) and read responses.
- **Impact:** Cross-origin admin actions from any malicious website if the admin web portal uses cookies.
- **Fix:** Hardcoded allowlist: `origin: ['https://admin.easybasket.in', 'https://easybasket.in']`. Drop `credentials: true` unless cookies are actually needed.

### B-H11. Admin `updateOrderStatus` bypasses the state machine
- **File:** `backend/src/controllers/admin.controller.ts:168-178,215-230`
- **Category:** Auth / Data
- **Issue:** Legacy admin endpoint lets admin set arbitrary `status` + `isPaid` without going through `DeliveryStateService` transition guards.
- **Impact:** Invalid state transitions, lost audit trail in `OrderEvent`.
- **Fix:** Apply state-machine guards in the legacy endpoint, or deprecate it in favor of `assignRiderToOrder` / `completeRto`.

### B-H12. COD `cashCollectedPaise` accepted as JS `number` without bounds check
- **File:** `backend/src/controllers/delivery.controller.ts:524-535`, `backend/src/services/delivery-state.service.ts:293-307`
- **Category:** Payment
- **Issue:** Amount-match check protects honest amounts, but `amountPaise` is typed `number` (loses precision above 2^53). Discipline elsewhere is BigInt-string.
- **Impact:** Defense-in-depth gap. If amount-match check ever regresses, integer overflow exploit becomes possible.
- **Fix:** Validate `Number.isSafeInteger(amountPaise) && amountPaise > 0 && amountPaise < 100_000_00`. Standardize on string|BigInt everywhere.

### B-H13. Multer trusts client-provided MIME type → stored XSS via SVG
- **File:** `backend/src/middleware/upload.middleware.ts:13-21`, `backend/src/services/s3.service.ts:84-87,98-102`
- **Category:** Security
- **Issue:** `file.mimetype` comes from the client header; S3Service re-uses it. `getFileExtension(file.originalname)` derives extension from client filename → an SVG with forged `image/jpeg` header lands as `.svg` in S3.
- **Impact:** Admin views catalog → SVG executes JS in admin's session.
- **Fix:** Detect content by magic bytes (`file-type` npm). Allowlist `image/jpeg|png|webp` only. Force extension from detected type, not client filename. Ban SVG.

## MEDIUM — Backend

### B-M1. `Refund.razorpayRefundId` UNIQUE on nullable column (MySQL allows multiple NULLs)
- **File:** `backend/src/entities/Refund.ts:31-33`
- **Issue:** UNIQUE constraint provides no protection until Razorpay returns an ID. Concurrent admin actions can produce two pending refund rows pointing to the same eventual Razorpay refund.
- **Fix:** Enforce at service layer (no concurrent pending refunds per payment). See B-H2.

### B-M2. `OrderInventoryService.restoreReservedStockForItems` is non-idempotent
- **File:** `backend/src/services/order-inventory.service.ts:12-33`
- **Issue:** Called from 5 paths (customer cancel, admin cancel, payment failed, RTO, auto-cancel). Stock can be restored twice on race. The `AMOUNT_MISMATCH` path doesn't check status before restoring.
- **Fix:** Track `stockRestoredAt` on order; enforce idempotency. Or move to a reservation table.

### B-M3. `Order.deliveryBoy` typed non-null in TS but nullable in DB
- **File:** `backend/src/entities/Order.ts:25-27`
- **Issue:** `deliveryBoy!: User;` lies to TypeScript. Codebase defensively uses `?.` everywhere; a future "type fix" that removes `?.` will NPE.
- **Fix:** `deliveryBoy!: User | null;`. Audit other entity fields with `nullable: true`.

### B-M4. Sequential integer order IDs leak GMV / volume
- **File:** All entities — `@PrimaryGeneratedColumn()`
- **Fix:** Add opaque `publicId` (ULID/UUID) for external references; keep numeric PK internal.

### B-M5. Auto-cancel cron loads all stale orders in one query, no pagination
- **File:** `backend/src/services/order-auto-cancel.service.ts:58-65`
- **Issue:** Returns every pending order with relations; OOM on Twilio outage.
- **Fix:** `.take(50)` per tick.

### B-M6. `birthday` not validated
- **File:** `backend/src/controllers/auth.controller.ts:220-226`
- **Fix:** Validate ISO format, range-check year.

### B-M7. DB pool of 10 small for cluster + cron
- **File:** `backend/src/config/database.ts:54-57`
- **Fix:** Bump to 20–25; set `acquireTimeout`; monitor.

### B-M8. Dead `OTPService` in-memory map (lands in trap if rewired)
- **File:** `backend/src/services/otp.service.ts`
- **Fix:** Delete the file.

### B-M9. No input validation library (zod/joi); negative `quantity` exploitable
- **File:** All controllers; especially `backend/src/controllers/order.controller.ts`
- **Issue:** Hand-rolled checks miss cases. `quantity` is never required `> 0` → negative price-quantity math produces negative totals.
- **Fix:** Adopt zod schemas at every controller entry.

## LOW — Backend

- **B-L1.** `console.log` everywhere; no structured logger / request-id correlation → use pino.
- **B-L2.** Logs leak PII (phone numbers, FCM token prefixes) in `fcm.service.ts:137,233,257`.
- **B-L3.** Module-level side effects (`S3Service.initialize`, `RazorpayService.init`, `FCMService.initialize`) run on import before `dotenv.config()`.
- **B-L4.** `bcrypt` declared in `package.json` but never imported — dead dep.
- **B-L5.** `parseInt(x as string)` without radix in admin controllers.
- **B-L6.** Address fuzzy-duplicate detection runs Levenshtein per existing address with no cap — DoS surface.
- **B-L7.** Deleting a category cascades to subcategories but `Product.category` has no `onDelete` → FK error / orphans.
- **B-L8.** `OrderInventoryService` calls `ProductController.invalidateProductListCache()` — services importing controllers.
- **B-L9.** ESLint/Prettier configured but no husky/lint-staged.
- **B-L10.** Upload routes mounted at `/api/admin` alongside admin.routes — shadow risk.

---

# MOBILE ISSUES

## CRITICAL — Mobile

### M-C1. Android keystore password hardcoded in committed source
- **File:** `mobile/android/app/build.gradle.kts:44-48`
- **Category:** Security
- **Issue:** Release signing falls back to literal `"nik3122@@"` when env vars are missing. `.gitignore` doesn't exclude `*.jks`/`*.keystore`/`key.properties`.
- **Impact:** Anyone with source can sign malicious APKs that Play Store / users trust as Easy Basket. Hijacking the signing identity is unrecoverable for an Android app.
- **Fix:** Remove the literal fallback; fail the build if env vars unset. Rotate the password. Add `*.jks`, `*.keystore`, `key.properties` to `.gitignore`. Move secrets to CI variables.

### M-C2. JWT access + refresh tokens stored in plaintext SharedPreferences
- **File:** `mobile/lib/providers/auth_provider.dart:117-125,197`
- **Category:** Security
- **Issue:** Both tokens persisted via `prefs.setString(...)`. SharedPreferences is unencrypted XML on Android / plist on iOS.
- **Impact:** On rooted/jailbroken devices or via backup, refresh tokens (long-lived) are trivially extracted → persistent account takeover.
- **Fix:** Use `flutter_secure_storage` (Keystore / Keychain) for both tokens. SharedPrefs is fine for the user profile blob.

### M-C3. `android:allowBackup` not disabled — tokens auto-backed-up
- **File:** `mobile/android/app/src/main/AndroidManifest.xml:8-11`
- **Category:** Security / Privacy
- **Issue:** Default Android backup is on; SharedPreferences XML containing JWTs is uploaded to Google Drive / extractable via `adb backup`.
- **Impact:** Tokens leave the device unnecessarily; can be restored to a different device.
- **Fix:** Add `android:allowBackup="false"` and `tools:replace="android:allowBackup"`. Or define `<full-backup-content>` excluding `shared_prefs/`.

### M-C4. Order is created BEFORE Razorpay success — orphan / double-charge risk
- **File:** `mobile/lib/screens/payment/payment_screen.dart:350-382`
- **Category:** Payment
- **Issue:** Client calls `orderProvider.createOrder(...)` first, THEN opens Razorpay. If the app dies mid-payment, the order is pending with no payment; user retries → double charge.
- **Impact:** Money loss; manual reconciliation; customer trust.
- **Fix:** Either persist the pending Razorpay order and let the backend webhook reconcile (industry standard), or detect pending payment on app resume and force re-verify against backend by Razorpay order ID. Add idempotency keys to create-order.

## HIGH — Mobile

### M-H1. Only `GET` retries on 401 — POST/PUT/DELETE surface "auth required" instead of refreshing
- **File:** `mobile/lib/services/api_service.dart:87-228`
- **Issue:** `_handleTokenExpiration` is wired into `get()` only. Other verbs `rethrow` `TokenExpiredException` with no retry.
- **Impact:** Mutations on stale access tokens (place order, COD collect, admin status update) fail visibly. Users may retry and create duplicates.
- **Fix:** Apply same refresh-and-retry pattern to POST/PUT/DELETE. Use server-supported idempotency keys to make POST retries safe.

### M-H2. Token refresh single-flight is broken — concurrent 401s trigger duplicate refreshes
- **File:** `mobile/lib/services/api_service.dart:263-282`
- **Issue:** `_isRefreshing` is per-instance, but each Provider builds its own `ApiService()`. Within an instance, a 500ms sleep is used as the wait — non-atomic, races, retries with still-expired token.
- **Impact:** With refresh-token rotation, parallel refreshes invalidate each other → forced logout.
- **Fix:** One shared `ApiService` (DI singleton); gate refresh with a `Completer<bool>` so concurrent callers await the same in-flight refresh.

### M-H3. iOS `Info.plist` missing every permission usage description
- **File:** `mobile/ios/Runner/Info.plist:1-50`
- **Issue:** No `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`. Plus no `UIBackgroundModes` for FCM.
- **Impact:** iOS hard-crashes (SIGABRT) the moment any permission API is called. Fails App Store review.
- **Fix:** Add usage descriptions for every permission used. Add `UIBackgroundModes` `remote-notification`. Confirm ATS allows HTTPS only.

### M-H4. Razorpay client-side verification can be bypassed if backend trusts client
- **File:** `mobile/lib/services/razorpay_service.dart:70-95`, `mobile/lib/screens/payment/payment_screen.dart:120-263`
- **Issue:** Mobile success handler POSTs `paymentId`/`signature` to backend. Backend MUST recompute HMAC server-side — if it trusts the client payload, an attacker forges success.
- **Impact:** Free orders if backend trusts client.
- **Fix:** Confirm backend `verifyPayment` recomputes `HMAC_SHA256(razorpayOrderId|paymentId, key_secret)` and compares to signature. Prefer webhook `payment.captured` as truth.

### M-H5. Role-based redirect uses stale role from SharedPreferences without server re-validation
- **File:** `mobile/lib/routes/app_router.dart:54-127`, `mobile/lib/core/startup_deep_link.dart:64-73`
- **Issue:** Router reads role from cached `user_data` JSON. Editable on rooted devices; not refreshed after server-side demotion.
- **Impact:** Defense-in-depth gap. Admin UI shell flashes for a window after demotion. Manipulated JSON shows admin shell (backend will block actual calls — assuming JWT carries role).
- **Fix:** On cold start, hit `/auth/me` or decode role from JWT before routing. Refresh role on FCM push that signals role change.

### M-H6. `print()` statements ship to production — leak URLs, error bodies, IDs
- **File:** `mobile/lib/services/api_service.dart:29,107,153,197`; 77 calls across 15 files
- **Issue:** Unconditional `print()` (no `kDebugMode` guard). Logs server error bodies which may include PII.
- **Impact:** Info leak via `logcat`, performance hit on hot paths.
- **Fix:** Replace with `debugPrint()` or wrap in `kDebugMode`. Add `avoid_print` lint.

### M-H7. Cold-start FCM data coerces nested objects via `toString` → broken deep links
- **File:** `mobile/lib/main.dart:41-48`
- **Issue:** Nested map values become `"{id: 42}"` strings that `routePathFromFcmData` can't parse. Also, "logged-in" check is `access_token != null`, not validity.
- **Impact:** Edge-case FCM payloads silently misroute; expired tokens cause cold-start 401 storms before redirect to login.
- **Fix:** Don't coerce. Check JWT `exp` before honoring cold-start route.

### M-H8. Providers don't `reset()` on logout — stale data lingers in memory across account switch
- **File:** `mobile/lib/main.dart:94-145`, `mobile/lib/providers/admin_provider.dart`, `delivery_provider.dart`, etc.
- **Issue:** `ChangeNotifierProxyProvider` keeps the same provider instances. `AuthProvider.logout()` doesn't clear AdminProvider/OrderProvider/DeliveryProvider/ProductProvider state.
- **Impact:** Multi-account device leak — user A's admin data sits in memory when user B logs in. Push notification race could show it briefly.
- **Fix:** Add `reset()` to every provider and call them from `AuthProvider.logout()`.

### M-H9. `CartProvider._loadCart` quantity restore can silently truncate items
- **File:** `mobile/lib/providers/cart_provider.dart:38-66`
- **Issue:** Restore loops `addItem` N times (each call clamps to `maxStock`), then `updateQuantity` silently fails if `quantity > maxStock`. O(n) per item.
- **Impact:** On app restart, cart shows fewer items than user saved with no warning.
- **Fix:** Re-fetch stock from server before restore; warn user when quantity was reduced.

### M-H10. Web Razorpay path is a `print` + early return — silent payment failure
- **File:** `mobile/lib/services/razorpay_service.dart:149-164`
- **Issue:** `_openRazorpayWebCheckout` is a TODO. Order is already created by then.
- **Impact:** Accidental web/PWA builds → orders pile up unpaid.
- **Fix:** Either omit Razorpay from web builds entirely, implement Checkout.js, or block the create-order call on web.

### M-H11. Four screens run independent polling timers with no backoff
- **File:** `mobile/lib/screens/delivery/delivery_dashboard_screen.dart:46-53`, `mobile/lib/screens/admin/admin_orders_screen.dart:66-78`, `mobile/lib/screens/admin/admin_dashboard_screen.dart:71-82`, `mobile/lib/screens/orders/order_tracking_screen.dart:58-63`
- **Issue:** `Timer.periodic` at 15-30s intervals, no exponential backoff, no offline detection.
- **Impact:** Battery + data drain. DoS-amplification of any backend incident.
- **Fix:** Add exponential backoff. Use `connectivity_plus` to pause when offline. Prefer FCM-driven invalidation over polling.

### M-H12. `notifyListeners()` from FCM callbacks holds a stale `BuildContext`
- **File:** `mobile/lib/services/notification_service_mobile.dart:96,323,332`, `mobile/lib/main.dart:172-189`
- **Issue:** `NotificationService` keeps `BuildContext _context` since `initialize()`. FCM listener calls `_context!.push(...)` even after the originating widget is disposed.
- **Impact:** Crashes when FCM arrives after navigation.
- **Fix:** Use `AppRouter.router.push` everywhere (don't hold long-term context). Use a `navigatorKey` for overlay access.

### M-H13. `Future.delayed` callback in `verifyOTP` fires after dispose
- **File:** `mobile/lib/providers/auth_provider.dart:137-143`
- **Issue:** Fire-and-forgotten 500ms timer calls `notificationService.ensureTokenSent()` regardless of state.
- **Impact:** Minor today; class of bug invites future NPEs.
- **Fix:** Use `addPostFrameCallback` or sequence the FCM send in the caller.

### M-H14. Cart total computed in floats; sent to Razorpay as paise via `(amount * 100).toInt()`
- **File:** `mobile/lib/services/cart_service.dart:43-45`, `mobile/lib/services/razorpay_service.dart:129`
- **Issue:** Classic float drift (`0.1 + 0.2 = 0.300000…04`), then truncate. UI shows ₹599.97 while Razorpay is charged 59996 paise.
- **Impact:** UI-vs-charge mismatch. Trust issues; accounting reconciliation pain at scale.
- **Fix:** Use `int paise` everywhere on client. Backend must recompute total from item IDs as source of truth.

## MEDIUM — Mobile

### M-M1. No certificate pinning for a payment app
- **File:** `mobile/lib/services/api_service.dart` (entire file)
- **Fix:** Use `dio` (already a dep) with `http_certificate_pinning` or SPKI hash pinning.

### M-M2. Cold-start routing trusts `access_token != null`, not validity
- **File:** `mobile/lib/main.dart:37-38`
- **Fix:** Decode JWT and check `exp` before honoring cold-start route.

### M-M3. AddressProvider / ServiceAreaProvider each build their own `ApiService()` with no token-expiry callback
- **File:** `mobile/lib/providers/address_provider.dart:37`, `mobile/lib/providers/service_area_provider.dart:5`
- **Issue:** Refresh callback only wired for Product/Order/Delivery/Admin. Address save fails opaquely after token expiry.
- **Fix:** Inject one shared `ApiService` from `MultiProvider`.

### M-M4. `LocationProvider.openAppSettings` shadows `permission_handler.openAppSettings`
- **File:** `mobile/lib/providers/location_provider.dart:166-174`
- **Fix:** Rename to `openSystemSettings`.

### M-M5. `_pickBestSamePincodeAddress` returns default address without considering GPS distance
- **File:** `mobile/lib/providers/proximity_provider.dart:61-82`
- **Issue:** User at office with home as default gets home auto-selected.
- **Fix:** Pick nearest within same pincode; fall back to default only when no nearby match.

### M-M6. Duplicate-address check uses degree-diff `< 0.0005` instead of `Geolocator.distanceBetween`
- **File:** `mobile/lib/providers/address_provider.dart:457-462`, `mobile/lib/providers/order_provider.dart:351-358`
- **Issue:** Two different distance heuristics in the same provider stack.
- **Fix:** Use Haversine via `Geolocator.distanceBetween` everywhere.

### M-M7. `_currentOrderId` lives only in widget state — lost if Android reaps the screen
- **File:** `mobile/lib/screens/payment/payment_screen.dart:34,111,156`
- **Fix:** Persist in SharedPreferences for the payment-in-flight window. Add backend `/payment/lookup-by-razorpay-order` as recovery path.

### M-M8. `OrderModel.fromJson` parses dates without try/catch
- **File:** `mobile/lib/models/order_model.dart:139-147,173-176`
- **Fix:** Wrap `DateTime.parse` in try/catch; fall back to `DateTime.now()` or null.

### M-M9. `OrderModel.fromJson` casts `items` as non-null List
- **File:** `mobile/lib/models/order_model.dart:174-176`
- **Fix:** `(json['items'] as List<dynamic>? ?? [])`.

### M-M10. Query strings concatenated raw without `Uri.encodeQueryComponent`
- **File:** `mobile/lib/providers/product_provider.dart:96-101,151-157`, `mobile/lib/providers/order_provider.dart:66-71`
- **Fix:** Encode query components consistently.

### M-M11. Order time display inconsistent across screens; only delivery dashboard uses IST
- **File:** `mobile/lib/utils/date_utils.dart`, cart/order list/admin screens
- **Fix:** Standardize on `formatISTShort` (`Asia/Kolkata`) app-wide.

### M-M12. `_handleResponse` silently drops 401 body on JSON parse failure
- **File:** `mobile/lib/services/api_service.dart:243-251`
- **Fix:** Log raw body in `kDebugMode` when 401 decode fails.

## LOW — Mobile

- **M-L1.** Dependency hygiene — `flutter_lints` 2 majors behind, `intl 0.18` behind 0.20. Run `flutter pub outdated`.
- **M-L2.** 130-line `MyApp.build()` with inline providers — extract to `appProviders()`.
- **M-L3.** `devOTP = '1234'` hardcoded in production config file (currently unused).
- **M-L4.** Hardcoded store coordinates `(31.1250, 76.4351)` in app_config — should come from backend.
- **M-L5.** `OrderModel.status` not defaulted on null; unknown values display raw.
- **M-L6.** Commented dev URLs in `app_config.dart` invite wrong-env shipping. Use `--dart-define`.
- **M-L7.** Login screen `CustomPaint` animates background at 60fps — janky on low-end devices.
- **M-L8.** `auth_service.refreshToken` blindly casts `response['user']` without null check.
- **M-L9.** Local notification payload pushed straight to GoRouter — validate against an allowlist of safe routes.
- **M-L10.** `_AdminActionBanner._isLoading` is dead code (banner is removed before await).

---

# Methodology

- Backend reviewer read: every file in `src/middleware/`, `src/entities/`, `src/routes/`, `src/controllers/`, key services (payment, payments-v2, payments-reconciler, razorpay, twilio, fcm, s3, delivery-state, delivery-otp, rider-wallet, order-inventory, order-auto-cancel), `src/index.ts`, `src/config/database.ts`, `package.json`, `ecosystem.config.js`.
- Mobile reviewer read: `pubspec.yaml`, `lib/main.dart`, `lib/config/app_config.dart`, `lib/routes/app_router.dart`, `lib/core/startup_deep_link.dart`, all of `lib/services/` and `lib/providers/`, key models, key screens (login, cart, payment, payment_status, admin_orders, delivery_dashboard, delivery_cod_collect, address screens), `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`.

False-positive discipline: every issue lists a verified file:line reference and a concrete exploitation/impact path. Nitpicks and style-only items were excluded.
