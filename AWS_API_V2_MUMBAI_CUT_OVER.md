# **`api-v2.easybasket.in`** — Mumbai test host (no clash with production)

Use this pattern while **`api.easybasket.in`** still points at your **old** stack (e.g. EU). You build everything in **Mumbai** behind **`api-v2`**, validate, then **switch** production when ready.

**GoDaddy DNS + ACM validation + ALB + how to test (end-to-end):**  
**[GODADDY_DNS_API_V2_E2E.md](./GODADDY_DNS_API_V2_E2E.md)**

---

## Why this works

| Hostname | Points to | Purpose |
|----------|-----------|---------|
| **`api.easybasket.in`** | Old ALB / EU (unchanged) | Current users — **do not touch** until Mumbai is verified |
| **`api-v2.easybasket.in`** | **Mumbai** ALB | Your test URL for the new region |

No conflict: different **DNS names** → different targets.

---

## 1. DNS: create **`api-v2`** in Route 53

1. **Route 53** → Hosted zone **`easybasket.in`** → **Create record**.
2. **Record name:** `api-v2`
3. **Record type:** **A**
4. **Alias:** **Yes**
5. **Route traffic to:** **Application Load Balancer** → **ap-south-1** → select your **Mumbai** load balancer (the one in front of Mumbai EC2).

Save. Do **not** change the existing **`api`** record yet.

**If DNS is outside Route 53:** add a **CNAME** `api-v2.easybasket.in` → your ALB DNS name (e.g. `xxx.ap-south-1.elb.amazonaws.com`), or use **ALIAS** if your provider supports it.

---

## 2. ACM certificate (Mumbai)

In **Certificate Manager** (region **ap-south-1**):

**Option A — Cert only for v2 (simplest for first go)**  
- Request a public certificate for **`api-v2.easybasket.in`** only.  
- DNS-validate (add CNAME in Route 53 or click **Create records**).

**Option B — One cert for both (ready for later cutover)**  
- Request certificate with **two** names:  
  - `api.easybasket.in`  
  - `api-v2.easybasket.in`  
- Validate both. Attach this single cert to the **Mumbai** ALB **HTTPS listener** so when you later point **`api`** to this ALB, you don’t need a new cert.

Attach the **Issued** certificate to the Mumbai ALB listener **443**.

---

## 3. ALB listener behavior

- **Default action:** forward to your **Mumbai** target group (Node on **:3000**), same as in [AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md](./AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md).
- You usually **do not** need a separate listener per hostname: one **HTTPS:443** listener with a cert that includes **`api-v2.easybasket.in`** is enough for testing.
- If you use **host-based rules** later (different services), add rules then; for one backend, default forward is fine.

---

## 4. Security groups

Same as the main ALB guide:

- **ALB SG:** inbound **443** (and **80** if you redirect).
- **EC2 SG:** app port (**3000**) from **ALB SG** only.

---

## 5. Test from your laptop

```bash
curl -sS -o /dev/null -w "HTTP %{http_code}\n" https://api-v2.easybasket.in/api/health
```

Expect **200**. Then run a few real flows (login, list products) against **`https://api-v2.easybasket.in/api`**.

---

## 6. Point the **mobile app** at v2 (test builds only)

In **`mobile/lib/config/app_config.dart`**, temporarily use:

```dart
static const String apiBaseUrl = 'https://api-v2.easybasket.in/api';
```

Ship **internal / TestFlight** builds with this; keep **Play Store** on **`api.easybasket.in`** until cutover.

Or use **`--dart-define=API_BASE_URL=...`** in CI for a “staging” flavor (optional).

---

## 7. When Mumbai is good — cut over production (“downgrade” old stack)

1. **Lower TTL** on **`api`** if it’s not already an alias (optional; alias flips fast).
2. **Route 53:** change **`api`** **A (alias)** to the **same Mumbai ALB** as **`api-v2`** (or keep one ALB, two names).
3. Ensure **ACM** on that ALB includes **`api.easybasket.in`** (Option B above, or add name + revalidate).
4. **Verify:** `curl https://api.easybasket.in/api/health`
5. **Monitor** errors/latency 24–48h.
6. **Decommission old EU** EC2/ALB (after snapshot/backup). That’s the real “downgrade” of the old path.
7. **`api-v2`:** keep as staging, or **delete** the DNS record later to avoid confusion.

---

## 8. Summary

| Step | Action |
|------|--------|
| 1 | Mumbai stack up (EC2, ALB, TG) — see ALB guide |
| 2 | ACM for **`api-v2.easybasket.in`** (or SAN with `api`) |
| 3 | Route 53 **`api-v2`** → Mumbai ALB |
| 4 | Test HTTPS + app on **api-v2** |
| 5 | Flip **`api`** → Mumbai when ready |
| 6 | Turn off old region |

This avoids clashing with live traffic on **`api.easybasket.in`** until you’re ready.
