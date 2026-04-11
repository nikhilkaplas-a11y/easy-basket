# Part J — Application Load Balancer & DNS (production) — **ap-south-1** end to end

This guide walks you from a **running Mumbai EC2** (Node on **port 3000**) to **HTTPS** on **`https://api.easybasket.in`** using an **ALB** + **ACM** + **Route 53**.

**Parallel Mumbai test hostname (no clash with live `api`):** use **`api-v2.easybasket.in`** → same ALB/TG steps, separate DNS + ACM name — see **[AWS_API_V2_MUMBAI_CUT_OVER.md](./AWS_API_V2_MUMBAI_CUT_OVER.md)**.  
**GoDaddy-specific DNS steps + testing:** **[GODADDY_DNS_API_V2_E2E.md](./GODADDY_DNS_API_V2_E2E.md)**.

**Assumptions:**

- Region: **Asia Pacific (Mumbai) `ap-south-1`**
- API hostname: **`api.easybasket.in`** (adjust if yours differs)
- App listens on EC2: **`http://127.0.0.1:3000`** (PM2 / Express)
- Health check path (already in your backend): **`GET /api/health`**

---

## J0 — Prerequisites (must work before ALB)

1. **EC2 in Mumbai** is running; on the instance:

   ```bash
   curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/api/health
   ```

   You want **`200`** (or whatever your health route returns).

2. **Route 53 hosted zone** for **`easybasket.in`** exists in the **same AWS account** (easiest for ACM DNS validation). If DNS is only at **GoDaddy / Cloudflare**, you can still validate ACM by **adding the CNAME records they show you** at that provider.

3. **Two public subnets** in **different Availability Zones** in Mumbai (ALB requires subnets in **≥2 AZs**).  
   **VPC** → **Subnets** → filter `ap-south-1` → pick two subnets that have **route to an Internet Gateway** (public subnets).

---

## J1 — Request an ACM certificate (HTTPS) in Mumbai

Certificates for ALB must live in the **same region as the ALB** → **ap-south-1**.

1. AWS Console → region **Mumbai** → **Certificate Manager (ACM)**.
2. **Request** → **Request a public certificate** → Next.
3. **Domain names:**
   - Add **`api.easybasket.in`**
   - (Optional) Add **`* .easybasket.in`** if you use wildcards elsewhere.
4. **Validation:** **DNS validation** (recommended).
5. **Request** → open the new certificate → status **Pending validation**.

### DNS validation records

1. ACM shows **CNAME** name + value for `api.easybasket.in`.
2. **If using Route 53:** click **Create records in Route 53** (fastest).  
   **If using external DNS:** create the **same** CNAME at your registrar/DNS host.
3. Wait until certificate status is **Issued** (often **a few minutes** after DNS propagates).

---

## J2 — Security groups (do this before or right after ALB)

You need **two** security groups in **ap-south-1**:

### J2a — Security group for the **ALB** (new)

**EC2** → **Security Groups** → **Create security group**

| Setting | Value |
|---------|--------|
| Name | `easy-basket-alb-mumbai` |
| VPC | Same VPC as your EC2 |

**Inbound rules:**

| Type | Port | Source |
|------|------|--------|
| HTTPS | 443 | `0.0.0.0/0` |
| HTTP | 80 | `0.0.0.0/0` *(optional; useful for HTTP→HTTPS redirect)* |

**Outbound:** default (all traffic) is fine.

### J2b — Security group for **EC2** (update existing)

**Stop** exposing the app port to the whole internet once ALB is in front.

1. Open the security group attached to your **Mumbai EC2**.
2. **Remove** inbound rules that allow port **3000** (or **80/443**) from **`0.0.0.0/0`** if you added them for testing.
3. **Add** inbound rule:

| Type | Port | Source |
|------|------|--------|
| Custom TCP | **3000** | **Security group** → select **`easy-basket-alb-mumbai`** (the ALB SG above) |

4. Keep **SSH (22)** from **My IP** only (not `0.0.0.0/0`).

**Result:** Only the load balancer can reach Node on **3000**; users hit **443** on the ALB only.

---

## J3 — Create a **target group**

**EC2** → **Target Groups** → **Create target group**

| Field | Suggested value |
|-------|-----------------|
| Target type | **Instances** |
| Name | `easy-basket-api-tg-mumbai` |
| Protocol : Port | **HTTP** : **3000** *(ALB talks HTTP to your instance on 3000)* |
| VPC | Same as EC2 |
| Protocol version | HTTP1 |
| Health checks | **HTTP** |
| Health check path | **`/api/health`** |
| Healthy threshold | 2–5 (default OK) |
| Unhealthy threshold | 2–3 |
| Timeout / Interval | defaults OK |

**Register targets:** add your **Mumbai EC2 instance** → port **3000** → **Include as pending below** → **Create target group**.

Wait until the target becomes **healthy** (green). If it stays **unhealthy**:

- SG: EC2 must allow **3000** from **ALB SG** (J2b).
- App must respond on **`/api/health`** on **3000** from the ALB subnet (test from instance: `curl http://127.0.0.1:3000/api/health`).

---

## J4 — Create the **Application Load Balancer**

**EC2** → **Load Balancers** → **Create Load Balancer** → **Application Load Balancer**

| Field | Value |
|-------|--------|
| Name | `easy-basket-alb-mumbai` |
| Scheme | **Internet-facing** |
| IP address type | **IPv4** |
| VPC | Same as EC2 |
| Mappings | Enable **at least 2 AZs**; select **two public subnets** (different AZs). |
| Security groups | **`easy-basket-alb-mumbai`** (J2a) |

### Listeners and routing

**Listener 1 — HTTPS (443)**

- **Protocol:** HTTPS  
- **Port:** 443  
- **Default action:** **Forward to** → **`easy-basket-api-tg-mumbai`**  
- **Security policy:** ELBSecurityPolicy-TLS-1-2-2017-01 (or current default)  
- **Default SSL certificate:** **From ACM** → select the **Issued** certificate for `api.easybasket.in`

**Listener 2 — HTTP (80) — optional but recommended**

Choose one:

- **Redirect to HTTPS** (443) — best for production, or  
- **Forward to** same target group (less ideal; users may stay on HTTP).

Example **redirect** (Console: add listener HTTP:80 → Action **Redirect** → HTTPS:443, status 301).

Click **Create load balancer**. Wait until **State** = **active**.

---

## J5 — Route 53 — point **`api.easybasket.in`** to the ALB

1. **Route 53** → **Hosted zones** → **`easybasket.in`**.
2. Find record **`api.easybasket.in`** (or **Create record**).

**Create / edit record:**

| Field | Value |
|-------|--------|
| Record name | `api` |
| Record type | **A** |
| **Alias** | **Yes** |
| Route traffic to | **Alias to Application and Classic Load Balancer** |
| Region | **ap-south-1** |
| Load balancer | Select **`easy-basket-alb-mumbai`** |

Save. **TTL** on alias records is managed by Route 53 (no need to set 300 for alias).

**If DNS is not in Route 53:** create a **CNAME** from `api.easybasket.in` to the ALB DNS name shown on the load balancer page (e.g. `easy-basket-alb-mumbai-123456789.ap-south-1.elb.amazonaws.com`). Note: **CNAME at apex** is limited; use **A/ALIAS** at providers that support ALIAS (Cloudflare orange cloud, etc.).

---

## J6 — Lower TTL **before** cutover (only if using **non-alias** old records)

If you previously used a **plain A record** to an IP (not alias), lower TTL to **300** a day before. **Alias to ALB** in Route 53 usually switches quickly.

---

## J7 — Verify end to end

From your **laptop**:

```bash
curl -sS -o /dev/null -w "HTTP %{http_code}\n" https://api.easybasket.in/api/health
```

Expect **200** (or your app’s health status).

```bash
curl -sS -I https://api.easybasket.in/api/health
```

Check **TLS** and **Server** headers. Open in browser: `https://api.easybasket.in/api/health`.

**Mobile app:** if `apiBaseUrl` is already `https://api.easybasket.in/api`, **no app update** is required after DNS points to Mumbai ALB.

---

## J8 — Checklist

- [ ] ACM certificate **Issued** in **ap-south-1**
- [ ] Target group: port **3000**, health **`/api/health`**, instance **healthy**
- [ ] ALB: **HTTPS 443** → target group, correct **ACM** cert
- [ ] ALB SG: **443** (and **80** if used) from internet
- [ ] EC2 SG: **3000** only from **ALB SG**; SSH from **My IP**
- [ ] Route 53 **A (alias)** `api` → Mumbai ALB
- [ ] `curl https://api.easybasket.in/api/health` works

---

## Troubleshooting

| Symptom | What to check |
|--------|----------------|
| **502 Bad Gateway** | Target **unhealthy** or app not listening on **3000**; check target group **Health** tab. |
| **504** | Security group blocking ALB → EC2 on **3000**; wrong port in target group. |
| **Certificate error** | Wrong cert on listener; cert not **Issued**; wrong domain on cert. |
| **DNS not updating** | Old TTL; wrong record; typo in hostname. |
| **Health check failing** | Path must be **`/api/health`**; app must return **200**; check **Advanced health** settings (success codes). |

---

## Related docs

- **[AWS_EC2_AP_SOUTH_1_MIGRATION_GUIDE.md](./AWS_EC2_AP_SOUTH_1_MIGRATION_GUIDE.md)** — EC2 + AMI + key pair  
- **[AWS_AP_SOUTH_1_FULL_STACK_MIGRATION.md](./AWS_AP_SOUTH_1_FULL_STACK_MIGRATION.md)** — full stack overview  
- **[HIGH_AVAILABILITY_SETUP.md](./HIGH_AVAILABILITY_SETUP.md)** — nginx + ALB patterns (if you terminate TLS on nginx instead)

---

## Summary

1. **ACM** in **Mumbai** for `api.easybasket.in` → **DNS validate**.  
2. **Target group** → instances on **:3000**, health **`/api/health`**.  
3. **ALB** → **HTTPS 443** → that group + ACM cert; **HTTP 80** → redirect to HTTPS.  
4. **Security groups** → ALB open to world on **443**; EC2 **3000** only from **ALB**.  
5. **Route 53** → **A (alias)** `api` → ALB.  
6. **Test** with `curl` and your mobile app.
