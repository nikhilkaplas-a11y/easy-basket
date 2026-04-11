# End-to-end: **`api-v2.easybasket.in`** with **GoDaddy DNS** + **ACM** + **ALB (Mumbai)**

This guide assumes:

- AWS **region:** `ap-south-1` (Mumbai)
- You want **`https://api-v2.easybasket.in`** for your **new Mumbai** stack
- Your domain **`easybasket.in`** is registered at **GoDaddy** (or you manage DNS there)

---

## A. What you register vs what you add in DNS

| Item | What it is |
|------|----------------|
| **`easybasket.in`** | The **domain** you buy once (e.g. at GoDaddy). You already have this or you buy it at GoDaddy → **Domains** → search → purchase. |
| **`api-v2.easybasket.in`** | A **subdomain**. You do **not** buy it separately. You only add **DNS records** under `easybasket.in`. |

So: **register the root domain** if needed; **api-v2** is just DNS + SSL + your ALB.

---

## B. Where DNS must be edited (important)

DNS records must be created **where your domain’s nameservers point**.

1. In GoDaddy: **My Products** → **easybasket.in** → **DNS** (or **Manage DNS**).
2. Check **Nameservers** at the top:
   - If they are **GoDaddy’s** (e.g. `nsXX.domaincontrol.com`) → add **all** records below **in GoDaddy**.
   - If they point to **Route 53** or **Cloudflare** → add records **there**, not in GoDaddy (same logic, different UI).

The steps below use **GoDaddy** as the editor.

---

## C. Order of work (recommended)

1. **Mumbai EC2** running; app responds on port **3000**; `/api/health` works locally.
2. **ACM** certificate requested for **`api-v2.easybasket.in`** (status: **Pending validation**).
3. **GoDaddy:** add **ACM validation** CNAME (section D).
4. Wait until ACM status is **Issued** (often **5–30 minutes** after DNS propagates).
5. **ALB + target group** in Mumbai; attach this **cert** to HTTPS **443** → target group (see [AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md](./AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md)).
6. **GoDaddy:** add **`api-v2`** → ALB (section E).
7. **Test** (section F).

You can request ACM **before** the ALB exists; you need the cert **Issued** before attaching it to the listener.

---

## D. Step 1 — ACM DNS validation (GoDaddy)

In **AWS Certificate Manager** (region **ap-south-1**), open your certificate for **`api-v2.easybasket.in`**. Under **Domains**, you’ll see something like:

| Field | Example (yours will differ) |
|--------|-------------------------------|
| **CNAME name** | `_de0f9724460a7f84fa02ad96b8619367.api-v2.easybasket.in` |
| **CNAME value** | `_37078bb58e0d6239d8806674e6a98b8e.jkd-validations.aws.` |

### Add this in GoDaddy

1. GoDaddy → **My Products** → **Domains** → **easybasket.in** → **DNS** / **Manage DNS**.
2. **Add** → **CNAME** (or **Add record**).

**Typical GoDaddy mapping:**

| GoDaddy field | What to enter |
|---------------|----------------|
| **Type** | CNAME |
| **Name** / **Host** | Only the **left part** of the CNAME **name**, **without** `easybasket.in` |

For a name like:

`_de0f9724460a7f84fa02ad96b8619367.api-v2.easybasket.in`

the **Host** is usually:

**`_de0f9724460a7f84fa02ad96b8619367.api-v2`**

(If GoDaddy shows the full domain already, you might enter only the underscore prefix part — see their hint text.)

| **Value** / **Points to** | Paste the **CNAME value** from ACM **exactly** (often starts with `_` and ends with `_...aws.`). **Include the trailing dot** only if GoDaddy asks for FQDN; many UIs omit it — try **without** trailing dot if save fails. |

| **TTL** | 1 hour or default |

3. **Save**.

### If GoDaddy rejects a long host name

Some UIs limit length. Options:

- Use **AWS Route 53** only for **DNS** (change nameservers to Route 53) and use **Create records in Route 53** from ACM, or  
- Ask GoDaddy support, or  
- Use **email validation** for ACM if offered (less common for wildcards).

### Wait for ACM to become **Issued**

- Refresh the ACM console every few minutes.
- **Pending validation** → **Issued** = success.

---

## E. Step 2 — Point **`api-v2`** to your **Mumbai ALB**

After your **Application Load Balancer** exists in **ap-south-1** (see [AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md](./AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md)), copy the **ALB DNS name**, e.g.:

`easy-basket-alb-mumbai-1234567890.ap-south-1.elb.amazonaws.com`

### In GoDaddy — second CNAME (traffic to the API)

1. **Add record** → **CNAME**

| Field | Value |
|----------|--------|
| **Name** / **Host** | `api-v2` |
| **Value** / **Points to** | Paste the **ALB DNS name** (no `https://`). |
| **TTL** | 1 hour (or default) |

2. **Save**.

**Do not** remove the **ACM validation** CNAME (section D) until ACM shows **Issued**; after validation, some people delete that record — ACM already issued the cert, so it’s optional to keep.

**Note:** Using **CNAME** for `api-v2` to the ALB hostname is standard when DNS is **not** Route 53 alias. If you later move DNS to Route 53, you can use **A (alias)** to ALB instead.

---

## F. Step 3 — HTTPS on the ALB

1. **ALB** → listener **HTTPS:443** → default action **Forward** to target group (Node **:3000**).
2. **Certificate:** select the **Issued** certificate for **`api-v2.easybasket.in`**.
3. **EC2 security group:** allow port **3000** from **ALB security group** only.

---

## G. How to test (end-to-end)

### 1) DNS propagation

After a few minutes (up to **48h** on rare TTL/cache issues, usually **&lt; 30 min**):

```bash
dig +short api-v2.easybasket.in CNAME
```

You should see something ending in **`elb.amazonaws.com`** (or a chain that resolves to the ALB).

```bash
nslookup api-v2.easybasket.in
```

### 2) TLS + HTTP

```bash
curl -sS -o /dev/null -w "HTTP %{http_code}\n" https://api-v2.easybasket.in/api/health
```

Expect **`200`** (or your app’s health status).

```bash
curl -sS -I https://api-v2.easybasket.in/api/health
```

Check **`HTTP/2 200`** and no certificate errors.

```bash
openssl s_client -connect api-v2.easybasket.in:443 -servername api-v2.easybasket.in </dev/null 2>/dev/null | openssl x509 -noout -subject -dates
```

Confirm the **subject** includes **`api-v2.easybasket.in`**.

### 3) Browser

Open:

`https://api-v2.easybasket.in/api/health`

You should see JSON or a small health payload, and the padlock **valid**.

### 4) Mobile app (test build)

In **`mobile/lib/config/app_config.dart`**, temporarily:

```dart
static const String apiBaseUrl = 'https://api-v2.easybasket.in/api';
```

Build and run; test login, product list, cart. **Revert** to `https://api.easybasket.in/api` for Play Store until you cut over.

### 5) If something fails

| Symptom | Check |
|--------|--------|
| **Certificate invalid** | ACM **Issued**? Correct cert on ALB listener? **SNI** hostname matches. |
| **DNS not found** | GoDaddy CNAME for **api-v2** correct? Nameservers still GoDaddy? |
| **502 / 504** | Target group **healthy**? EC2 SG allows **3000** from ALB SG? |
| **Connection timeout** | ALB **internet-facing**? **Public subnets**? |

---

## H. Registering a **new** domain at GoDaddy (only if you don’t own `easybasket.in` yet)

1. **godaddy.com** → **Domains** → search **`easybasket.in`** (or your chosen name).
2. Add to cart → **checkout** → **register** (1+ years).
3. After purchase, open **DNS** for that domain and follow **sections D–G** above.

---

## I. Related docs

- [AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md](./AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md) — ALB + SG + health checks  
- [AWS_API_V2_MUMBAI_CUT_OVER.md](./AWS_API_V2_MUMBAI_CUT_OVER.md) — cutover strategy and **`api`** when ready  
- [AWS_EC2_AP_SOUTH_1_MIGRATION_GUIDE.md](./AWS_EC2_AP_SOUTH_1_MIGRATION_GUIDE.md) — EC2 in Mumbai  

---

## J. Short checklist

- [ ] Domain **`easybasket.in`** active; DNS managed in **GoDaddy** (or you know where NS point)
- [ ] ACM requested for **`api-v2.easybasket.in`** (Mumbai)
- [ ] **Validation CNAME** added in GoDaddy → ACM **Issued**
- [ ] **ALB** + **target group** + **cert** on **443**
- [ ] **CNAME** `api-v2` → ALB DNS name
- [ ] `curl https://api-v2.easybasket.in/api/health` works
- [ ] Optional: test app with **`api-v2`** base URL
