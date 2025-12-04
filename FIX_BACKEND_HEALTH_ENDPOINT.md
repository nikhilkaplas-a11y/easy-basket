# 🔧 Fix: Cannot GET /api/health

The backend code has the `/api/health` endpoint, but it's not available. This means the backend needs to be restarted or rebuilt.

---

## 🔍 Step 1: Check Current Backend Status

### On EC2:

```bash
# Check PM2 status
pm2 status

# Check PM2 logs
pm2 logs easy-basket-api --lines 50
```

---

## 🔧 Step 2: Restart Backend

### Option A: Simple Restart (if code is already built)

```bash
cd ~/easy-basket/backend
pm2 restart easy-basket-api
pm2 logs easy-basket-api --lines 20
```

### Option B: Rebuild and Restart (recommended)

```bash
cd ~/easy-basket/backend

# Pull latest code (if using git)
git pull

# Install dependencies (if needed)
npm install

# Rebuild TypeScript
npm run build

# Restart PM2
pm2 restart easy-basket-api

# Check logs
pm2 logs easy-basket-api --lines 30
```

---

## 🧪 Step 3: Test After Restart

```bash
# Test root endpoint
curl http://localhost:3000/

# Should show: "Easy Basket Backend is running"

# Test health endpoint
curl http://localhost:3000/api/health

# Should show JSON:
# {
#   "status": "ok",
#   "message": "Easy Basket Backend is running",
#   "timestamp": "..."
# }
```

---

## 🔍 Step 4: Verify Backend is Running Latest Code

### Check if endpoint exists:

```bash
# Check if server is listening
netstat -tuln | grep 3000

# Check PM2 process
pm2 describe easy-basket-api

# Check what file PM2 is running
pm2 show easy-basket-api | grep script
```

**Should show:** `dist/index.js` (compiled TypeScript)

---

## 🔧 Step 5: If Still Not Working - Full Rebuild

```bash
cd ~/easy-basket/backend

# Stop PM2
pm2 stop easy-basket-api
pm2 delete easy-basket-api

# Clean and rebuild
rm -rf dist
npm run build

# Start fresh
pm2 start dist/index.js --name easy-basket-api
pm2 save

# Check logs
pm2 logs easy-basket-api --lines 30
```

---

## 🧪 Step 6: Test All Endpoints

```bash
# Root endpoint
curl http://localhost:3000/

# Health endpoint
curl http://localhost:3000/api/health

# Categories (should work without auth)
curl http://localhost:3000/api/categories
```

---

## 🐛 Common Issues

### Issue 1: Backend Running Old Code

**Symptom:** Endpoint doesn't exist

**Fix:**
```bash
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
```

### Issue 2: Database Connection Error

**Symptom:** Backend crashes on startup

**Fix:**
- Check `.env` file: `cat ~/easy-basket/backend/.env`
- Verify database credentials
- Check RDS security group allows EC2 IP

### Issue 3: Port Already in Use

**Symptom:** "Port 3000 already in use"

**Fix:**
```bash
# Find process using port 3000
sudo lsof -i :3000

# Kill it
sudo kill -9 <PID>

# Restart PM2
pm2 restart easy-basket-api
```

---

## ✅ Verification Checklist

- [ ] Backend restarted: `pm2 restart easy-basket-api`
- [ ] Code rebuilt: `npm run build`
- [ ] Root endpoint works: `curl http://localhost:3000/`
- [ ] Health endpoint works: `curl http://localhost:3000/api/health`
- [ ] PM2 logs show no errors
- [ ] Database connected (check logs)

---

## 📋 Quick Fix Command

```bash
cd ~/easy-basket/backend && npm run build && pm2 restart easy-basket-api && sleep 2 && curl http://localhost:3000/api/health
```

This will:
1. Rebuild the backend
2. Restart PM2
3. Wait 2 seconds
4. Test the health endpoint

---

**After restarting, the `/api/health` endpoint should work! 🚀**

