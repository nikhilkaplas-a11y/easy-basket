# Verify Health Check Configuration

## ✅ Good News!

Your health endpoint is working:
```
HTTP/1.1 200 OK
```

This means:
- ✅ Backend is running
- ✅ Health endpoint exists (`/api/health`)
- ✅ Returns correct status code (200)
- ✅ Accessible via domain (through ALB)

**But targets are still showing "Unhealthy"** - this means health checks from ALB to instances are failing.

---

## 🔍 Check Target Group Health Check Configuration

### Step 1: Verify Health Check Settings

**AWS Console:**
1. **EC2** → **Target Groups** → Select your target group
2. Click **"Health checks"** tab
3. **Verify these settings:**

**Required Configuration:**
- **Protocol:** HTTP
- **Port:** 3000 (must match your backend port)
- **Path:** `/api/health` (must match your endpoint)
- **Healthy threshold:** 2
- **Unhealthy threshold:** 2
- **Timeout:** 5 seconds
- **Interval:** 30 seconds
- **Success codes:** 200

**⚠️ Common Issues:**
- ❌ Port is 80 instead of 3000
- ❌ Path is `/health` instead of `/api/health`
- ❌ Protocol is HTTPS instead of HTTP

### Step 2: Check Target Health Details

**AWS Console:**
1. **EC2** → **Target Groups** → Your target group
2. **Targets** tab
3. Click on the **unhealthy target**
4. **Health checks** section shows:
   - **Status:** Unhealthy
   - **Reason:** (e.g., "Health checks failed", "Request timeout")
   - **Last health check:** (timestamp)
   - **Response code:** (if any)

**This tells you exactly why it's failing!**

---

## 🔧 Most Likely Issues

### Issue 1: Health Check Port is Wrong

**Problem:** Health check might be using port 80 instead of 3000

**Fix:**
1. **EC2** → **Target Groups** → Your target group
2. **Health checks** tab → **Edit**
3. **Port:** Change to `3000` (not 80)
4. **Save**

### Issue 2: Health Check Path is Wrong

**Problem:** Health check might be using `/health` instead of `/api/health`

**Fix:**
1. **EC2** → **Target Groups** → Your target group
2. **Health checks** tab → **Edit**
3. **Path:** Change to `/api/health`
4. **Save**

### Issue 3: Security Group Blocking Health Checks

**Problem:** ALB can't reach instances on port 3000

**Fix:**
1. **EC2** → **Instances** → Select your instance
2. **Security** tab → Security Group → **Edit inbound rules**
3. **Add rule:**
   - **Type:** Custom TCP
   - **Port:** 3000
   - **Source:** ALB Security Group ID
   - **Description:** Allow health checks from ALB
4. **Save**
5. **Repeat for Instance 2**

### Issue 4: Health Check Using Private IP

**Problem:** Health checks go to instance private IP, not public IP

**Verify:**
- Health checks should use **private IP** (this is correct)
- Make sure security group allows ALB → Instance on port 3000

---

## 🧪 Test Health Check from Instance

**SSH into your EC2 instance:**
```bash
# Test health endpoint on localhost
curl -I http://localhost:3000/api/health

# Expected:
# HTTP/1.1 200 OK

# Test on private IP
PRIVATE_IP=$(hostname -I | awk '{print $1}')
curl -I http://$PRIVATE_IP:3000/api/health

# Expected:
# HTTP/1.1 200 OK
```

**If this works but ALB health checks fail:**
- It's a security group issue
- ALB can't reach the instance

---

## 🔍 Diagnostic Steps

### Step 1: Check Health Check Configuration

**AWS Console:**
1. **EC2** → **Target Groups** → Your target group
2. **Health checks** tab
3. **Note down:**
   - Protocol: `HTTP`
   - Port: `3000` (should be 3000, not 80)
   - Path: `/api/health` (should match your endpoint)

### Step 2: Check Target Health Details

**AWS Console:**
1. **EC2** → **Target Groups** → Your target group
2. **Targets** tab
3. Click on unhealthy target
4. **Check "Reason" field:**
   - "Health checks failed" → Security group or wrong path/port
   - "Request timeout" → Backend too slow or security group
   - "Connection refused" → Backend not running or wrong port
   - "HTTP 404" → Wrong path

### Step 3: Verify Security Groups

**Check ALB can reach instances:**
1. **EC2** → **Load Balancers** → Your ALB
2. **Security** tab → Note Security Group ID
3. **EC2** → **Instances** → Your instance
4. **Security** tab → Security Group → **Inbound rules**
5. **Verify:** Rule allowing port 3000 from ALB Security Group

---

## 🚀 Quick Fix Checklist

**Run through this checklist:**

- [ ] **Health check port is 3000** (not 80)
- [ ] **Health check path is `/api/health`** (matches your endpoint)
- [ ] **Health check protocol is HTTP** (not HTTPS)
- [ ] **Security group allows port 3000 from ALB**
- [ ] **Backend is running** (`pm2 status` shows online)
- [ ] **Health endpoint works locally** (`curl http://localhost:3000/api/health`)

**If all checked:** Wait 1-2 minutes, targets should become healthy! ✅

---

## 📋 AWS CLI Commands

### Check Health Check Configuration

```bash
# Get Target Group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
  --names easy-basket-backend \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Check health check settings
aws elbv2 describe-target-groups \
  --target-group-arns $TG_ARN \
  --query 'TargetGroups[0].HealthCheckPath' \
  --output text

# Should return: /api/health

aws elbv2 describe-target-groups \
  --target-group-arns $TG_ARN \
  --query 'TargetGroups[0].HealthCheckPort' \
  --output text

# Should return: 3000
```

### Check Target Health

```bash
# Get detailed health status
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason,TargetHealth.Description]' \
  --output table
```

### Update Health Check

```bash
# Update health check port
aws elbv2 modify-target-group \
  --target-group-arn $TG_ARN \
  --health-check-port 3000

# Update health check path
aws elbv2 modify-target-group \
  --target-group-arn $TG_ARN \
  --health-check-path /api/health
```

---

## 🎯 Most Likely Fix

**Since your endpoint works via domain, but targets are unhealthy:**

**90% chance it's one of these:**

1. **Health check port is 80 instead of 3000**
   - Fix: Update Target Group health check port to 3000

2. **Security group not allowing ALB → Instance**
   - Fix: Add inbound rule on instance security group (port 3000 from ALB SG)

3. **Health check path is wrong**
   - Fix: Update Target Group health check path to `/api/health`

**Check the "Reason" field in Target Group → Targets → Unhealthy target to see exact error!**

---

## ✅ Next Steps

1. **Check Target Group health check settings** (port 3000, path `/api/health`)
2. **Check security groups** (allow port 3000 from ALB)
3. **Check target health details** (see exact error reason)
4. **Fix the issue** based on error reason
5. **Wait 1-2 minutes** for health checks to pass
6. **Verify targets become healthy** ✅

**Your endpoint works, so it's just a configuration issue!** 🔧

