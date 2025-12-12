# 🔧 Fix API Not Running on EC2

## ❌ Error: API Not Responding

If `curl http://13.60.76.140:3000/api/health` is not working, check these:

---

## 🔍 Step 1: Check if Server is Running

### On EC2:

```bash
# Check PM2 status
pm2 status

# Should show: easy-basket-api | online
# If shows: stopped or errored, restart it
```

### Check if Port 3000 is Listening

```bash
# Check if port 3000 is in use
sudo lsof -i :3000

# Or
sudo netstat -tlnp | grep 3000

# Should show Node.js process listening on port 3000
```

---

## 🔍 Step 2: Check PM2 Logs

```bash
# View recent logs
pm2 logs easy-basket-api --lines 50

# Look for:
# ✅ "Database connected" - Good!
# ✅ "Server is running on port 3000" - Good!
# ❌ "Database connection error" - Fix .env
# ❌ "EADDRINUSE" - Port already in use
```

---

## 🔍 Step 3: Test Locally on EC2

```bash
# Test from EC2 itself (localhost)
curl http://localhost:3000

# Should return: "Easy Basket Backend is running"

# Test health endpoint
curl http://localhost:3000/api/health

# Should return JSON
```

**If localhost works but public IP doesn't:**
- Security group issue (see Step 4)

**If localhost doesn't work:**
- Server not running or crashed (see Step 5)

---

## 🔍 Step 4: Check Security Group

### Allow Port 3000 in Security Group

1. **AWS Console** → **EC2** → **Instances** → Select your instance
2. Click **Security** tab → Click security group
3. **Inbound rules** → **Edit inbound rules** → **Add rule:**
   - **Type:** Custom TCP
   - **Port:** 3000
   - **Source:** 
     - `0.0.0.0/0` (for testing - allows all IPs)
     - Or your specific IP (more secure)
   - **Description:** Allow API access
4. **Save rules**

### Test Again

```bash
# From your local machine
curl http://13.60.76.140:3000/api/health
```

---

## 🔍 Step 5: Check Server Configuration

### Make Sure Server Listens on 0.0.0.0

The server should listen on `0.0.0.0` (all interfaces), not just `localhost`.

**Check `backend/src/index.ts`:**

```typescript
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});
```

Or:

```typescript
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
// This defaults to 0.0.0.0 in Express
```

---

## 🔧 Step 6: Restart Server

```bash
# On EC2
cd ~/easy-basket/backend

# Rebuild (if code changed)
npm run build

# Restart PM2
pm2 restart easy-basket-api

# Check status
pm2 status

# Check logs
pm2 logs easy-basket-api --lines 20
```

---

## 🧪 Complete Test Sequence

### On EC2:

```bash
# 1. Check PM2
pm2 status

# 2. Test locally
curl http://localhost:3000

# 3. Check port
sudo lsof -i :3000

# 4. Check logs
pm2 logs easy-basket-api --lines 20
```

### From Your Local Machine:

```bash
# Test public IP
curl http://13.60.76.140:3000/api/health

# If timeout: Security group issue
# If connection refused: Server not running
# If 404: Wrong endpoint
```

---

## 🐛 Common Issues

### Issue 1: "Connection timed out"

**Cause:** Security group not allowing port 3000

**Fix:** Add inbound rule for port 3000 (see Step 4)

### Issue 2: "Connection refused"

**Cause:** Server not running or listening on wrong interface

**Fix:**
```bash
# Restart server
pm2 restart easy-basket-api

# Check if listening
sudo lsof -i :3000
```

### Issue 3: "404 Not Found"

**Cause:** Wrong endpoint URL

**Fix:** Use correct endpoints:
- `http://13.60.76.140:3000/` (root)
- `http://13.60.76.140:3000/api/health` (health)
- `http://13.60.76.140:3000/api/categories` (categories)

### Issue 4: Server Crashes on Start

**Cause:** Database connection error or other startup error

**Fix:**
```bash
# Check logs
pm2 logs easy-basket-api --lines 50

# Fix .env file (database credentials)
cd ~/easy-basket/backend
nano .env
# Update DB_USER=admin, DB_PASS=nikhilkaplas

# Rebuild and restart
npm run build
pm2 restart easy-basket-api
```

---

## ✅ Success Checklist

- [ ] PM2 shows `easy-basket-api | online`
- [ ] `curl http://localhost:3000` works on EC2
- [ ] Security group allows port 3000
- [ ] `curl http://13.60.76.140:3000/api/health` works from outside
- [ ] Logs show "Database connected" and "Server is running"

---

## 📋 Quick Fix Commands

```bash
# On EC2 - Complete restart
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
pm2 logs easy-basket-api --lines 20

# Test locally
curl http://localhost:3000/api/health

# If works locally, check security group for port 3000
```

---

**After fixing, test again! 🚀**

