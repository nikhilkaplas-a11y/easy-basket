# Multilingual Support (English / Hindi / Punjabi) — Design (HLD + LLD)

**Date:** 2026-08-05
**Status:** Design only — not implemented. Awaiting go-ahead.
**Context:** Add Hindi (हिंदी) and Punjabi (ਪੰਜਾਬੀ) alongside English. Language is an **explicit user choice** in Settings — never auto-detected from the device. On selection the app downloads that language pack from the backend, caches it, re-renders, and returns to the home screen. English ships inside the app as the permanent fallback.

---

## Current state (for reference)

| Item | Today | Implication |
|---|---|---|
| Localization deps | `intl: ^0.18.1` only. **No** `flutter_localizations`, no `generate:` flag, no `l10n.yaml` | Greenfield — nothing to migrate away from |
| UI strings | Hardcoded. ~137 `Text('…')` literals in customer screens (a floor — excludes `hintText`, `labelText`, snackbars, interpolated strings). Realistic total 400–600 | The bulk of the work |
| Screens | 24 customer / 15 admin / 5 delivery | **Admin + delivery stay English** → ~45% scope cut |
| Backend messages | 285 user-facing `message:` strings in `backend/src` | Must move to error codes, not translated prose |
| Font | `GoogleFonts.poppinsTextTheme()` ([theme.dart](mobile/lib/utils/theme.dart)) | Poppins covers Latin + **Devanagari**, **not Gurmukhi** — Punjabi will tofu/fallback |
| Voice search | `localeId: 'hi_IN'` hardcoded ([speech_service.dart:100](mobile/lib/services/speech_service.dart#L100)) | Already Hindi-biased; must follow app locale |
| Error handling | `_handleResponse` throws `Exception(error['message'])` — **discards `code`** ([api_service.dart](mobile/lib/services/api_service.dart)) | Blocks the error-code approach until fixed |
| Persistence | `shared_preferences` already wired in `main.dart` | Reuse for locale + cached pack |
| Routing | `MaterialApp.router` + `AppRouter.router`, inside `MultiProvider` | Locale rebuild hooks in cleanly |

---

# HLD (High-Level Design)

## Goal
Let a user pick English / Hindi / Punjabi in Settings and have the entire customer-facing app render in that language, **without shipping an app update to fix wording**.

## Core principle
```
Keys live in the app (compile-time safe).
Values live in the backend (editable without a release).
English values also live in the app (offline + first-run fallback).
```

## Three layers — do not conflate them

| Layer | Source | Why |
|---|---|---|
| **1. UI strings** (buttons, titles, errors) | Backend `translations` table, cached on device. English bundled as `assets/i18n/en.json` | Bounded set; needs offline + fast startup |
| **2. Backend messages** | Backend returns a stable `code`; the app maps code → layer-1 string | Avoids i18n libraries on Node; app controls wording |
| **3. Catalogue** (product / category / campaign names) | `name_i18n` JSON column on the row itself | Unbounded, grows with stock, changes daily |

Most teams do layer 1 only and ship an app with a fully English product grid. For a grocery app **layer 3 is the most-read text on screen.**

## Components & data flow
```
┌───────────────────────────────┐        ┌──────────────────────────────────┐
│  MOBILE (Flutter)              │        │  BACKEND (Node/Express + MySQL)   │
│                                │        │                                   │
│  Settings → Language           │        │  translations table                │
│   ├ English  (bundled)         │ GET    │   (locale, key, value)             │
│   ├ हिंदी     ──────────────── │ ─────► │  GET /api/i18n/:locale?v=<appVer>  │
│   └ ਪੰਜਾਬੀ                     │ ◄───── │   → { version, strings{k:v} }      │
│                                │  pack  │   (Redis-cached, ETag)             │
│  LocaleProvider                │        │                                   │
│   ├ persist locale (prefs)     │        │  users.locale  ← synced on change  │
│   ├ cache pack   (prefs)       │        │   (used for push notifications)    │
│   └ notifyListeners()          │        │                                   │
│        ↓                       │        │  Catalogue rows carry name_i18n    │
│  MaterialApp rebuilds          │        │   → API returns resolved name      │
│        ↓                       │        │     per Accept-Language            │
│  context.go('/home')           │        │                                   │
└───────────────────────────────┘        └──────────────────────────────────┘
```

## Resolution order (every string, every time)
```
remotePack[key]  ??  bundledEnglish[key]  ??  key   (debug: ⟦key⟧ marker)
```
A missing Punjabi row degrades to English for **that one string** — never a blank widget.

## Source of truth
The **backend** owns translated text. The **app** owns the key list. Neither can drift silently:
the app can't invent a key (constants won't compile), and CI fails if a constant has no backend row.

---

# LLD (Low-Level Design)

## 1. Supported locales
```
en  — English   (bundled, default, permanent fallback)
hi  — हिंदी      (Devanagari)
pa  — ਪੰਜਾਬੀ     (Gurmukhi)
```
Both are **LTR** — no RTL mirroring work anywhere.

## 2. Backend: schema

New table, additive. Follows the existing manual-migration convention (`synchronize: false`), next file is `backend/src/migrations/005_translations.sql`.

```sql
CREATE TABLE translations (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  locale      VARCHAR(5)   NOT NULL,      -- 'hi' | 'pa' | 'en'
  `key`       VARCHAR(160) NOT NULL,      -- 'cart.checkout'
  value       TEXT         NOT NULL,
  updated_by_id INT NULL,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_locale_key (locale, `key`),
  KEY idx_locale (locale)
);
```
- `UNIQUE(locale, key)` makes upserts safe and prevents duplicate rows silently shadowing each other.
- Keys are **never deleted or renamed** — old app versions still request them. Deprecate by leaving the row.

Add a `locale` column to users (for push notifications, §11):
```sql
ALTER TABLE users ADD COLUMN locale VARCHAR(5) NOT NULL DEFAULT 'en';
```

## 3. Backend: endpoints

```
GET  /api/i18n/:locale          PUBLIC   → { version, locale, strings: { key: value } }
GET  /api/admin/i18n/keys       ADMIN    → all keys + per-locale coverage (for CI + admin UI)
PUT  /api/admin/i18n            ADMIN    → upsert { locale, key, value }
```

- **Public** — a guest can switch language before logging in.
- **Redis-cached** per locale (pattern `cache:i18n:<locale>`), invalidated on any admin write. Same pattern as `SERVICE_AREA_CHECK_CACHE_PREFIX`.
- `version` = `MAX(updated_at)` epoch for that locale. The client sends its cached version; unchanged → `304`, saving the payload.
- Payload is small: ~500 keys ≈ 40–60 KB uncompressed, less over gzip.

## 4. App: keys as constants (this is the safety net)

```dart
// lib/l10n/keys.dart — hand-maintained or generated
abstract class K {
  static const cartCheckout      = 'cart.checkout';
  static const cartStoreClosed   = 'cart.store_closed';
  static const homeNotServiceable= 'home.not_serviceable';
  // …
}
```

Call sites never use raw strings:
```dart
Text(context.t(K.cartCheckout))
```

- Typo a constant name → **build fails**. Typo a raw string → silent blank button in production, in a language nobody on the team reads. This single decision removes the main risk of server-delivered strings.
- **CI check:** fetch `/api/admin/i18n/keys`, diff against `K`. Fail the build if a constant has no `en` row, or a locale is below a coverage threshold. Catches "we forgot the Punjabi row" *before* release.

## 5. App: bundled English baseline
```
assets/i18n/en.json     # declared in pubspec assets:
```
Same key→value shape as the API response, so one lookup path serves both. English never needs a network call.

## 6. App: LocaleProvider

`ChangeNotifier`, registered in the existing `MultiProvider` in `main.dart`.

State:
```
locale          : 'en' | 'hi' | 'pa'     (persisted: prefs 'app_locale')
strings         : Map<String,String>      (remote pack, in memory)
packVersion     : int                     (persisted)
packAppVersion  : String                  (persisted — see §8)
isLoading       : bool
```

Lookup:
```dart
String t(String key) =>
    _strings[key] ?? _bundledEn[key] ?? (kDebugMode ? '⟦$key⟧' : key);
```
Exposed as a `BuildContext` extension (`context.t(...)`) so call sites stay short.

**Storage:** the pack goes in `shared_preferences` as a JSON string. At ~40–60 KB that's acceptable and adds no dependency. If packs grow past a few hundred KB, switch to a file via `path_provider` (**not currently in pubspec**).

## 7. Language-switch flow (the re-render)

```
Settings → Language screen
   │
   ├─ user taps "ਪੰਜਾਬੀ"
   │
   ├─ show inline spinner on that row  (deliberate action → a wait is acceptable)
   │
   ├─ GET /api/i18n/pa
   │     ├─ 200 → save pack + version + appVersion to prefs
   │     ├─ 304 → keep cached pack
   │     └─ FAIL → snackbar "Couldn't switch language. Check your connection."
   │               stay on current locale, DO NOT half-apply
   │
   ├─ (Punjabi only) warm the Gurmukhi font — §9
   │
   ├─ prefs['app_locale'] = 'pa'
   ├─ PATCH users.locale = 'pa'   (fire-and-forget; for push. Failure is non-fatal)
   │
   ├─ notifyListeners()
   │     └─ MaterialApp.router rebuilds → whole tree re-renders in Punjabi
   │
   └─ context.go('/home')
```

**Why the whole tree rebuilds:** wrap `MaterialApp.router` in a `Consumer<LocaleProvider>`. Because it sits inside `MultiProvider` and above the router, one `notifyListeners()` re-renders every screen. No per-screen wiring needed.

**Atomicity rule:** locale is committed *only after* the pack is in hand. A failed download must never leave the app pointing at a locale it has no strings for.

## 8. Cache invalidation — two independent triggers

| Trigger | Check | Action |
|---|---|---|
| Translator edited copy | cached `version` < server `version` | Refetch (server returns 200 vs 304) |
| **App was updated** | cached `packAppVersion` != current app version | **Force refetch** |

The second is the one that's easy to miss: a new app release ships new screens with new keys, but the user's cached Punjabi pack predates them. Without this check those screens fall back to English silently. Store the app version alongside the pack and compare on startup.

Refresh timing: on app start (non-blocking, applied next launch) and on entering the Language screen (blocking, so the user sees current data).

## 9. Fonts — the real binary cost

Poppins has **no Gurmukhi glyphs**. Unstyled Punjabi will fall back to a system font (inconsistent) or render tofu (some Android builds).

| Script | Font | Approx size |
|---|---|---|
| Devanagari (hi) | Poppins already covers it | 0 |
| Gurmukhi (pa) | Noto Sans Gurmukhi | ~100–200 KB |

`google_fonts` **fetches at runtime rather than bundling** — which fits this design exactly: a user who only ever uses English downloads nothing. Resolve the text theme from the active locale:
```
en/hi → GoogleFonts.poppinsTextTheme()
pa    → GoogleFonts.notoSansGurmukhiTextTheme()
```
Warm the font during the switch spinner (§7) so the home screen doesn't flash unstyled text.

> **Decision needed:** runtime-fetch (0 KB APK, needs network on first Punjabi render) vs bundling the font (reliable offline, +~150 KB). Runtime-fetch is consistent with how Poppins already works today.

## 10. Backend messages → error codes

`createOrder` already returns `code: 'STORE_CLOSED'` and `code: 'OUT_OF_SERVICE_AREA'`. Extend that pattern; the app maps code → `K.*`.

**Blocker to clear first:** `_handleResponse` in [api_service.dart](mobile/lib/services/api_service.dart) throws `Exception(error['message'])` and **drops `code` entirely**. It must surface a typed error carrying `code` before any of this works. This is a prerequisite, not a nice-to-have.

Two things resist codes:
- **Admin free text** — store-closed `customMessage`. Not translatable. Mitigation: lean on the `closedReason` enum, whose `defaultHeadline`/`defaultSubtitle` are already client-side strings and localize for free. Treat `customMessage` as a single-language override.
- **Push notification bodies** — see §11.

## 11. Push notifications

Notifications render in the OS tray while the app may be dead, so **the backend must localize them**.

- **Targeted** (order updates): read `users.locale`, look up the translation server-side, send in that language.
- **Broadcast** (store reopen): the current single `all_users` topic can't carry three languages. Split into `all_users_en` / `all_users_hi` / `all_users_pa`; the app subscribes to the one matching its locale and **re-subscribes on language change** (unsubscribe old, subscribe new — same shape as the existing `switchPincodeTopic` logic).
- `StoreStatusController.broadcastReopen()` then sends three messages instead of one.

## 12. Catalogue content (layer 3)

Add a JSON column rather than parallel `name_hi` / `name_pa` columns — adding a 4th language becomes a data change, not a migration. Consistent with `Campaign.targetPincodes` already using `simple-json`.

```sql
ALTER TABLE product  ADD COLUMN name_i18n JSON NULL;
ALTER TABLE category ADD COLUMN name_i18n JSON NULL;
-- {"hi":"आलू","pa":"ਆਲੂ"}
```
Resolution happens **server-side** from `Accept-Language`, so the app receives an already-resolved `name` and needs no per-screen changes. Fallback chain `pa → hi → en`; `name` column remains the English source of truth.

> **This is gated on content, not code.** ~N products × 2 languages is a translation set someone must produce *and maintain on every new SKU*. That is an ops commitment and is usually what stalls this kind of project. Decide before building.

## 13. Voice search

`speech_service.dart` hardcodes `localeId: 'hi_IN'`. Map from the active locale (`en_IN` / `hi_IN` / `pa_IN`).

Separately: a Hindi/Punjabi spoken query will not match English product names in `keyword_extraction_service`. Cross-language search needs translated names indexed or a transliteration layer — **explicitly out of scope for v1**, but worth naming so it isn't discovered as a surprise.

## 14. Layout risks

Devanagari and Gurmukhi need more vertical room (matras above and below the baseline), and translations typically run 15–30% longer than English. The codebase uses many fixed heights (`height: 48`, `height: 50`) and `TextOverflow.ellipsis`.

Expect real visual QA, not just string swaps. Mitigations: audit fixed-height buttons for clipping, prefer `minHeight` constraints, and test the longest expected string per screen.

## 15. Edge cases

| Case | Behaviour |
|---|---|
| Download fails mid-switch | Stay on current locale, show error. Never half-apply. |
| Key missing in `pa` | Fall back to English for that string only |
| Key missing everywhere | Debug: `⟦key⟧`. Release: render the key (never blank/crash) |
| App updated, cache stale | `packAppVersion` mismatch → force refetch (§8) |
| Guest switches language | Fully supported — endpoint is public; sync to `users.locale` on next login |
| User clears app data | Falls back to bundled English, re-downloads on next switch |
| Two devices, same account | Locale is per-device (prefs). `users.locale` reflects the most recent switch — acceptable for push |
| Admin/delivery screens | Remain English by design |

## 16. Rollout (phased, low-risk)

| Phase | Scope | Ship? |
|---|---|---|
| **0** | `LocaleProvider`, `K` constants, `context.t()`, `en.json`, `_handleResponse` fix, translations table + API | Yes — English only, zero visible change. Everything else depends on this. |
| **1** | Settings → Language screen + switch flow + font handling | Yes — switchable, but most screens still English |
| **2** | Convert customer screens by journey: onboarding/login → home → cart/checkout → orders → profile | Ship each journey |
| **3** | Backend messages → codes | Ship |
| **4** | Push notification localization + per-locale topics | Ship |
| **5** | Catalogue `name_i18n` | Gated on translated content being available |

Phase 0 is deliberately invisible: it lands the plumbing with no user-facing risk, and every later phase is additive.

## 17. Testing plan

1. **Switch** en → hi → pa → en; verify full re-render and landing on home each time.
2. **Offline switch** — airplane mode, tap Punjabi → error shown, locale unchanged, app still usable.
3. **Cold start** in each locale — no flash of English, no blocking spinner.
4. **Stale cache** — bump app version with cached old pack → forced refetch, new screens translated.
5. **Missing key** — delete one `pa` row → that string shows English, everything else stays Punjabi.
6. **Font** — Punjabi renders Gurmukhi correctly on a low-end Android device (tofu check).
7. **Layout** — longest string per screen in all three locales; check fixed-height buttons for clipping.
8. **Push** — reopen broadcast reaches a Punjabi device in Punjabi; verify topic re-subscription after switching.
9. **CI gate** — remove a backend row for a key in `K`; build must fail.

---

## One-line summary
**Keys compiled into the app for safety; values served from the backend for editability; English bundled so it always works offline — with the language applied only after a successful download, then a single `notifyListeners()` re-renders the app and returns the user to home.**

---

## Files this will likely touch (when implemented)

**Backend**
- `src/entities/Translation.ts` *(new)*, `src/config/database.ts`
- `src/migrations/005_translations.sql` *(new)*
- `src/services/translation.service.ts` *(new)* — Redis-cached lookup
- `src/controllers/i18n.controller.ts`, `src/routes/i18n.routes.ts` *(new)*, `src/index.ts`, `src/routes/admin.routes.ts`
- `src/entities/User.ts` (+`locale`), `src/controllers/storeStatus.controller.ts` (per-locale broadcast)
- `src/services/fcm.service.ts` (localized bodies)

**Mobile**
- `lib/l10n/keys.dart`, `lib/l10n/localization_extension.dart` *(new)*
- `lib/providers/locale_provider.dart` *(new)*
- `assets/i18n/en.json` *(new)* + `pubspec.yaml` assets
- `lib/main.dart` (provider + `Consumer` around `MaterialApp.router`)
- `lib/screens/profile/language_screen.dart` *(new)*, `lib/routes/app_router.dart`
- `lib/services/api_service.dart` (surface `code`)
- `lib/utils/theme.dart` (locale-aware text theme)
- `lib/services/speech_service.dart` (locale-aware STT)
- `lib/services/notification_service_mobile.dart` (per-locale topic switch)
- 24 customer screens — string replacement, phased
