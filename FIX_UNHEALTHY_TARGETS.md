# Fix Unhealthy Targets in ALB Target Group

## 🔍 Current Issue

- ✅ Instances registered in Target Group
- ❌ Status: **"Unhealthy"**
- ❌ Health checks failing

---

## Step 1: Check Health Check Configuration

### 1.1 Verify Health Check Settings

**AWS Console:**
1. **EC2** → **Target Groups** → Select your target group
2. Click **"Health checks"** tab
3. **Verify settings:**

**Required settings:**
- **Protocol:** HTTP
- **Port:** 3000 (or your backend port)
- **Path:** `/api/health` (or your health endpoint)
- **Healthy threshold:** 2
- **Unhealthy threshold:** 2
- **Timeout:** 5 seconds
- **Interval:** 30 seconds
- **Success codes:** 200

**If settings are wrong:**
- Click **"Edit"** → Fix settings → **Save**

### 1.2 Test Health Check Endpoint Manually

**SSH into your EC2 instance:**
```bash
# Test health endpoint
curl http://localhost:3000/api/health

# Expected response:
# {"status":"ok","message":"Easy Basket API is running"}
```

**If this fails:**
- Backend is not running
- Wrong port
- Health endpoint doesn't exist
- See Step 2 below

---

## Step 2: Verify Backend is Running

### 2.1 Check PM2 Status

**SSH into EC2 instance:**
```bash
# Check PM2 status
pm2 status

# Should show:
# ┌─────┬─────────────┬─────────┬─────────┬──────────┐
# │ id  │ name        │ status  │ cpu     │ memory   │
# ├─────┼─────────────┼─────────┼─────────┼─────────┤
# │ 0   │ easy-basket │ online  │ 0%      │ 50 MB    │
# └─────┴─────────────┴─────────┴─────────┴─────────┘
```

**If not running:**
```bash
# Start backend
cd /path/to/backend
pm2 start ecosystem.config.js
# Or
pm2 restart easy-basket-api
```

### 2.2 Check Backend Port

**Verify backend is listening on port 3000:**
```bash
# Check if port 3000 is listening
sudo netstat -tlnp | grep 3000
# Or
sudo ss -tlnp | grep 3000

# Expected output:
# tcp  0  0  0.0.0.0:3000  0.0.0.0:*  LISTEN  12345/node
```

**If port not listening:**
- Backend might be on different port
- Update Target Group health check port
- Or fix backend to use port 3000

### 2.3 Test Health Endpoint

**From EC2 instance:**
```bash
# Test localhost
curl http://localhost:3000/api/health

# Test private IP
curl http://<private-ip>:3000/api/health

# Expected: {"status":"ok","message":"Easy Basket API is running"}
```

**If this fails:**
- Check backend logs: `pm2 logs easy-basket-api`
- Verify health endpoint exists in backend code
- Check for errors in backend

---

## Step 3: Check Security Groups (Most Common Issue!)

### 3.1 ALB Security Group

**Check ALB can reach instances:**

**AWS Console:**
1. **EC2** → **Load Balancers** → Your ALB
2. **Security** tab → Note Security Group ID (e.g., `sg-xxxxxxxxxxxxx`)

**Required Inbound Rules:**
- **Port 80** from `0.0.0.0/0` (HTTP)
- **Port 443** from `0.0.0.0/0` (HTTPS)

**Required Outbound Rules:**
- **All traffic** to `0.0.0.0/0` (or restrict to VPC)

### 3.2 EC2 Instance Security Group

**⚠️ CRITICAL:** EC2 instances must allow traffic from ALB!

**AWS Console:**
1. **EC2** → **Instances** → Select your instance
2. **Security** tab → Click Security Group
3. **Inbound rules** → **Edit inbound rules**

**Add rule:**
- **Type:** Custom TCP
- **Port:** 3000
- **Source:** 
  - **Option 1 (Recommended):** Select ALB Security Group (e.g., `sg-xxxxxxxxxxxxx`)
  - **Option 2 (For testing):** `0.0.0.0/0` (less secure, but works)
- **Description:** Allow from ALB
- **Save rules**

**Repeat for Instance 2!**

### 3.3 Verify Security Group Rules

**Check both instances have correct rules:**

**AWS CLI:**
```bash
# Get ALB Security Group ID
ALB_SG_ID=$(aws elbv2 describe-load-balancers \
  --names easy-basket-alb \
  --query 'LoadBalancers[0].SecurityGroups[0]' \
  --output text)

echo "ALB Security Group: $ALB_SG_ID"

# Get Instance Security Group ID
INSTANCE_SG_ID=$(aws ec2 describe-instances \
  --instance-ids i-xxxxxxxxxxxxx \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

echo "Instance Security Group: $INSTANCE_SG_ID"

# Check if instance allows traffic from ALB
aws ec2 describe-security-groups \
  --group-ids $INSTANCE_SG_ID \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`3000`]' \
  --output json
```

**Expected:** Should show rule allowing port 3000 from ALB security group.

---

## Step 4: Check Network Connectivity

### 4.1 Test from ALB to Instance

**SSH into EC2 instance:**
```bash
# Get ALB private IP (if in same VPC)
# Or test from another instance in same VPC

# Test if health endpoint is accessible
curl -v http://localhost:3000/api/health
```

### 4.2 Check VPC and Subnets

**Verify:**
- ✅ ALB and instances are in **same VPC**
- ✅ Instances are in **subnets that ALB can reach**
- ✅ No Network ACLs blocking traffic

**AWS Console:**
1. **EC2** → **Load Balancers** → Your ALB
2. **Network mapping** tab → Note VPC and Subnets
3. **EC2** → **Instances** → Your instance
4. **Networking** tab → Verify same VPC

---

## Step 5: Check Health Check Path

### 5.1 Verify Health Endpoint Exists

**Backend should have:**
```typescript
// Example: backend/src/routes/health.ts or similar
router.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Easy Basket API is running'
  });
});
```

**Test from EC2:**
```bash
curl http://localhost:3000/api/health
```

**Expected response:**
```json
{"status":"ok","message":"Easy Basket API is running"}
```

**If different path:**
- Update Target Group health check path
- Or add health endpoint to backend

### 5.2 Check Response Status Code

**Health check expects HTTP 200:**
```bash
# Check status code
curl -I http://localhost:3000/api/health

# Expected:
# HTTP/1.1 200 OK
```

**If not 200:**
- Fix backend to return 200
- Or update Target Group success codes

---

## Step 6: Check Target Group Health Details

### 6.1 View Health Check Details

**AWS Console:**
1. **EC2** → **Target Groups** → Your target group
2. **Targets** tab
3. Click on unhealthy target
4. **Health checks** section shows:
   - **Status:** Unhealthy
   - **Reason:** (e.g., "Health checks failed", "Request timeout")
   - **Last health check:** (timestamp)

### 6.2 Common Error Messages

**"Health checks failed":**
- Security group blocking traffic
- Backend not responding
- Wrong port/path

**"Request timeout":**
- Backend too slow to respond
- Network issues
- Increase timeout in health check

**"Connection refused":**
- Backend not running
- Wrong port
- Security group blocking

**"HTTP 404":**
- Health check path incorrect
- Backend route doesn't exist

---

## Step 7: Fix Common Issues

### Issue 1: Security Group Not Allowing ALB

**Fix:**
1. **EC2** → **Security Groups** → Instance security group
2. **Inbound rules** → **Edit**
3. **Add rule:**
   - **Type:** Custom TCP
   - **Port:** 3000
   - **Source:** ALB Security Group ID
4. **Save**

### Issue 2: Backend Not Running

**Fix:**
```bash
# SSH into instance
ssh -i your-key.pem ec2-user@<instance-ip>

# Check PM2
pm2 status

# If not running, start it
cd /path/to/backend
pm2 start ecosystem.config.js

# Or restart
pm2 restart easy-basket-api

# Check logs
pm2 logs easy-basket-api
```

### Issue 3: Wrong Health Check Path

**Fix:**
1. **EC2** → **Target Groups** → Your target group
2. **Health checks** tab → **Edit**
3. **Path:** `/api/health` (or your actual path)
4. **Save**

### Issue 4: Wrong Port

**Fix:**
1. **EC2** → **Target Groups** → Your target group
2. **Health checks** tab → **Edit**
3. **Port:** 3000 (or your actual backend port)
4. **Save**

---

## Step 8: Verify Fix

### 8.1 Wait for Health Checks

**After fixing issues:**
- Wait **30-60 seconds** for health checks to run
- Health check interval: 30 seconds
- Healthy threshold: 2 (needs 2 successful checks)

### 8.2 Check Target Status

**AWS Console:**
1. **EC2** → **Target Groups** → Your target group
2. **Targets** tab
3. **Status** should change:
   - **Initial** → **Unhealthy** → **Healthy** ✅

**Timeline:**
- **Initial:** Just registered
- **Unhealthy:** Health checks failing
- **Healthy:** 2 successful health checks ✅

---

## Quick Diagnostic Checklist

**Run these checks in order:**

- [ ] **Backend running?** → `pm2 status` (should show online)
- [ ] **Port 3000 listening?** → `sudo netstat -tlnp | grep 3000`
- [ ] **Health endpoint works?** → `curl http://localhost:3000/api/health`
- [ ] **Security group allows ALB?** → Check inbound rules (port 3000 from ALB SG)
- [ ] **Health check path correct?** → `/api/health` in Target Group
- [ ] **Health check port correct?** → `3000` in Target Group
- [ ] **Same VPC?** → ALB and instances in same VPC

**If all checked:** Wait 1-2 minutes, status should become Healthy! ✅

---

## AWS CLI Commands

### Check Target Health

```bash
# Get Target Group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
  --names easy-basket-backend \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason,TargetHealth.Description]' \
  --output table
```

### Update Security Group

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

# Add rule to allow ALB
aws ec2 authorize-security-group-ingress \
  --group-id $INSTANCE_SG_ID \
  --protocol tcp \
  --port 3000 \
  --source-group $ALB_SG_ID
```

---

## Most Common Fix

**90% of the time, it's the security group!**

**Quick fix:**
1. **EC2** → **Instances** → Select instance
2. **Security** tab → Security Group → **Edit inbound rules**
3. **Add rule:**
   - **Type:** Custom TCP
   - **Port:** 3000
   - **Source:** ALB Security Group (or `0.0.0.0/0` for testing)
4. **Save**
5. **Repeat for Instance 2**
6. **Wait 1-2 minutes**
7. **Check Target Group** → Should be Healthy! ✅

---

## Summary

**Most likely causes (in order):**
1. ❌ **Security group not allowing ALB** (90% of cases)
2. ❌ **Backend not running** (5% of cases)
3. ❌ **Wrong health check path/port** (3% of cases)
4. ❌ **Network/VPC issues** (2% of cases)

**Quick fix:** Check security groups first! 🔒

