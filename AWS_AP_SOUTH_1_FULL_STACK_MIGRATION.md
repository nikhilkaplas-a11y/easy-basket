# Full stack migration to **ap-south-1 (Mumbai)** — India-only traffic

Use this when you want **all** AWS pieces in India (not a mix of EU + Mumbai). Your app (`api.easybasket.in`) should eventually resolve to a **load balancer in ap-south-1**, with **RDS**, **S3**, and optional **Redis** in the same region.

> **EC2-only step-by-step (key pair, security group, AMI copy, launch, SSH):**  
> **[AWS_EC2_AP_SOUTH_1_MIGRATION_GUIDE.md](./AWS_EC2_AP_SOUTH_1_MIGRATION_GUIDE.md)**

---

## 1. Why one region (Mumbai)?

| Topic | EU API + India users | Everything in **ap-south-1** |
|--------|----------------------|-------------------------------|
| Latency | High (round trip to Europe) | Low for Indian users |
| DB ↔ app | Cross-region if split | Same AZ/region = fast & simple |
| S3 ↔ EC2 | Cross-region charges possible | Same region = cheaper & faster |
| Compliance | Data may leave India paths | Easier to keep data in India |

---

## 2. Inventory (write this down before you start)

- [ ] **EC2**: instance id, type, key pair, **which VPC/subnet**
- [ ] **RDS**: engine (MySQL?), version, **multi-AZ?**, storage
- [ ] **ALB** (if any): listeners, target group, health check path
- [ ] **ACM certificate**: domain (e.g. `api.easybasket.in`) — **must be in the same region as the ALB**
- [ ] **Route 53** (or other DNS): hosted zone for `easybasket.in`
- [ ] **S3**: bucket name(s), public policy, CORS
- [ ] **Redis** (if used): `REDIS_URL` / `REDIS_HOST` — ElastiCache or external
- [ ] **Secrets**: `.env` on server (never commit) — DB, JWT, Twilio, Razorpay, Firebase JSON

Third-party services (**Twilio, Firebase, Razorpay**) are **not** tied to AWS region; keep the same keys.

---

## 3. Recommended order of work

Do **not** delete EU resources until Mumbai is tested.

### Phase A — Network in Mumbai

1. AWS Console → region **Asia Pacific (Mumbai) ap-south-1**.
2. Use **default VPC** for a simple setup, or create a VPC with **public subnets** (ALB + EC2) and **private subnets** (RDS) if you want stricter layout.
3. Create **security groups**:
   - **ALB**: inbound `443` (and `80` if needed) from `0.0.0.0/0`.
   - **EC2 / app**: inbound **only from ALB SG** on app port (e.g. `3000`), not from the open internet if behind ALB.
   - **RDS**: inbound `3306` **only from** app SG (or EC2 SG).

### Phase B — RDS (MySQL) to Mumbai

**Full step-by-step (snapshot copy, restore, security groups, `.env`, troubleshooting):**  
**[AWS_RDS_MYSQL_MIGRATION_AP_SOUTH_1.md](./AWS_RDS_MYSQL_MIGRATION_AP_SOUTH_1.md)**

RDS **cannot** change region in place. You **restore a snapshot** in Mumbai.

1. In **eu-north-1** (or your current region): **RDS → your DB → Snapshots → Take snapshot** (or use latest automated snapshot).
2. **Actions → Copy snapshot** → Target region **ap-south-1** (give it a name).
3. Switch region to **ap-south-1** → **Snapshots** → select the copy → **Restore snapshot**.
4. Pick **VPC / subnets / security group** in Mumbai (SG must allow app → `3306`).
5. After instance is **available**, note the new **endpoint** (e.g. `xxx.xxx.ap-south-1.rds.amazonaws.com`).
6. **Test**: from a bastion or temporary EC2 in Mumbai, `mysql` client to the new endpoint (or use RDS query editor if enabled).

**Data cutover:** For minimal downtime, plan a **maintenance window**: stop writes in EU, final snapshot/sync if needed, restore in Mumbai, point app to new `DB_HOST`, then resume traffic.

### Phase C — S3 to Mumbai

- **Option 1 — New bucket in Mumbai, copy objects** (good for India-only going forward):

  ```bash
  # Example: sync EU bucket → Mumbai bucket (run from CloudShell or a machine with AWS CLI)
  aws s3 sync s3://YOUR-EU-BUCKET s3://YOUR-MUMBAI-BUCKET --region ap-south-1
  ```

  Then recreate **bucket policy** and **CORS** on the Mumbai bucket like the old one.

- **Option 2 — Only new uploads in Mumbai** (old image URLs still point to EU until you re-upload or run a DB migration to replace URLs).

Set on the **Mumbai** server `.env`:

```env
AWS_REGION=ap-south-1
AWS_S3_BUCKET_NAME=your-mumbai-bucket-name
```

### Phase D — Redis (only if you use it)

Create **ElastiCache Redis** (or **MemoryDB**) in **ap-south-1** in the same VPC as the app, or use a managed Redis URL that is **hosted in India**. Update:

```env
REDIS_URL=...
# or REDIS_HOST / REDIS_PORT / REDIS_PASSWORD
```

### Phase E — App servers (EC2) in Mumbai

You can either **clone the EU server as an AMI** (fastest — nginx, PM2, app folder, and configs come along) or **build a fresh box** and reinstall everything.

#### Option A — **Same as EU: copy the instance (AMI)** — recommended if you don’t want to redo nginx

An **AMI** is a snapshot of the **root disk**. Whatever is on disk in EU (nginx, certbot files, `/etc/nginx`, your `backend` folder, PM2, Node, etc.) is **copied** to Mumbai. You do **not** rewrite all nginx config from scratch unless you want to clean up.

**Steps:**

1. In **EC2 (EU region)** → select your instance → **Actions → Images and templates → Create image**.
2. Wait until AMI status is **available**.
3. **Actions (on the AMI) → Copy AMI** → Destination region **ap-south-1** → Copy.
4. Switch console to **ap-south-1** → **EC2 → AMIs** → select the copied AMI → **Launch instance from AMI**.
5. Pick **instance type** (same as EU, e.g. **t3.small**), **VPC/subnet** in Mumbai, **security group** (allow SSH from your IP; app port from ALB SG later).
6. **Key pair**: use an existing Mumbai key or create one (you can’t use the EU `.pem` file name unless you imported the same material — simplest is **create new key pair** in Mumbai and use it, or use **Session Manager** if SSM agent was on the AMI).

**After the new instance boots in Mumbai:**

| Item | Why |
|------|-----|
| **`.env`** | Update `DB_HOST`, `AWS_*`, `REDIS_*` to **Mumbai** resources (RDS/S3/Redis endpoints changed). |
| **Nothing on disk for nginx** | If configs only use **hostname** (`api.easybasket.in`) and your app listens on **127.0.0.1:3000**, nginx often works as-is after DNS points to the new ALB. |
| **SSL on the instance** | If nginx used **Let’s Encrypt** on the **EC2 directly**, cert paths may still work after DNS cutover, or re-run `certbot` for the same domain once DNS hits Mumbai. If TLS is **only on ALB + ACM**, nginx might only do HTTP behind ALB — then only ALB needs the cert in Mumbai. |
| **Elastic IP** | Old EU public IP does **not** move; allocate a **new Elastic IP** in Mumbai if you need a stable IP (often you use **ALB DNS** instead). |
| **IAM instance role** | If the EU instance had an **IAM role**, attach the **same policies** to a role in Mumbai and attach to the new instance. |
| **Cron / systemd** | Copied with AMI — verify paths still valid. |

**Limits:** AMI copy can take **tens of minutes**; **larger disks** cost time. **Instance store** (if any) is not in standard EBS AMIs the same way — most t3 use EBS only.

#### Option B — **Fresh EC2** (empty Ubuntu)

You **do** reinstall: Node, PM2, nginx, clone repo, `npm ci`, `npm run build`, copy **`.env`**, restore nginx site files from backup/git. Use this if you want a **clean** server or your EU server is messy.

---

**Either option, then:**

1. Fix **`.env`** for Mumbai (DB, S3, Redis).
2. **`pm2 restart all`** (or `npm run build` if you pulled new code).
3. Health-check: `curl http://localhost:3000` on the instance.
4. Point **ALB** target group to this instance; then **DNS** to ALB.

### Phase F — ALB + TLS in Mumbai (for `https://api.easybasket.in`)

**Full step-by-step (ACM, target group, ALB listeners, security groups, Route 53, verification):**

**[AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md](./AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md)**

Short version:

1. **ACM** (in **ap-south-1**): request certificate for `api.easybasket.in` (DNS validation in Route 53).
2. Create **Application Load Balancer** in **ap-south-1**, listeners **443** → target group → Mumbai EC2 (port your app uses).
3. **Security groups**: ALB allows internet `443`; EC2 allows **only** ALB SG on app port.

### Phase G — DNS cutover (Route 53 or your DNS provider)

Covered in detail in **AWS_ALB_DNS_AP_SOUTH_1_PRODUCTION.md** (section J5).

1. Lower **TTL** on `api.easybasket.in` to **300** seconds **before** cutover (wait for old TTL to expire) — mainly if not using Route 53 **alias**.
2. Point **A (alias)** to the **Mumbai ALB** in Route 53.
3. Test: `curl -I https://api.easybasket.in/api/health`

### Phase H — Mobile app

If the **domain is unchanged** (`https://api.easybasket.in/api`), **no** `app_config.dart` change is needed. If you introduce a **new hostname**, update `apiBaseUrl` and release a new app build.

### Phase I — Decommission EU (after 24–48h stable)

- Stop or terminate **EU EC2** (after AMI/snapshot if you want backup).
- **Delete** EU RDS only after a **final snapshot** stored in a safe place.
- Remove unused **EU ALB**, **EIPs**, old **S3** bucket (only after data copied and verified).

---

## 4. `.env` checklist (Mumbai production)

| Variable | Note |
|----------|------|
| `DB_HOST` | Mumbai RDS endpoint |
| `DB_PORT` | Usually `3306` |
| `AWS_REGION` | `ap-south-1` |
| `AWS_S3_BUCKET_NAME` | Mumbai bucket |
| `REDIS_URL` / `REDIS_*` | Mumbai if applicable |
| `JWT_SECRET`, `TWILIO_*`, `RAZORPAY_*`, `FIREBASE_*` | Copy from EU; values unchanged |

---

## 5. Rollback (if something breaks)

- Point DNS back to the **old EU ALB** (keep EU stack running until Mumbai is proven).
- Or restore `.env` on EU server and repoint Route 53.

---

## 6. Related docs in this repo

- `AWS_REGION_MIGRATION_GUIDE.md` — S3-focused steps and `.env` notes (partial migration).
- `CREATE_S3_BUCKET_MUMBAI.md` — S3 in Mumbai.
- `backend/EC2_INSTANCE_UPGRADE.md` — instance sizing on small VMs.

---

## 7. Summary

1. **Snapshot RDS** → copy to **ap-south-1** → **restore**.  
2. **S3 sync** or new bucket in **ap-south-1**.  
3. **New EC2 + ALB + ACM** in **ap-south-1**.  
4. Update **`.env`**, deploy **backend**, test.  
5. **Route 53** → Mumbai ALB.  
6. Turn off **EU** after you’re happy.

This gives you a **single-region, India-oriented** stack in **ap-south-1** with no dependency on EU for day-to-day traffic.
