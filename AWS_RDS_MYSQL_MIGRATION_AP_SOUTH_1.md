# RDS **MySQL** migration to **ap-south-1 (Mumbai)**

Your backend uses **TypeORM + MySQL** (`DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`). This guide moves the **database** from another region (e.g. **eu-north-1**) to **Mumbai** without changing application code—only **`.env`** on the Mumbai server.

---

## 1. What you need in Mumbai before restoring

| Item | Note |
|------|------|
| **VPC** | Same VPC as your Mumbai **EC2**, or a VPC connected (VPC peering / same account). |
| **DB subnet group** | At least **two subnets** in **different Availability Zones** in **ap-south-1** (RDS requirement). Subnets should be **private** (recommended) with route to NAT for outbound patches, or public if that’s how you run RDS today. |
| **Security group** | New SG in **ap-south-1**: inbound **MySQL (3306)** from your **Mumbai EC2 security group** (not `0.0.0.0/0`). |
| **Engine version** | Restored instance must use a **compatible** MySQL major version with your snapshot (same or newer minor, per AWS rules). |

---

## 2. Method A — **Snapshot → copy → restore** (simple, common)

Best when you can accept a **short maintenance window** or a **one-time copy** (staging first).

### Step A1 — Snapshot the **source** RDS (EU)

1. AWS Console → region **source** (e.g. **eu-north-1**) → **RDS** → **Databases** → select your instance.
2. **Actions** → **Take snapshot** → name e.g. `easy-basket-pre-mumbai-YYYYMMDD`.
3. Wait until snapshot status is **Available**.

### Step A2 — Copy snapshot to **ap-south-1**

1. **RDS** → **Snapshots** → select the snapshot.
2. **Actions** → **Copy snapshot**.
3. **Target region:** **Asia Pacific (Mumbai) ap-south-1**.
4. **New DB snapshot identifier:** e.g. `easy-basket-mumbai-copy`.
5. **Copy** → wait until the copy is **Available** in **Mumbai**.

### Step A3 — Restore to a **new** DB instance in Mumbai

1. Switch region to **ap-south-1** → **RDS** → **Snapshots** → select the copied snapshot.
2. **Actions** → **Restore snapshot**.
3. **Settings:**
   - **DB instance identifier:** e.g. `easy-basket-mysql-mumbai`
   - **Instance class:** start with same class as EU or **db.t3.micro** / **db.t3.small** for test (scale later).
   - **Storage:** match or exceed source; **gp3** is fine.
   - **VPC:** your Mumbai VPC.
   - **Subnet group:** your **DB subnet group** (two AZs).
   - **Public access:** **No** (recommended) if app connects from EC2 in same VPC.
   - **VPC security group:** create or choose the SG that allows **3306** from **EC2 app SG**.
4. **Master password:** restoring from snapshot **keeps the same master username/password** as the original instance (you are not prompted for a new password in typical restore flows—confirm in console if AWS asks).
5. **Restore** → wait until status is **Available** (can take **15–60+ minutes**).

### Step A4 — Get the new endpoint

**RDS** → **Databases** → your Mumbai instance → copy **Endpoint** (e.g. `easy-basket-mysql-mysql-mumbai.xxxxx.ap-south-1.rds.amazonaws.com`).

### Step A5 — Update backend **`.env`** (Mumbai EC2)

```env
DB_HOST=<mumbai-rds-endpoint>
DB_PORT=3306
DB_USER=<same as before unless you changed>
DB_PASS=<same as before>
DB_NAME=easy_basket
```

Restart app:

```bash
pm2 restart all
```

### Step A6 — Verify

On Mumbai EC2:

```bash
mysql -h <mumbai-endpoint> -u <user> -p -e "SELECT 1;"
```

Hit your API: `curl https://api-v2.easybasket.in/api/health` (and a real login flow).

---

## 3. Method B — **Cross-region read replica → promote** (less downtime)

Use when the database is **large** and you want to **minimize** the final cutover window.

1. In **source region** → **RDS** → select **primary** DB.
2. **Actions** → **Create read replica** (or **Create Aurora read replica** if Aurora—steps differ).
3. For **MySQL RDS**: set **Region** for the replica to **ap-south-1**, choose subnet group + SG in Mumbai.
4. Wait until replica **status** is **Available** and **Replica lag** is low (seconds).
5. **Stop writes** to the old app (maintenance) or accept a small drift window.
6. In **Mumbai** → select the **read replica** → **Actions** → **Promote read replica** (makes it a **standalone** primary).
7. Update **`DB_HOST`** on Mumbai EC2 to the **new** promoted instance endpoint (verify in console—may change after promote).
8. Point traffic to Mumbai app + DB; **decommission** EU DB when confident (after final snapshot).

**Note:** Exact menu names can vary slightly by engine/version; if **Create read replica** to another region is not shown, use **Method A** (snapshot copy).

---

## 4. Security checklist (Mumbai)

- [ ] RDS **not** publicly accessible unless you truly need it (usually **no**).
- [ ] SG: **3306** only from **EC2** (or ALB if you ever put DB behind proxy—normally **EC2 only**).
- [ ] Same **`DB_USER` / `DB_PASS`** as before, or update **`.env`** if you rotate secrets.
- [ ] **Parameter group** / `time_zone`, `character_set` — match EU if you had custom parameters (optional check).

---

## 5. Cutover strategy (no double-writes)

| Approach | When |
|----------|------|
| **Snapshot restore to Mumbai** | Test **`api-v2`** + Mumbai RDS while EU still serves **`api`**. When happy, move **`api`** DNS to Mumbai and **stop** using EU RDS (after a last snapshot). |
| **Single cutover** | Short maintenance: stop EU app, final snapshot or ensure replica caught up, restore/promote Mumbai, switch **`DB_HOST`** everywhere, start Mumbai app. |

Avoid two apps writing to **two** primaries for the same domain for long—pick one primary after cutover.

---

## 6. After migration

1. **Backup:** enable **automated backups** + **backup retention** on Mumbai RDS.
2. **Monitoring:** CPU, connections, free storage.
3. **EU RDS:** take a **final snapshot**, then **delete** instance when you no longer need rollback (saves cost).

---

## 7. Troubleshooting

| Issue | What to check |
|-------|----------------|
| **Can’t connect** | SG allows **EC2 → RDS:3306**; correct **endpoint**; **private** RDS needs EC2 in **same VPC** or peering. |
| **Access denied** | User grants in MySQL—snapshot restore keeps users; verify user **host** is `%` or EC2 private IP pattern. |
| **Wrong data** | You connected to **old** EU RDS—double-check **`DB_HOST`** in **`.env`** actually loaded by PM2 (`pm2 env 0`). |

---

## 8. Related docs

- **[AWS_AP_SOUTH_1_FULL_STACK_MIGRATION.md](./AWS_AP_SOUTH_1_FULL_STACK_MIGRATION.md)** — full stack order (EC2, S3, etc.)
- **[GODADDY_DNS_API_V2_E2E.md](./GODADDY_DNS_API_V2_E2E.md)** — testing **`api-v2`**

---

## 9. Summary

1. **Snapshot** source RDS → **Copy** to **ap-south-1** → **Restore** new instance in Mumbai (subnet group + SG).  
2. **Endpoint** → **`DB_HOST`** on Mumbai EC2.  
3. **Restart** PM2; test **`api-v2`**.  
4. **Cut over** production when ready; **snapshot and delete** old RDS after validation.

If you tell me your **current RDS engine** (MySQL 8 vs 5.7) and whether you use **Multi-AZ**, the restore screen choices can be narrowed further—this doc stays valid for standard **RDS MySQL**.
