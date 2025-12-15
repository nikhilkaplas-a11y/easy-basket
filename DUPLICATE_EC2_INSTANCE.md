# Duplicate EC2 Instance - Create Same Instance with Same Config

## Overview

You'll create an **AMI (Amazon Machine Image)** from your current instance, then launch a new instance from it. This gives you an identical copy with all your configurations.

---

## Method 1: Using AWS Console (Easiest)

### Step 1: Create AMI from Current Instance

1. **Go to AWS Console** → EC2 → Instances
2. **Select your current instance** (the one running your backend)
3. **Right-click** → **Image and templates** → **Create image**
4. **Configure AMI:**
   - **Image name:** `easy-basket-backend-v1` (or any name)
   - **Image description:** `Backend server with Node.js, PM2, Nginx, and all configurations`
   - **No reboot:** ✅ **Uncheck this** (let it reboot to ensure consistency)
   - **Tags:** Add tags if needed (e.g., `Name: easy-basket-backend`)
5. **Click "Create image"**

### Step 2: Wait for AMI Creation

- This takes **5-15 minutes** depending on instance size
- **Check status:** EC2 → AMIs → Your AMI name
- Wait until status shows **"Available"** (not "Pending")

### Step 3: Launch New Instance from AMI

1. **Go to EC2** → **AMIs** → Select your AMI
2. **Click "Launch instance from AMI"**
3. **Configure instance:**
   - **Name:** `easy-basket-backend-2` (or any name)
   - **Instance type:** Same as original (e.g., `t3.micro`, `t3.small`)
   - **Key pair:** Select your existing key pair (same as original)
   - **Network settings:**
     - **VPC:** Same VPC as original
     - **Subnet:** Different subnet (for high availability) OR same subnet
     - **Auto-assign Public IP:** Enable
     - **Security Group:** Select same security group as original
4. **Configure storage:** Same as original (usually 20-30 GB)
5. **Click "Launch instance"**

### Step 4: Update New Instance Configuration

**SSH into new instance:**
```bash
ssh -i your-key.pem ec2-user@<new-instance-ip>
```

**Update configurations that need to be unique:**

```bash
# 1. Update Nginx config (if it has hardcoded IPs)
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Update server_name if needed

# 2. Update PM2 process name (optional, to distinguish)
cd ~/easy-basket/backend
pm2 delete easy-basket-api  # If it auto-started
pm2 start ecosystem.config.js --update-env

# 3. Verify everything works
pm2 status
sudo systemctl status nginx
curl http://localhost:3000/api/health
```

---

## Method 2: Using AWS CLI (Faster for Automation)

### Step 1: Create AMI

```bash
# Get your instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=your-instance-name" \
  --query "Reservations[*].Instances[*].[InstanceId]" \
  --output text

# Create AMI (replace INSTANCE_ID)
aws ec2 create-image \
  --instance-id i-xxxxxxxxxxxxx \
  --name "easy-basket-backend-$(date +%Y%m%d)" \
  --description "Backend server AMI" \
  --no-reboot

# Note the ImageId from output
```

### Step 2: Wait for AMI (Check Status)

```bash
# Check AMI status
aws ec2 describe-images \
  --image-ids ami-xxxxxxxxxxxxx \
  --query "Images[*].[ImageId,State]" \
  --output table

# Wait until State = "available"
```

### Step 3: Launch New Instance

```bash
# Get your security group ID and subnet ID from original instance
aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxxxxxx \
  --query "Reservations[*].Instances[*].[SecurityGroups[0].GroupId,SubnetId]" \
  --output text

# Launch new instance (replace values)
aws ec2 run-instances \
  --image-id ami-xxxxxxxxxxxxx \
  --instance-type t3.micro \
  --key-name your-key-name \
  --security-group-ids sg-xxxxxxxxxxxxx \
  --subnet-id subnet-xxxxxxxxxxxxx \
  --associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=easy-basket-backend-2}]'
```

---

## Method 3: Using EC2 Launch Templates (Best for Production)

### Step 1: Create Launch Template from Current Instance

1. **EC2 Console** → **Launch Templates** → **Create launch template**
2. **Source:** Select your current instance
3. **Template details:**
   - **Name:** `easy-basket-backend-template`
   - **Description:** `Template for backend servers`
4. **Configure:**
   - All settings will be pre-filled from your instance
   - Review and adjust if needed
5. **Create template**

### Step 2: Launch Instances from Template

```bash
# Launch multiple instances at once
aws ec2 run-instances \
  --launch-template LaunchTemplateName=easy-basket-backend-template,Version=1 \
  --count 2 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=easy-basket-backend}]'
```

---

## Step 5: Setup Load Balancer (After Creating 2nd Instance)

### Option A: Update Nginx on Both Instances

**On Instance 1:**
```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Update upstream block:**
```nginx
upstream backend_servers {
    least_conn;
    server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
    server <instance-2-private-ip>:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}
```

**On Instance 2:**
```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Update upstream block:**
```nginx
upstream backend_servers {
    least_conn;
    server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
    server <instance-1-private-ip>:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}
```

**Reload both:**
```bash
sudo nginx -t && sudo systemctl reload nginx
```

### Option B: Use AWS Application Load Balancer (Recommended)

See `HIGH_AVAILABILITY_SETUP.md` for ALB setup guide.

---

## Step 6: Update DNS (If Using ALB)

If you set up ALB:
1. Get ALB DNS name from AWS Console
2. Update your domain DNS (GoDaddy):
   - Type: `CNAME`
   - Name: `api`
   - Value: `<alb-dns-name>`
   - TTL: 3600

---

## Important: Things to Update on New Instance

### 1. PM2 Process Names (Optional)

```bash
# On new instance, you might want different names
cd ~/easy-basket/backend
pm2 delete easy-basket-api
pm2 start ecosystem.config.js --name easy-basket-api-2
```

### 2. Log Files (Optional)

If you want separate logs:
```bash
# Update ecosystem.config.js
# Change log file paths
error_file: './logs/err-instance2.log',
out_file: './logs/out-instance2.log',
```

### 3. Environment Variables (If Different)

```bash
# Check if .env needs updates
cd ~/easy-basket/backend
cat .env

# Usually same config is fine (both connect to same RDS)
```

### 4. Firewall Rules

Ensure security groups allow:
- **Port 22 (SSH)** from your IP
- **Port 80 (HTTP)** from 0.0.0.0/0
- **Port 443 (HTTPS)** from 0.0.0.0/0
- **Port 3000** from other instances (for load balancing)

---

## Verification Checklist

After creating new instance:

- [ ] New instance is running
- [ ] Can SSH into new instance
- [ ] PM2 is running backend
- [ ] Nginx is running
- [ ] API health check works: `curl http://localhost:3000/api/health`
- [ ] Both instances can communicate (if using Nginx load balancing)
- [ ] Database connection works (both use same RDS)
- [ ] SSL certificates work (if copied or re-issued)

---

## Cost Considerations

- **AMI Storage:** ~$0.10 per GB per month (for the AMI snapshot)
- **New Instance:** Same cost as your current instance
- **Data Transfer:** Minimal (between instances in same region)

**Example:**
- Current: 1x t3.micro = ~$7-10/month
- After duplication: 2x t3.micro = ~$14-20/month
- ALB (optional): ~$16/month

---

## Quick Commands Reference

```bash
# Create AMI from instance
aws ec2 create-image --instance-id i-xxx --name "easy-basket-backend"

# Launch instance from AMI
aws ec2 run-instances --image-id ami-xxx --instance-type t3.micro --key-name your-key

# List your AMIs
aws ec2 describe-images --owners self --query "Images[*].[ImageId,Name,CreationDate]" --output table

# Get instance IPs
aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,PrivateIpAddress]" --output table
```

---

## Troubleshooting

### Issue: AMI Creation Fails

- Check instance is in "running" state
- Ensure you have permissions
- Check instance has enough storage

### Issue: New Instance Can't Connect to Database

- Verify security group allows outbound to RDS port 3306
- Check RDS security group allows inbound from new instance
- Verify .env has correct RDS endpoint

### Issue: SSL Certificate Not Working

- Certificates are tied to domain, not instance
- If using same domain, certificates should work
- If issues, re-run Certbot: `sudo certbot --nginx -d api.easybasket.in`

---

## Next Steps After Duplication

1. ✅ **Setup load balancing** (Nginx or ALB)
2. ✅ **Test failover** (stop one instance, verify other handles traffic)
3. ✅ **Setup monitoring** (CloudWatch alarms)
4. ✅ **Automate deployments** (deploy to both instances)

See `HIGH_AVAILABILITY_SETUP.md` for complete setup guide.

