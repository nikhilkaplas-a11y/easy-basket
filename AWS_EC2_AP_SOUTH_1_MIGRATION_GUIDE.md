# EC2 migration to **ap-south-1 (Mumbai)** — full guide (key pair, AMI, launch)

This guide assumes you already have a running EC2 in another region (e.g. **eu-north-1**) and you want a **copy of that server** in **ap-south-1**, including **new key pair**, **security group**, and **launch from AMI**.

**High level:** Create **AMI** in EU → **Copy AMI** to Mumbai → **Create key pair + security group** in Mumbai → **Launch** from AMI → **SSH** → **update `.env`** → **point DNS/ALB**.

---

## Part A — Things you must know

| Topic | Detail |
|--------|--------|
| **Key pairs are per region** | The `.pem` you downloaded in **EU** is **not** listed in **Mumbai**. You either **create a new key pair in ap-south-1** or **import** the same public key. |
| **AMI = disk clone** | Nginx, PM2, your app folder, and most configs on disk **move with the AMI**. You still **change** `.env` for Mumbai RDS/S3. |
| **Public IP** | The EU public IP **does not** move. In Mumbai you get a **new** IP (or use **Elastic IP**). |
| **Time** | AMI create + cross-region copy can take **15–60+ minutes** depending on disk size. |

---

## Part B — Create a key pair in **ap-south-1** (required before launch)

Do this **in Mumbai** so you can SSH into the new instance.

### B1. AWS Console

1. Open **AWS Console** → top-right **region** → select **Asia Pacific (Mumbai) ap-south-1**.
2. Go to **EC2** → left menu **Key Pairs** (under **Network & Security**).
3. **Create key pair**:
   - **Name:** e.g. `easy-basket-mumbai-2025`
   - **Type:** RSA or ED25519 (ED25519 is fine for modern OpenSSH).
   - **Format:** `.pem` (for OpenSSH / macOS / Linux terminal).
4. Click **Create** — your browser downloads **one** `.pem` file. **You cannot download it again.** Store it safely (password manager, secure folder).
5. On your Mac/Linux:

   ```bash
   chmod 400 ~/path/to/easy-basket-mumbai-2025.pem
   ```

### B2. Optional — reuse your **existing** EU key (import)

If you want to **keep using the same private key file** you already have:

1. On your laptop, show the **public** half:

   ```bash
   ssh-keygen -y -f /path/to/your-old-eu-key.pem
   ```

2. **EC2 (Mumbai)** → **Key Pairs** → **Import key pair** → paste that **single line** (starts with `ssh-rsa` or `ssh-ed25519`) → name it e.g. `imported-eu-key`.
3. When launching the instance in Mumbai, select **this** imported key pair.

You do **not** need a new `.pem` if you import — you keep using the **same private key** file for SSH.

---

## Part C — Security group in **ap-south-1**

Your new instance needs a **security group** in **Mumbai** (EU security groups do not appear here).

1. Region **ap-south-1** → **EC2** → **Security Groups** → **Create security group**.
2. **Name:** e.g. `easy-basket-app-mumbai`
3. **VPC:** choose the same VPC where you will place the instance (often **default VPC** for simplicity).
4. **Inbound rules** (adjust to your setup):

   | Type | Port | Source | Note |
   |------|------|--------|------|
   | SSH | 22 | **My IP** | Safer than `0.0.0.0/0` |
   | Custom TCP | 3000 | **ALB security group** (later) or **My IP** for testing | Your Node app |
   | HTTP | 80 | ALB SG or `0.0.0.0/0` | If nginx listens on 80 |
   | HTTPS | 443 | ALB SG or `0.0.0.0/0` | If TLS on instance |

   For **first boot testing**, many people allow **SSH from My IP** and **3000 from My IP**, then **tighten** to ALB-only after the load balancer exists.

5. **Outbound:** default **All traffic** to `0.0.0.0/0` is usually fine (app talks to RDS, S3, internet).

6. **Create** the security group. **Note the SG ID** (e.g. `sg-0abc123`).

---

## Part D — Create an AMI from your **EU** instance

1. Switch region to your **current** one (e.g. **eu-north-1** Stockholm).
2. **EC2** → **Instances** → select your running (or stopped) instance.
3. **Actions** → **Images and templates** → **Create image**:
   - **Image name:** e.g. `easy-basket-eu-before-mumbai-migration`
   - **Description:** optional.
   - **No reboot** (optional): unchecked = AWS reboots for a cleaner snapshot (recommended for production consistency).
4. **Create image**.
5. **EC2** → **AMIs** → wait until status is **available** (green).

---

## Part E — Copy that AMI to **ap-south-1**

1. Still in **EU** region → **EC2** → **AMIs** → select your new AMI.
2. **Actions** → **Copy AMI**:
   - **Destination region:** **Asia Pacific (Mumbai) ap-south-1**
   - **Name:** e.g. `easy-basket-mumbai-from-eu`
3. **Copy AMI**.
4. Switch console region to **ap-south-1** → **EC2** → **AMIs** → wait until the copied AMI is **available**.

---

## Part F — Launch a new EC2 in **Mumbai** from the AMI

1. Region **ap-south-1** → **EC2** → **AMIs** → select the **copied** AMI (owned by you).
2. **Launch instance from AMI**.
3. **Name:** e.g. `easy-basket-api-mumbai`.
4. **Instance type:** same as EU (e.g. **t3.small**) or larger.
5. **Key pair:** select the **Mumbai** key pair you created in **Part B** (or the **imported** key).
6. **Network settings:**
   - **VPC / subnet:** pick a **public subnet** if you need a public IPv4 for SSH (or use **Session Manager** without public IP — only if the AMI had SSM agent + IAM role).
   - **Auto-assign public IP:** **Enable** (for simple SSH from internet), unless you use only private IP + bastion.
   - **Firewall (security groups):** select **existing** → the security group you created in **Part C**.
7. **Storage:** default from AMI is usually fine; increase if EU had larger disk.
8. **Advanced** → **IAM instance profile:** if your EU instance used an **IAM role** for S3, **create the same role in Mumbai** (same policies) and attach here so the app can reach S3 without long-lived keys.
9. **Launch instance**.

---

## Part G — Elastic IP (optional but stable)

Without Elastic IP, **stop/start** can change the public IP.

1. **ap-south-1** → **EC2** → **Elastic IPs** → **Allocate** → **Allocate**.
2. Select the new EIP → **Actions** → **Associate** → your **Mumbai** instance → **Associate**.

Update **DNS** or **ALB target** as needed (often the ALB is in front and you don’t point users at the instance IP).

---

## Part H — Connect with SSH

**User name** depends on AMI (Ubuntu = `ubuntu`, Amazon Linux = `ec2-user`, Debian = `admin` — your copied AMI keeps the **same OS** as EU).

```bash
ssh -i ~/path/to/easy-basket-mumbai-2025.pem ubuntu@<PUBLIC_IP_OR_DNS>
```

If **Permission denied (publickey)**:

- Wrong username for that AMI.
- Wrong `.pem` (must match the **key pair name** selected at launch).
- `chmod 400` on the `.pem`.

---

## Part I — After login — point the app to Mumbai services

1. Edit backend **`.env`** on the server (path is whatever you used in EU, e.g. `~/easy-bucket/backend/.env`):

   ```env
   DB_HOST=<mumbai-rds-endpoint>
   AWS_REGION=ap-south-1
   AWS_S3_BUCKET_NAME=<mumbai-bucket-if-changed>
   # REDIS_* if Redis moved to Mumbai
   ```

2. Restart app:

   ```bash
   cd ~/path/to/backend   # your actual path
   npm run build
   pm2 restart all
   pm2 logs --lines 50
   ```

3. Local test on the box:

   ```bash
   curl -sS http://127.0.0.1:3000/
   ```

4. **Nginx:** if it proxies to Node, usually **no change** unless you hardcoded EU IPs. Reload: `sudo nginx -t && sudo systemctl reload nginx`.

---

## Part J — Load balancer & DNS (production)

1. Create **ALB** + **target group** in **ap-south-1** pointing to this instance (port **3000** or **80** depending on nginx).
2. **ACM certificate** in **ap-south-1** for `api.easybasket.in` → attach to ALB **443**.
3. **Route 53** (or DNS): **A/ALIAS** `api.easybasket.in` → **Mumbai ALB**.
4. After traffic is stable, **stop/terminate EU EC2** (after a final backup AMI in EU if you want rollback).

---

## Checklist (print this)

- [ ] Key pair created **or** public key imported in **ap-south-1**
- [ ] `.pem` chmod `400`; backup stored safely
- [ ] Security group in **Mumbai** (SSH + app ports)
- [ ] AMI created in **EU** and **available**
- [ ] AMI **copied** to **ap-south-1** and **available**
- [ ] Instance **launched** from AMI with correct **key pair** + **SG**
- [ ] **Elastic IP** (optional)
- [ ] **SSH** works
- [ ] **`.env`** updated for Mumbai RDS/S3/Redis
- [ ] **pm2** / **nginx** OK; **ALB + DNS** cutover
- [ ] EU instance decommissioned **after** validation

---

## Related docs

- **[AWS_AP_SOUTH_1_FULL_STACK_MIGRATION.md](./AWS_AP_SOUTH_1_FULL_STACK_MIGRATION.md)** — RDS, S3, full stack order.
- **[AWS_REGION_MIGRATION_GUIDE.md](./AWS_REGION_MIGRATION_GUIDE.md)** — env / S3 notes.

---

## Troubleshooting

| Problem | What to check |
|--------|----------------|
| **No key pair in Mumbai** | Key pairs are **regional** — create/import in **ap-south-1**. |
| **Lost `.pem`** | You cannot recover. Create **new** key pair, **launch new instance** from same AMI with new key (or use Session Manager / recovery runbook). |
| **AMI copy stuck** | Large disk; wait. Check **AMI** status in both regions. |
| **Cannot SSH** | SG port **22**, **correct key**, **correct user**, **public IP** or bastion. |
| **App can’t reach RDS** | RDS **security group** allows **this** EC2’s SG on **3306** in **Mumbai**. |
| **S3 errors** | `AWS_REGION=ap-south-1`, bucket in Mumbai, IAM role or keys valid. |
