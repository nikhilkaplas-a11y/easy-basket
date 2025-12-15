# Troubleshoot API Health Endpoint

## 🔍 Current Issue

`curl http://api.easybasket.in/api/health` is not working

---

## Step 1: Check What Error You're Getting

**Run the command with verbose output:**
```bash
curl -v http://api.easybasket.in/api/health
```

**Common errors:**
- `Connection refused` → Backend not running
- `Connection timeout` → Security group or network issue
- `404 Not Found` → Route not configured
- `502 Bad Gateway` → ALB can't reach backend
- `503 Service Unavailable` → All targets unhealthy

---

## Step 2: Check ALB Status

**AWS Console:**
1. **EC2** → **Load Balancers** → Select your ALB
2. Check **Status:** Should be **"Active"** (green)
3. **Listeners** tab:
   - HTTP (Port 80) → Should redirect to HTTPS
   - HTTPS (Port 443) → Should forward to Target Group

**Or via AWS CLI:**
```bash
aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].[State.Code,DNSName]' \
  --output table
```

---

## Step 3: Check Target Group Health

**AWS Console:**
1. **EC2** → **Target Groups** → Select your target group
2. **Targets** tab
3. Check status of both instances:
   - ✅ **Healthy** = Good
   - ❌ **Unhealthy** = Problem

**If unhealthy:**
- Check security groups (ALB → Instance on port 3000)
- Check backend is running on instances
- Check health check path/port

**Or via AWS CLI:**
```bash
TG_ARN=$(aws elbv2 describe-target-groups \
  --names easy-basket-backend \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason]' \
  --output table
```

---

## Step 4: Check Backend on EC2 Instances

**SSH into Instance 1:**
```bash
ssh -i your-key.pem ec2-user@<instance-1-ip>

# Check PM2 status
pm2 status

# Check if backend is running
curl http://localhost:3000/api/health

# Check Nginx
sudo systemctl status nginx

# Check PM2 logs
pm2 logs easy-basket-api --lines 50
```

**SSH into Instance 2:**
```bash
ssh -i your-key.pem ec2-user@<instance-2-ip>

# Same checks as above
pm2 status
curl http://localhost:3000/api/health
```

**If backend not running:**
```bash
# Restart backend
cd /path/to/backend
pm2 restart easy-basket-api

# Or start if not running
pm2 start ecosystem.config.js
```

---

## Step 5: Check Security Groups

### ALB Security Group

**Should allow:**
- **Inbound:** Port 80, 443 from `0.0.0.0/0`
- **Outbound:** All traffic to `0.0.0.0/0` (or VPC)

### EC2 Instance Security Groups

**Should allow:**
- **Inbound:** Port 3000 from ALB Security Group
- **Outbound:** All traffic

**Check via AWS CLI:**
```bash
# Get ALB Security Group
ALB_SG_ID=$(aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].SecurityGroups[0]' \
  --output text)

# Get Instance Security Group
INSTANCE_SG_ID=$(aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxxxxxx \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

# Check if instance allows ALB
aws ec2 describe-security-groups \
  --group-ids $INSTANCE_SG_ID \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`3000`]' \
  --output json
```

---

## Step 6: Check DNS Resolution

**Test DNS:**
```bash
# Check if DNS resolves correctly
nslookup api.easybasket.in

# Or
dig api.easybasket.in

# Should resolve to ALB DNS name
```

**Check ALB DNS:**
```bash
# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "ALB DNS: $ALB_DNS"

# Test ALB directly
curl -v http://$ALB_DNS/api/health
```

---

## Step 7: Check Backend Route

**Verify health endpoint exists in backend:**

**SSH into instance:**
```bash
# Check backend routes
grep -r "health" /path/to/backend/src/routes/

# Or check if endpoint responds locally
curl http://localhost:3000/api/health
```

**Expected response:**
```json
{"status":"ok","message":"Easy Basket API is running"}
```

---

## Step 8: Check Nginx Configuration

**SSH into instance:**
```bash
# Check Nginx config
sudo cat /etc/nginx/conf.d/easy-basket.conf

# Test Nginx config
sudo nginx -t

# Check Nginx status
sudo systemctl status nginx

# Check Nginx logs
sudo tail -50 /var/log/nginx/error.log
```

**If Nginx is running but ALB is configured:**
- Nginx might not be needed (ALB handles routing)
- Or Nginx might be blocking requests

---

## Step 9: Test Direct ALB Access

**Test HTTPS (should work):**
```bash
curl -v https://api.easybasket.in/api/health
```

**Test HTTP (should redirect):**
```bash
curl -v http://api.easybasket.in/api/health
# Should return 301 redirect to HTTPS
```

**Test ALB DNS directly:**
```bash
# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

# Test HTTPS
curl -v https://$ALB_DNS/api/health

# Test HTTP
curl -v http://$ALB_DNS/api/health
```

---

## Step 10: Common Fixes

### Fix 1: Backend Not Running

**SSH into both instances:**
```bash
# Check PM2
pm2 status

# If not running, start it
cd /path/to/backend
pm2 start ecosystem.config.js

# Or restart
pm2 restart easy-basket-api
```

### Fix 2: Targets Unhealthy

**Check and fix security groups:**
1. **EC2** → **Instances** → Select instance
2. **Security** tab → Security Group → **Edit inbound rules**
3. **Add rule:**
   - **Type:** Custom TCP
   - **Port:** 3000
   - **Source:** ALB Security Group
4. **Save**

### Fix 3: Health Check Failing

**Check Target Group health check:**
1. **EC2** → **Target Groups** → Your target group
2. **Health checks** tab
3. **Verify:**
   - **Path:** `/api/health`
   - **Port:** 3000
   - **Protocol:** HTTP

### Fix 4: ALB Not Active

**Check ALB status:**
- If status is not "Active", wait a few minutes
- Check for any errors in ALB events

---

## Quick Diagnostic Commands

**Run these to diagnose:**

```bash
# 1. Test DNS
nslookup api.easybasket.in

# 2. Test HTTP (should redirect)
curl -I http://api.easybasket.in/api/health

# 3. Test HTTPS
curl -I https://api.easybasket.in/api/health

# 4. Test ALB directly
ALB_DNS=$(aws elbv2 describe-load-balancers --names easy-basket-alb --query 'LoadBalancers[0].DNSName' --output text)
curl -I https://$ALB_DNS/api/health

# 5. Check target health
TG_ARN=$(aws elbv2 describe-target-groups --names easy-basket-backend --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN --output table
```

---

## Most Likely Issues

1. **Backend not running on instances** (90% of cases)
   - Fix: SSH and restart PM2

2. **Targets unhealthy** (5% of cases)
   - Fix: Check security groups

3. **ALB listeners not configured** (3% of cases)
   - Fix: Configure HTTPS listener

4. **DNS not pointing to ALB** (2% of cases)
   - Fix: Update DNS in GoDaddy

---

## Next Steps

1. **Run diagnostic commands** above
2. **Check target health** in AWS Console
3. **SSH into instances** and check backend
4. **Fix the issue** based on findings
5. **Test again** with curl

**Share the error message from `curl -v` and I can help pinpoint the exact issue!**

