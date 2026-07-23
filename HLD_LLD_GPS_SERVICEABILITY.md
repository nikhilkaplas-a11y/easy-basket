# GPS Radius-Based Serviceability — Design (HLD + LLD)

**Date:** 2026-07-22
**Status:** Design only — not implemented. Awaiting go-ahead.
**Context:** Single data store. Replace pincode-based serviceability with a GPS-distance check: an address is deliverable if it lies within a configured radius (ENV) of the store's coordinates.

---

## Current state (for reference)

| Layer | How it works today | Precision |
|---|---|---|
| Address selection (which saved address) | GPS/coordinate-based — `ProximityProvider` uses Haversine distance from GPS to each saved address ([proximity_provider.dart](mobile/lib/providers/proximity_provider.dart)) | High (meters) |
| **Serviceability** (can we deliver here?) | **Pincode string match** — `GET /api/service-area/check?pincode=X` against a `ServiceArea` table; entity stores only pincode/city/state, **no coordinates** ([serviceArea.controller.ts](backend/src/controllers/serviceArea.controller.ts), [ServiceArea.ts](backend/src/entities/ServiceArea.ts)) | Low (km-scale) |

Today the app captures precise GPS, reverse-geocodes it to a pincode, then checks the coarse pincode — discarding precision at the one decision that needs it. Addresses already store `lat/lng`, and the client already computes Haversine, so the codebase is well-positioned for this change.

> **Note to reconcile:** current hardcoded store is `31.1250, 76.4351` (Punjab) while service checks in logs use pincode `243003` (Bareilly, UP) — a store-vs-pincode mismatch that the coordinate model removes.

---

# HLD (High-Level Design)

## Goal
Replace "is this **pincode** in our list?" with "is this **GPS point within R km** of our one store?", where `R` is an ENV config.

## Core rule
```
serviceable(point) = haversine_distance(STORE, point) <= DELIVERY_RADIUS_KM
```

## Components & data flow
```
┌──────────────────────────┐        ┌───────────────────────────────┐
│  MOBILE (Flutter)         │        │  BACKEND (Node/Express)        │
│                           │        │                                │
│  1. Get GPS (lat,lng)     │  lat,  │  Serviceability service:       │
│     via LocationProvider  │  lng   │   - reads STORE_LAT/LNG,        │
│  2. Ask backend           │ ─────► │     DELIVERY_RADIUS_KM (env)    │
│     "serviceable?"        │        │   - Haversine(store, point)     │
│  3. Show banner / block   │ ◄───── │   - returns {available,distance}│
│     checkout accordingly  │ result │                                │
│  4. Fallback: map-pin     │        │  Order create:                 │
│     if GPS denied         │        │   - RE-VALIDATES address coords │
└──────────────────────────┘        │     are within radius (enforce) │
                                     └───────────────────────────────┘
```

## Two enforcement points
1. **Browse/home (UX, advisory):** app checks current GPS → shows "We deliver here ✅" / "Not serviceable ❌".
2. **Order creation (security, authoritative):** backend independently re-checks the **delivery address coordinates** are within radius before accepting the order. Never trust the client — a spoofed client could otherwise place an out-of-zone order.

## Source of truth
The **backend** owns the radius + store location and makes the decision. The app sends coordinates and receives yes/no, so the radius lives in exactly one place (backend ENV) — never duplicated/desynced. Serviceability no longer needs reverse-geocoding (raw lat/lng is sent); reverse geocoding remains only for *displaying* the area name.

---

# LLD (Low-Level Design)

## 1. Configuration (ENV)
```
STORE_LAT=31.1250
STORE_LNG=76.4351
DELIVERY_RADIUS_KM=7
DELIVERY_RADIUS_BUFFER_KM=0.2     # optional; absorbs GPS jitter at the edge
```
- Validate at **boot**: missing `STORE_LAT/LNG` or non-positive `DELIVERY_RADIUS_KM` → clear error (refuse start or fall back to pincode). Prevents a silent "serves nowhere / everywhere."
- Change radius = edit ENV + restart. (Upgrade path in §9.)

## 2. Distance function (Haversine)
Single store → point-to-point, no spatial index needed.
```
function haversineKm(lat1, lng1, lat2, lng2):
    R = 6371  # earth radius km
    dLat = radians(lat2 - lat1)
    dLng = radians(lng2 - lng1)
    a = sin(dLat/2)^2 + cos(radians(lat1))*cos(radians(lat2))*sin(dLng/2)^2
    return R * 2 * atan2(sqrt(a), sqrt(1-a))

function isServiceable(lat, lng):
    d = haversineKm(STORE_LAT, STORE_LNG, lat, lng)
    return { available: d <= (RADIUS + BUFFER), distanceKm: d }
```
*(Alternative: MySQL `ST_Distance_Sphere` — unnecessary for one point; JS Haversine is sub-millisecond.)*

## 3. Check endpoint (new / revised)
```
GET /api/service-area/check?lat=<>&lng=<>

200 → { success:true, available:true,  distanceKm:3.4, radiusKm:7 }
200 → { success:true, available:false, distanceKm:12.1, radiusKm:7,
        message:"We don't deliver to your location yet" }
400 → invalid/missing lat,lng
```
- Keep the old `?pincode=` variant as a **fallback** (see §7) so nothing regresses during rollout.
- Validate lat ∈ [-90,90], lng ∈ [-180,180]; reject NaN.

## 4. Order-creation enforcement (the real gate)
In create-order ([order.controller.ts](backend/src/controllers/order.controller.ts)), after loading the delivery `Address`:
```
if address.lat/lng present:
    if not isServiceable(address.lat, address.lng).available:
        return 400 "Delivery address is outside our service area"
else:
    # legacy address with no coords → fallback to pincode check (§7) or reject
```
Serviceability is enforced server-side, independent of what the app displayed.

## 5. Mobile changes (conceptual)
- **`ServiceAreaProvider` / check call:** send `lat,lng` (from `LocationProvider`) instead of `pincode`.
- **Home flow:** interpret `{available}` for the deliver/not-deliver banner (existing logic, different input).
- **Checkout:** block "Place Order" for an out-of-zone selected address (backend also enforces).
- **`app_config` store coords:** no longer needed for the *decision* (backend decides); keep only for display/map centering if used.

## 6. Address coordinates (data dependency)
- **New addresses:** must carry lat/lng → enforce a **map-pin confirm** step when adding an address (`Address` already stores lat/lng).
- **Legacy addresses with null coords:** on selection, either (a) prompt to pin the location, or (b) fall back to pincode check for that address. Recommended: (a) going forward, (b) as safety net.

## 7. Fallback strategy (must-have)
```
1. Live GPS coords        → Haversine check       (primary)
2. GPS denied → map pin   → Haversine check       (user drops a pin)
3. No coords at all       → pincode check (legacy) (last resort)
```
Keep the `ServiceArea` pincode table as a **fallback allow-list** (do not delete) so users who deny location can still be served.

## 8. Caching
- Pincode caching (discrete keys) doesn't apply to continuous coordinates.
- Haversine for one store is trivially cheap → **no cache needed**. (If ever wanted: round coords to ~3 decimals (~111 m grid) as a cache key.)

## 9. Admin / config management
- **Now:** radius + store coords in ENV (simple, single store).
- **Later (recommended):** a `store_config` DB row (`lat, lng, radius_km, is_active`) + small admin screen → change radius without redeploy. ENV-first is fine.

## 10. Edge cases
| Case | Handling |
|---|---|
| GPS jitter at the boundary | `DELIVERY_RADIUS_BUFFER_KM` (e.g. +200 m) |
| GPS permission denied | Map-pin fallback (§7) |
| Address has no lat/lng | Prompt to pin, or pincode fallback |
| Store coords misconfigured | Boot-time validation |
| Radius = 0 / invalid | Guard → default or refuse start |
| Client spoofs "serviceable" | Server re-validates at order create (§4) |

## 11. Rollout (phased, low-risk)
1. **Phase 1** — add coord-based check endpoint + `isServiceable()`; keep pincode endpoint. No user-visible change.
2. **Phase 2** — app home/checkout send coords; pincode kept as no-GPS fallback.
3. **Phase 3** — add server-side enforcement at order creation.
4. **Phase 4 (optional)** — config ENV → DB + admin UI; retire pincode table if unused.

## 12. Testing plan
- **Unit:** Haversine vs known distances; points at radius, radius−ε, radius+ε.
- **Integration:** `/check` with inside/outside/boundary coords; invalid coords → 400.
- **Enforcement:** create-order with out-of-zone address → 400.
- **Fallback:** GPS-denied → pin → serviceable; no-coords address → pincode path.
- **Config:** missing/invalid ENV → boot behavior.

---

## One-line summary
Add a backend `isServiceable(lat,lng) = Haversine(store, point) ≤ radius(ENV)`; call it from the check endpoint (coords instead of pincode) and enforce it at order creation; keep pincode as a no-GPS fallback.

**Effort:** small-to-moderate — addresses already store coordinates and the app already computes Haversine, so the backend gains one small service + an ENV block, and the app swaps `pincode` for `lat,lng` in the check.

## Files this will likely touch (when implemented)
- **Backend:** new `services/serviceability.service.ts` (Haversine + `isServiceable`), `controllers/serviceArea.controller.ts` (coord endpoint), `controllers/order.controller.ts` (enforcement), config/env validation at boot.
- **Mobile:** `providers/service_area_provider.dart` (send coords), home/checkout screens (interpret result + block), address-add flow (map-pin confirm), `config/app_config.dart` (store coords only for display).
- **Config:** `.env` (`STORE_LAT`, `STORE_LNG`, `DELIVERY_RADIUS_KM`, `DELIVERY_RADIUS_BUFFER_KM`).
