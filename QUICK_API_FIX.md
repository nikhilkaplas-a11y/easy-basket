# Quick Fix: API Health Endpoint Not Working

## 🔍 Issue Found

- ✅ HTTP works (301 redirect to HTTPS) - **This is correct!**
- ⚠️ HTTPS connects but may be hanging - **Backend might not be responding**

## 🚀 Quick Fixes

### Fix 1: Use HTTPS Instead of HTTP

**The issue:** You're using HTTP, which redirects to HTTPS. Use HTTPS directly:

```bash
# ✅ Correct - Use HTTPS
curl https://api.easybasket.in/api/health

# ❌ Wrong - HTTP redirects (this is expected)
curl http://api.easybasket.in/api/health
```

### Fix 2: Check Backend on EC2 Instances

**SSH into both instances and check:**

```bash
# SSH into instance
ssh -i your-key.pem ec2-user@<instance-ip>

# Check PM2 status
pm2 status

# Should show:
# ┌─────┬─────────────┬─────────┬─────────┬──────────┐
# │ id  │ name        │ status  │ cpu     │ memory   │
# ├─────┼─────────────┼─────────┼─────────┼─────────┤
# │ 0   │ easy-basket │ online  │ 0%      │ 50 MB    │
# └─────┴─────────────┴─────────┴─────────┴─────────┘

# If not running, restart:
cd /path/to/backend
pm2 restart easy-basket-api

# Test locally
curl http://localhost:3000/api/health
# Should return: {"status":"ok","message":"Easy Basket API is running"}
```

### Fix 3: Check Target Group Health

**AWS Console:**
1. **EC2** → **Target Groups** → `easy-basket-backend`
2. **Targets** tab
3. **Check status:**
   - ✅ **Healthy** = Good
   - ❌ **Unhealthy** = Problem

**If unhealthy:**
- Check security groups allow port 3000 from ALB
- Check backend is running on instances
- Check health check path is `/api/health`

### Fix 4: Restart Backend on Both Instances

**Instance 1:**
```bash
ssh -i your-key.pem ec2-user@<instance-1-ip>
cd /path/to/backend
pm2 restart easy-basket-api
pm2 logs easy-basket-api --lines 20
```

**Instance 2:**
```bash
ssh -i your-key.pem ec2-user@<instance-2-ip>
cd /path/to/backend
pm2 restart easy-basket-api
pm2 logs easy-basket-api --lines 20
```

## ✅ Test After Fix

```bash
# Test HTTPS (correct way)
curl https://api.easybasket.in/api/health

# Expected response:
# {"status":"ok","message":"Easy Basket API is running"}
```

## 📋 Quick Checklist

- [ ] Use **HTTPS** instead of HTTP
- [ ] Backend running on **both instances** (PM2 status)
- [ ] Targets show **Healthy** in Target Group
- [ ] Security groups allow **port 3000** from ALB
- [ ] Health endpoint works **locally** on instances

## 🎯 Most Likely Issue

**Backend not running on one or both instances**

**Quick fix:**
```bash
# SSH and restart
pm2 restart easy-basket-api
```

**Then test:**
```bash
curl https://api.easybasket.in/api/health
```

