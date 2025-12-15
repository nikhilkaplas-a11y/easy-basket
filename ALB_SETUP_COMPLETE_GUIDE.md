# Complete ALB Setup Guide - Attach Both EC2 Instances

## ✅ What You Already Have

- ✅ PM2 Cluster Mode enabled on both instances
- ✅ Second EC2 instance created from AMI
- ✅ Target Group created (or will be created during ALB setup)

## 🎯 Goal

Create Application Load Balancer, get SSL certificate, attach both EC2 instances to Target Group, and configure ALB to distribute traffic between them.

## 📋 Prerequisites

Before starting, you'll need:
- ✅ Domain registered (`api.easybasket.in`)
- ✅ Access to GoDaddy DNS management (or your domain registrar)
- ✅ AWS account with EC2 and Certificate Manager access

**If you don't have SSL certificate yet:**
- See `SSL_CERTIFICATE_SETUP_GUIDE.md` for complete SSL setup instructions
- You can create certificate in parallel with ALB setup

---

## Step 1: Create Application Load Balancer (ALB)

### 1.1 Create ALB via AWS Console

1. **Go to AWS Console** → **EC2** → **Load Balancers**
2. Click **"Create Load Balancer"**
3. Select **"Application Load Balancer"** → Click **"Create"**

4. **Basic Configuration:**
   - **Name:** `easy-basket-alb` (or any name)
   - **Scheme:** Internet-facing
   - **IP address type:** IPv4

5. **Network Mapping:**
   - **VPC:** Select your VPC (same as your EC2 instances)
   - **Availability Zones:**
     - ✅ Select **at least 2 availability zones** (for high availability)
     - Example: `us-east-1a` and `us-east-1b`
     - Select subnets in each AZ

6. **Security Groups:**
   - **Create new security group** or **Select existing**
   - **Name:** `easy-basket-alb-sg`
   - **Inbound rules:**
     - **Type:** HTTP, **Port:** 80, **Source:** 0.0.0.0/0
     - **Type:** HTTPS, **Port:** 443, **Source:** 0.0.0.0/0
   - **Outbound rules:**
     - **Type:** All traffic, **Destination:** 0.0.0.0/0

7. **Listeners and Routing:**
   - **Protocol:** HTTP
   - **Port:** 80
   - **Default action:** Create new target group
     - **Target group name:** `easy-basket-backend`
     - **Target type:** Instances
     - **Protocol:** HTTP
     - **Port:** 3000
     - **Health check:**
       - **Path:** `/api/health`
       - **Protocol:** HTTP
       - **Port:** 3000
       - **Healthy threshold:** 2
       - **Unhealthy threshold:** 2
       - **Timeout:** 5 seconds
       - **Interval:** 30 seconds
       - **Success codes:** 200

8. **Register targets:** (Skip for now - we'll do this after configuring listeners)
   - Click **"Create target group"** (this creates the target group)
   - **Don't register targets yet** - we'll do this in Step 3

9. **Review and Create:**
   - Review all settings
   - Click **"Create load balancer"**

10. **Wait 2-3 minutes** for ALB to be created (status will show "Active")

### 1.2 Create ALB via AWS CLI

```bash
# Get VPC ID and Subnet IDs
VPC_ID=$(aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxxxxxx \
  --query 'Reservations[0].Instances[0].VpcId' \
  --output text)

SUBNET_1=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[0].SubnetId' \
  --output text)

SUBNET_2=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[1].SubnetId' \
  --output text)

# Create Security Group for ALB
ALB_SG_ID=$(aws ec2 create-security-group \
  --group-name easy-basket-alb-sg \
  --description "Security group for Easy Basket ALB" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# Allow HTTP and HTTPS
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Create Target Group
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
  --name easy-basket-backend \
  --protocol HTTP \
  --port 3000 \
  --vpc-id $VPC_ID \
  --health-check-path /api/health \
  --health-check-protocol HTTP \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group ARN: $TARGET_GROUP_ARN"

# Create Application Load Balancer
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name easy-basket-alb \
  --subnets $SUBNET_1 $SUBNET_2 \
  --security-groups $ALB_SG_ID \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "ALB ARN: $ALB_ARN"
echo "ALB DNS: $(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text)"
```

### 1.3 Verify ALB is Created

**AWS Console:**
1. **EC2** → **Load Balancers**
2. Find your ALB (`easy-basket-alb`)
3. Status should be **"Active"** (green)
4. Note the **DNS name** (e.g., `easy-basket-alb-1234567890.us-east-1.elb.amazonaws.com`)

**Or via AWS CLI:**
```bash
aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].[LoadBalancerName,State.Code,DNSName]' \
  --output table
```

---

## Step 2: Verify Both Instances Are Running

### 1.1 Check Instance Status

**AWS Console:**
1. Go to **EC2** → **Instances**
2. Verify both instances show **"Running"** status
3. Note down:
   - **Instance 1 ID:** `i-xxxxxxxxxxxxx`
   - **Instance 2 ID:** `i-yyyyyyyyyyyyy`
   - **Instance 1 Private IP:** `10.x.x.x`
   - **Instance 2 Private IP:** `10.y.y.y`

**Or via AWS CLI:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=easy-basket-backend*" \
  --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,State.Name,Tags[?Key=='Name'].Value|[0]]" \
  --output table
```

### 1.2 Verify Backend is Running on Both Instances

**SSH into Instance 1:**
```bash
ssh -i your-key.pem ec2-user@<instance-1-ip>

# Check PM2
pm2 status
# Should show multiple instances in cluster mode

# Check Nginx
sudo systemctl status nginx

# Test API
curl http://localhost:3000/api/health
# Should return: {"status":"ok","message":"Easy Basket API is running"}
```

**SSH into Instance 2:**
```bash
ssh -i your-key.pem ec2-user@<instance-2-ip>

# Check PM2
pm2 status

# Check Nginx
sudo systemctl status nginx

# Test API
curl http://localhost:3000/api/health
```

**Both should work!** ✅

---

## Step 3: Configure ALB Listeners FIRST (Important!)

⚠️ **IMPORTANT:** You must configure ALB listeners BEFORE registering targets. If you get error "Target group is not configured to receive traffic from the load balancer", configure listeners first!

### 3.1 Get SSL Certificate (Check Existing First!)

**⚠️ IMPORTANT:** You need an SSL certificate in **AWS Certificate Manager (ACM)** before configuring HTTPS listener.

**🔍 First, check if you already have a certificate:**

**AWS Console:**
1. Go to **Certificate Manager (ACM)**
2. **Important:** Make sure you're in the **same region** as your ALB
3. Look for certificate with domain: `api.easybasket.in`
4. Check status:
   - ✅ **"Issued"** (green) = **You can reuse it!** Skip to Step 3.2
   - ❌ **Not found** = Need to create new one

**If certificate exists in ACM:**
- ✅ **Reuse it!** No need to create new certificate
- Go to Step 3.2 to configure HTTPS listener

**If certificate doesn't exist in ACM:**
- ❌ **Create new certificate** (see `SSL_CERTIFICATE_SETUP_GUIDE.md`)
- **Note:** If you have SSL on EC2 (Nginx/Certbot), that's different - ALB needs ACM certificate

**📋 See `REUSE_EXISTING_SSL_CERTIFICATE.md` for detailed explanation of:**
- Difference between EC2 certificates and ACM certificates
- How to check if you have existing ACM certificate
- How to reuse existing certificate
- When to create new certificate

### 3.2 Configure HTTPS Listener (Port 443)

**AWS Console:**
1. **EC2** → **Load Balancers** → Select your ALB
2. Click **"Listeners"** tab
3. Check if HTTPS listener exists:
   - **If exists:** Click on it → **Edit** → Verify Target Group is selected
   - **If doesn't exist:** Click **"Add listener"**

4. **Configure HTTPS Listener:**
   - **Protocol:** HTTPS
   - **Port:** 443
   - **Default SSL certificate:**
     - Select **"From ACM"** (AWS Certificate Manager)
     - **Certificate:** Select `api.easybasket.in` (your certificate)
     - ⚠️ **Certificate must be in same region as ALB!**
   - **Default action:** Forward to
   - **Target group:** Select `easy-basket-backend` (your target group)
   - Click **"Save"**

**If certificate doesn't appear:**
- Check certificate is in **same region** as ALB
- Check certificate status is **"Issued"** (not "Pending validation")

### 3.3 Configure HTTP Listener (Port 80)

1. **Listeners** tab → **Add listener**
2. **Configure:**
   - **Protocol:** HTTP
   - **Port:** 80
   - **Default action:** Redirect to HTTPS
   - **Status code:** 301
   - **Port:** 443
   - **Protocol:** HTTPS
   - Click **"Save"**

### 3.4 Verify Listeners are Configured

**Check Listeners tab:**
- ✅ HTTP (Port 80) → Redirect to HTTPS
- ✅ HTTPS (Port 443) → Forward to Target Group

**Now you can register targets!**

---

## Step 4: Register Instances with Target Group

### 3.1 Get Target Group Details

**AWS Console:**
1. Go to **EC2** → **Target Groups**
2. Click on your target group (e.g., `easy-basket-backend`)
3. Note:
   - **Target Group ARN:** `arn:aws:elasticloadbalancing:...`
   - **Target Group Name:** `easy-basket-backend`
   - **Port:** Should be `3000`
   - **Protocol:** Should be `HTTP`
   - **Health Check Path:** Should be `/api/health`

### 3.2 Register Instances via AWS Console

1. **EC2** → **Target Groups** → Select your target group
2. Click **"Register targets"** tab
3. **Select instances:**
   - ✅ Check **Instance 1**
   - ✅ Check **Instance 2**
4. **Port:** `3000` (should be pre-filled)
5. Click **"Register pending targets"**
6. Wait 1-2 minutes for registration

**Verify:**
- Both instances should appear in **"Registered targets"** tab
- Status should change from **"Initial"** → **"Healthy"** (takes 30-60 seconds)

### 3.3 Register Instances via AWS CLI

```bash
# Get Target Group ARN
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
  --names easy-basket-backend \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group ARN: $TARGET_GROUP_ARN"

# Register Instance 1
aws elbv2 register-targets \
  --target-group-arn $TARGET_GROUP_ARN \
  --targets Id=i-xxxxxxxxxxxxx,Port=3000

# Register Instance 2
aws elbv2 register-targets \
  --target-group-arn $TARGET_GROUP_ARN \
  --targets Id=i-yyyyyyyyyyyyy,Port=3000

# Verify registration
aws elbv2 describe-target-health \
  --target-group-arn $TARGET_GROUP_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
  --output table
```

**Expected output:**
```
Instance ID          State    Description
i-xxxxxxxxxxxxx      healthy  Target registration is in progress
i-yyyyyyyyyyyyy      healthy  Target is healthy
```

---

## Step 5: Verify Listeners Configuration (Already Done in Step 3)

### 3.1 Check Current Listeners

**AWS Console:**
1. **EC2** → **Load Balancers** → Select your ALB
2. Go to **"Listeners"** tab
3. Check if listeners exist:
   - **Port 80** (HTTP) - Should redirect to HTTPS
   - **Port 443** (HTTPS) - Should forward to Target Group

### 3.2 Create/Update HTTP Listener (Port 80)

**If listener doesn't exist:**

1. **Load Balancers** → Your ALB → **Listeners** tab
2. Click **"Add listener"**
3. **Configure:**
   - **Protocol:** HTTP
   - **Port:** 80
   - **Default action:** Redirect to HTTPS
   - **Status code:** 301
   - **Port:** 443
   - **Protocol:** HTTPS
4. Click **"Save"**

**Or via AWS CLI:**
```bash
# Get Load Balancer ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

# Create HTTP listener (redirect to HTTPS)
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'
```

### 3.3 Create/Update HTTPS Listener (Port 443)

**If listener doesn't exist:**

1. **Load Balancers** → Your ALB → **Listeners** tab
2. Click **"Add listener"**
3. **Configure:**
   - **Protocol:** HTTPS
   - **Port:** 443
   - **Default SSL certificate:** 
     - Select **"From ACM"** (if using AWS Certificate Manager)
     - Or **"From IAM"** (if using IAM certificates)
     - Select your certificate for `api.easybasket.in`
   - **Default action:** Forward to Target Group
   - **Target group:** Select `easy-basket-backend`
   - **Forward to:** `easy-basket-backend` (your target group)
4. Click **"Save"**

**Or via AWS CLI:**
```bash
# Get Certificate ARN (if using ACM)
CERT_ARN=$(aws acm list-certificates \
  --query "CertificateSummaryList[?DomainName=='api.easybasket.in'].CertificateArn" \
  --output text)

# Create HTTPS listener
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERT_ARN \
  --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN
```

---

## Step 6: Configure Security Groups

### 4.1 ALB Security Group

**Check ALB Security Group:**
1. **EC2** → **Load Balancers** → Your ALB → **Security** tab
2. Note the **Security Group ID** (e.g., `sg-xxxxxxxxxxxxx`)

**Required Inbound Rules:**
- **Port 80** (HTTP) from `0.0.0.0/0`
- **Port 443** (HTTPS) from `0.0.0.0/0`

**Required Outbound Rules:**
- **All traffic** to `0.0.0.0/0` (or restrict to your VPC)

### 4.2 EC2 Instances Security Group

**Both instances need to allow traffic from ALB:**

1. **EC2** → **Security Groups** → Select your instance security group
2. **Inbound rules** → **Edit inbound rules**
3. **Add rule:**
   - **Type:** Custom TCP
   - **Port:** 3000
   - **Source:** Select ALB security group (or `0.0.0.0/0` for testing)
   - **Description:** Allow from ALB
4. **Save rules**

**Or via AWS CLI:**
```bash
# Get ALB Security Group ID
ALB_SG_ID=$(aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].SecurityGroups[0]' \
  --output text)

# Get Instance Security Group ID
INSTANCE_SG_ID=$(aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxxxxxx \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

# Add rule to allow ALB to access instances
aws ec2 authorize-security-group-ingress \
  --group-id $INSTANCE_SG_ID \
  --protocol tcp \
  --port 3000 \
  --source-group $ALB_SG_ID
```

---

## Step 7: Update DNS to Point to ALB

### 5.1 Get ALB DNS Name

**AWS Console:**
1. **EC2** → **Load Balancers** → Your ALB
2. Copy the **DNS name** (e.g., `easy-basket-alb-1234567890.us-east-1.elb.amazonaws.com`)

**Or via AWS CLI:**
```bash
aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text
```

### 5.2 Update GoDaddy DNS

1. **Login to GoDaddy** → **My Products** → **Domains** → **easybasket.in**
2. **DNS Management**
3. **Find the A record or CNAME for `api`:**
   - If **A record exists:** Delete it
   - If **CNAME exists:** Update it
4. **Add/Update CNAME record:**
   - **Type:** CNAME
   - **Name:** `api`
   - **Value:** `<alb-dns-name>` (e.g., `easy-basket-alb-1234567890.us-east-1.elb.amazonaws.com`)
   - **TTL:** 3600 (1 hour)
5. **Save**

**Wait 5-10 minutes** for DNS propagation.

### 5.3 Verify DNS

```bash
# Check DNS resolution
dig api.easybasket.in
# or
nslookup api.easybasket.in

# Should resolve to ALB IP addresses
```

---

## Step 8: Test the Setup

### 6.1 Test Health Checks

**AWS Console:**
1. **EC2** → **Target Groups** → Your target group
2. **Targets** tab
3. Both instances should show **"Healthy"** status
4. If **"Unhealthy":**
   - Check health check path: `/api/health`
   - Check backend is running: `curl http://localhost:3000/api/health`
   - Check security groups allow ALB → Instance

**Or via AWS CLI:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn $TARGET_GROUP_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
  --output table
```

### 6.2 Test ALB Endpoint

```bash
# Test HTTP (should redirect to HTTPS)
curl -I http://api.easybasket.in/api/health
# Should return: 301 Moved Permanently

# Test HTTPS
curl https://api.easybasket.in/api/health
# Should return: {"status":"ok","message":"Easy Basket API is running"}

# Test multiple times (should hit different instances)
for i in {1..10}; do
  echo "Request $i:"
  curl -s https://api.easybasket.in/api/health | head -1
  sleep 1
done
```

### 6.3 Test from Browser

1. Open browser
2. Go to: `https://api.easybasket.in/api/health`
3. Should see: `{"status":"ok","message":"Easy Basket API is running"}`

---

## Step 9: Test Failover

### 7.1 Stop One Instance

**AWS Console:**
1. **EC2** → **Instances**
2. Select **Instance 1**
3. **Instance state** → **Stop instance**
4. Confirm

**Or via AWS CLI:**
```bash
aws ec2 stop-instances --instance-ids i-xxxxxxxxxxxxx
```

### 7.2 Verify Traffic Still Works

```bash
# Wait 30-60 seconds for health check to detect
sleep 60

# Test API (should still work via Instance 2)
curl https://api.easybasket.in/api/health
# Should still return success
```

**Check Target Group:**
- Instance 1: **"Unhealthy"** or **"Draining"**
- Instance 2: **"Healthy"**
- ALB automatically routes all traffic to Instance 2

### 7.3 Start Instance Again

```bash
aws ec2 start-instances --instance-ids i-xxxxxxxxxxxxx

# Wait for it to become healthy again
# Check Target Group - should show "Healthy" after 30-60 seconds
```

---

## Step 10: Update Backend Code on Both Instances

### 8.1 Deploy to Instance 1

```bash
# SSH into Instance 1
ssh -i your-key.pem ec2-user@<instance-1-ip>

cd ~/easy-basket/backend
git pull origin main
npm install
npm run build

# Reload PM2 (zero downtime)
pm2 reload ecosystem.config.js

# Verify
pm2 status
curl http://localhost:3000/api/health
```

### 8.2 Deploy to Instance 2

```bash
# SSH into Instance 2
ssh -i your-key.pem ec2-user@<instance-2-ip>

cd ~/easy-basket/backend
git pull origin main
npm install
npm run build

# Reload PM2 (zero downtime)
pm2 reload ecosystem.config.js

# Verify
pm2 status
curl http://localhost:3000/api/health
```

### 8.3 Automated Deployment Script

Create `deploy-to-all-instances.sh`:

```bash
#!/bin/bash

# Get all instance IPs
INSTANCE_IPS=(
  "13.60.76.140"  # Instance 1
  "13.xx.xx.xx"   # Instance 2 (replace with actual IP)
)

KEY_FILE="your-key.pem"

for IP in "${INSTANCE_IPS[@]}"; do
  echo "Deploying to $IP..."
  
  ssh -i $KEY_FILE ec2-user@$IP << 'ENDSSH'
    cd ~/easy-basket/backend
    git pull origin main
    npm install
    npm run build
    pm2 reload ecosystem.config.js
    echo "✅ Deployment complete on $(hostname)"
ENDSSH
  
  echo "✅ Deployed to $IP"
done

echo "✅ All instances deployed!"
```

---

## Step 11: Monitor and Verify

### 9.1 Check ALB Metrics

**AWS Console:**
1. **EC2** → **Load Balancers** → Your ALB
2. **Monitoring** tab
3. Check:
   - **Request count** (should be distributed)
   - **Target response time**
   - **Healthy host count** (should be 2)
   - **Unhealthy host count** (should be 0)

### 9.2 Check Target Group Health

```bash
# Continuous monitoring
watch -n 5 'aws elbv2 describe-target-health \
  --target-group-arn $TARGET_GROUP_ARN \
  --query "TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]" \
  --output table'
```

### 9.3 Test Load Distribution

```bash
# Make 20 requests and see which instance handles them
for i in {1..20}; do
  echo -n "Request $i: "
  curl -s https://api.easybasket.in/api/health | jq -r '.message' 2>/dev/null || echo "Success"
  sleep 0.5
done

# Requests should be distributed between both instances
```

---

## Step 12: Final Verification Checklist

- [ ] Both instances registered in Target Group
- [ ] Both instances show "Healthy" status
- [ ] ALB listeners configured (HTTP → HTTPS redirect, HTTPS → Target Group)
- [ ] Security groups allow ALB → Instances (port 3000)
- [ ] DNS updated to point to ALB
- [ ] HTTPS endpoint works: `https://api.easybasket.in/api/health`
- [ ] HTTP redirects to HTTPS
- [ ] Load balancing works (requests distributed)
- [ ] Failover works (stop one instance, other handles traffic)
- [ ] Both instances can deploy independently

---

## Troubleshooting

### Issue 1: Targets Show "Unhealthy"

**Check:**
```bash
# SSH into instance
ssh -i your-key.pem ec2-user@<instance-ip>

# Test health endpoint
curl http://localhost:3000/api/health

# Check if backend is running
pm2 status
sudo systemctl status nginx

# Check security group
# ALB security group should allow outbound to instance security group
# Instance security group should allow inbound from ALB security group on port 3000
```

**Fix:**
- Ensure backend is running on port 3000
- Ensure health check path is `/api/health`
- Ensure security groups allow ALB → Instance communication

### Issue 2: 502 Bad Gateway

**Check:**
- Target Group health status
- Backend is running on both instances
- Security groups configured correctly

**Fix:**
```bash
# Restart backend on unhealthy instance
pm2 restart ecosystem.config.js

# Check logs
pm2 logs easy-basket-api --lines 50
```

### Issue 3: DNS Not Resolving

**Check:**
```bash
dig api.easybasket.in
nslookup api.easybasket.in
```

**Fix:**
- Wait 10-15 minutes for DNS propagation
- Verify CNAME record in GoDaddy
- Clear DNS cache: `sudo dscacheutil -flushcache` (Mac)

### Issue 4: SSL Certificate Error

**Check:**
- Certificate is attached to ALB listener
- Certificate is for `api.easybasket.in`
- Certificate is valid (not expired)

**Fix:**
- Request new certificate in ACM if needed
- Attach to HTTPS listener

---

## Quick Reference Commands

```bash
# Get Target Group ARN
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
  --names easy-basket-backend \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Get ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

# Check target health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN

# Register instance
aws elbv2 register-targets \
  --target-group-arn $TARGET_GROUP_ARN \
  --targets Id=i-xxx,Port=3000

# Deregister instance
aws elbv2 deregister-targets \
  --target-group-arn $TARGET_GROUP_ARN \
  --targets Id=i-xxx,Port=3000
```

---

## Architecture Diagram

```
Internet
   ↓
Application Load Balancer (ALB)
   ├── Listener: Port 80 (HTTP) → Redirect to HTTPS
   └── Listener: Port 443 (HTTPS) → Forward to Target Group
           ↓
      Target Group: easy-basket-backend
           ├── Instance 1 (i-xxx) :3000 ✅ Healthy
           └── Instance 2 (i-yyy) :3000 ✅ Healthy
                   ↓
              PM2 Cluster Mode (multiple processes per instance)
                   ↓
              Node.js Backend
                   ↓
              RDS MySQL Database
```

---

## Cost Estimate

- **2x EC2 Instances:** ~$14-20/month
- **Application Load Balancer:** ~$16/month
- **Data Transfer:** Minimal (within same region)
- **Total:** ~$30-36/month

---

## Next Steps

1. ✅ **Setup CloudWatch Alarms** (alert if instance unhealthy)
2. ✅ **Setup Auto Scaling** (add instances based on traffic)
3. ✅ **Setup Logging** (ALB access logs to S3)
4. ✅ **Setup WAF** (Web Application Firewall for security)

---

## Summary

✅ **Both instances registered** in Target Group
✅ **ALB configured** with HTTP/HTTPS listeners
✅ **Security groups** allow communication
✅ **DNS updated** to point to ALB
✅ **Load balancing** working
✅ **Failover** tested and working

Your backend is now **highly available** with zero-downtime deployments! 🚀

