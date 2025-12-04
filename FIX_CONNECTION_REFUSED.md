# 🔧 Fix: Connection Refused Error

"Connection refused" means the server is not accepting connections. Let's diagnose and fix.

---

## 🔍 Step 1: Check Backend is Running

### On EC2:

```bash
# Check PM2 status
pm2 status

# Should show easy-basket-api as "online"

# If not running, start it
cd ~/easy-basket/backend
pm2 start dist/index.js --name easy-basket-api
pm2 save
```

---

## 🔍 Step 2: Check Backend Port

### On EC2:

```bash
# Check if backend is listening on port 3000
sudo netstat -tuln | grep 3000

# Or
sudo ss -tlnp | grep 3000

# Should show: 0.0.0.0:3000 or 127.0.0.1:3000
```

**If nothing shows, backend is not running or not listening.**

---

## 🔍 Step 3: Test Backend Directly

### On EC2:

```bash
# Test backend directly
curl http://localhost:3000/api/health

# Should return JSON
```

**If this fails, backend is not running or crashed.**

---

## 🔍 Step 4: Check Backend Logs

### On EC2:

```bash
# Check PM2 logs
pm2 logs easy-basket-api --lines 50

# Look for errors:
# - Database connection errors
# - Port already in use
# - Missing dependencies
# - Configuration errors
```

---

## 🔍 Step 5: Check Nginx is Running

### On EC2:

```bash
# Check Nginx status
sudo systemctl status nginx

# Should show: active (running)

# If not running, start it
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

## 🔍 Step 6: Check Nginx is Listening

### On EC2:

```bash
# Check if Nginx is listening on port 80
sudo netstat -tuln | grep :80

# Should show: 0.0.0.0:80
```

---

## 🔍 Step 7: Test Nginx Proxy

### On EC2:

```bash
# Test through Nginx
curl http://localhost/api/health

# Should return JSON (same as backend)
```

**If this fails, Nginx is not proxying correctly.**

---

## 🔍 Step 8: Check Nginx Config

### On EC2:

```bash
# Check Nginx config
sudo cat /etc/nginx/conf.d/easy-basket.conf

# Should have:
# proxy_pass http://localhost:3000;
```

**Verify proxy_pass is correct.**

---

## 🔍 Step 9: Check Where You're Calling From

### If calling from mobile app:

**Check API URL in app:**
```dart
// mobile/lib/config/app_config.dart
static const String apiBaseUrl = 'https://api.easybasket.in/api';
// Or: 'http://api.easybasket.in/api'
```

**Make sure it's using the correct domain.**

---

## 🔧 Common Fixes

### Fix 1: Backend Not Running

```bash
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
pm2 logs easy-basket-api --lines 20
```

### Fix 2: Port 3000 Already in Use

```bash
# Find what's using port 3000
sudo lsof -i :3000

# Kill it
sudo kill -9 <PID>

# Restart backend
pm2 restart easy-basket-api
```

### Fix 3: Database Connection Error

```bash
# Check backend logs
pm2 logs easy-basket-api --lines 50

# Check .env file
cat ~/easy-basket/backend/.env | grep DB_

# Verify database credentials
```

### Fix 4: Nginx Not Running

```bash
# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

### Fix 5: Wrong API URL in App

**Check:** `mobile/lib/config/app_config.dart`

**Should be:**
```dart
static const String apiBaseUrl = 'https://api.easybasket.in/api';
// Or HTTP if SSL not set up:
// static const String apiBaseUrl = 'http://api.easybasket.in/api';
```

---

## 📋 Complete Diagnostic

**Run this on EC2:**

```bash
echo "=== 1. Backend Status ==="
pm2 status | grep easy-basket-api

echo ""
echo "=== 2. Backend Listening ==="
sudo netstat -tuln | grep 3000

echo ""
echo "=== 3. Backend Test ==="
curl -s http://localhost:3000/api/health | head -1

echo ""
echo "=== 4. Nginx Status ==="
sudo systemctl status nginx | head -5

echo ""
echo "=== 5. Nginx Listening ==="
sudo netstat -tuln | grep :80

echo ""
echo "=== 6. Nginx Test ==="
curl -s http://localhost/api/health | head -1

echo ""
echo "=== 7. Recent Backend Logs ==="
pm2 logs easy-basket-api --lines 10 --nostream
```

**Share the complete output.**

---

## 🎯 Most Likely Issues

1. **Backend not running** → `pm2 restart easy-basket-api`
2. **Backend crashed** → Check logs: `pm2 logs easy-basket-api`
3. **Port 3000 in use** → Kill process and restart
4. **Database connection error** → Check `.env` and database
5. **Wrong API URL in app** → Check `app_config.dart`

---

## ✅ Quick Fix Sequence

```bash
# 1. Check backend
pm2 status
pm2 logs easy-basket-api --lines 20

# 2. Restart if needed
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api

# 3. Check Nginx
sudo systemctl status nginx
sudo systemctl restart nginx

# 4. Test
curl http://localhost:3000/api/health
curl http://localhost/api/health
```

---

**Run the diagnostic and share the output - that will tell us exactly what's wrong! 🔍**

