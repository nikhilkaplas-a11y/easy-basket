# ALB Setup - Quick Checklist

## ✅ Pre-requisites (You Have These)
- [x] PM2 Cluster Mode enabled
- [x] Second EC2 instance created
- [x] Target Group created
- [x] Application Load Balancer created

---

## 📋 Step-by-Step Checklist

### Step 1: Register Instances to Target Group

**AWS Console:**
- [ ] Go to **EC2** → **Target Groups** → Select your target group
- [ ] Click **"Register targets"** tab
- [ ] Select **Instance 1** ✅
- [ ] Select **Instance 2** ✅
- [ ] Port: `3000`
- [ ] Click **"Register pending targets"**
- [ ] Wait 1-2 minutes
- [ ] Verify both show **"Healthy"** status

**Time:** 2 minutes

---

### Step 2: Configure ALB Listeners

#### HTTP Listener (Port 80)
- [ ] **Load Balancers** → Your ALB → **Listeners** tab
- [ ] Click **"Add listener"** (if doesn't exist)
- [ ] Protocol: **HTTP**
- [ ] Port: **80**
- [ ] Default action: **Redirect to HTTPS**
- [ ] Status code: **301**
- [ ] Port: **443**
- [ ] Click **"Save"**

#### HTTPS Listener (Port 443)
- [ ] Click **"Add listener"** (if doesn't exist)
- [ ] Protocol: **HTTPS**
- [ ] Port: **443**
- [ ] SSL Certificate: Select certificate for `api.easybasket.in`
- [ ] Default action: **Forward to**
- [ ] Target group: Select `easy-basket-backend`
- [ ] Click **"Save"**

**Time:** 3 minutes

---

### Step 3: Configure Security Groups

#### ALB Security Group
- [ ] **EC2** → **Security Groups** → ALB security group
- [ ] **Inbound rules:**
  - [ ] Port **80** from `0.0.0.0/0` ✅
  - [ ] Port **443** from `0.0.0.0/0` ✅
- [ ] **Outbound rules:**
  - [ ] All traffic to `0.0.0.0/0` ✅

#### Instance Security Group
- [ ] **EC2** → **Security Groups** → Instance security group
- [ ] **Inbound rules:**
  - [ ] Port **3000** from ALB security group ✅
  - [ ] Port **22** from your IP (SSH) ✅

**Time:** 2 minutes

---

### Step 4: Update DNS

- [ ] Get ALB DNS name from AWS Console
- [ ] Login to **GoDaddy** → **DNS Management**
- [ ] Find `api` record
- [ ] **Delete A record** (if exists)
- [ ] **Add/Update CNAME:**
  - Type: **CNAME**
  - Name: `api`
  - Value: `<alb-dns-name>`
  - TTL: **3600**
- [ ] **Save**
- [ ] Wait 5-10 minutes for propagation

**Time:** 5 minutes

---

### Step 5: Test Everything

- [ ] Test Target Group health:
  ```bash
  # Both should show "Healthy"
  aws elbv2 describe-target-health --target-group-arn <arn>
  ```

- [ ] Test HTTP redirect:
  ```bash
  curl -I http://api.easybasket.in/api/health
  # Should return: 301 Moved Permanently
  ```

- [ ] Test HTTPS:
  ```bash
  curl https://api.easybasket.in/api/health
  # Should return: {"status":"ok",...}
  ```

- [ ] Test from browser:
  - [ ] Open: `https://api.easybasket.in/api/health`
  - [ ] Should see JSON response

**Time:** 2 minutes

---

### Step 6: Test Failover

- [ ] Stop Instance 1 in AWS Console
- [ ] Wait 60 seconds
- [ ] Test API: `curl https://api.easybasket.in/api/health`
- [ ] Should still work (Instance 2 handling traffic)
- [ ] Check Target Group: Instance 1 = Unhealthy, Instance 2 = Healthy
- [ ] Start Instance 1 again
- [ ] Wait 60 seconds
- [ ] Both should be Healthy again

**Time:** 3 minutes

---

## 🎯 Total Time: ~15 minutes

---

## 🚨 Common Issues & Quick Fixes

### Targets Unhealthy
```bash
# SSH into instance
ssh -i key.pem ec2-user@<ip>

# Check backend
curl http://localhost:3000/api/health
pm2 status

# Fix: Restart if needed
pm2 restart ecosystem.config.js
```

### 502 Bad Gateway
- Check security groups allow ALB → Instance (port 3000)
- Check backend is running: `pm2 status`
- Check health check path: `/api/health`

### DNS Not Working
- Wait 10-15 minutes
- Verify CNAME record in GoDaddy
- Test: `dig api.easybasket.in`

---

## ✅ Final Verification

- [ ] Both instances in Target Group = **Healthy**
- [ ] ALB listeners configured (HTTP + HTTPS)
- [ ] Security groups allow traffic
- [ ] DNS points to ALB
- [ ] `https://api.easybasket.in/api/health` works
- [ ] Failover tested and working

**You're done!** 🎉

