# ✅ Verify Domain Setup: api.easybasket.in

Your security group is correctly configured! Now let's verify everything else.

---

## ✅ Step 1: Security Group - DONE ✓

Your security group has:
- ✅ Port 80 (HTTP) - Open
- ✅ Port 443 (HTTPS) - Open  
- ✅ Port 22 (SSH) - Open

---

## 🔍 Step 2: Check Nginx Configuration

### On EC2, run:

```bash
# Check if server_name is set correctly
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name
```

**Should show:**
```
server_name api.easybasket.in;
```

**If it shows something else (like `_` or IP), update it:**
```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Change server_name to: api.easybasket.in
# Save: Ctrl+X, Y, Enter

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔍 Step 3: Check Backend is Running

### On EC2:

```bash
# Check PM2 status
pm2 status

# Should show easy-basket-api as "online"

# Test backend locally
curl http://localhost:3000/api/health
```

**Should return JSON:**
```json
{
  "status": "ok",
  "message": "Easy Basket Backend is running",
  "timestamp": "..."
}
```

**If not working:**
```bash
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
```

---

## 🔍 Step 4: Test Nginx Proxy

### On EC2:

```bash
# Test through Nginx (port 80)
curl http://localhost/api/health

# Should return the same JSON as above
```

**If this doesn't work:**
- Check Nginx config: `sudo nginx -t`
- Check Nginx logs: `sudo tail -f /var/log/nginx/easy-basket-error.log`

---

## 🔍 Step 5: Test Domain from EC2

### On EC2:

```bash
# Test domain
curl http://api.easybasket.in/api/health
```

**Should return JSON response**

**If it doesn't work:**
- DNS might not be fully propagated
- Check Nginx server_name is correct
- Check Nginx logs

---

## 🔍 Step 6: Test Domain from Your Local Machine

### From your Mac:

```bash
# Test domain
curl http://api.easybasket.in/api/health
```

**Should return JSON response**

**Or test in browser:**
```
http://api.easybasket.in/api/health
```

---

## 📋 Complete Verification Checklist

Run these commands on EC2:

```bash
# 1. Check Nginx config
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

# 2. Check backend
pm2 status
curl http://localhost:3000/api/health

# 3. Test Nginx proxy
curl http://localhost/api/health

# 4. Test domain
curl http://api.easybasket.in/api/health

# 5. Check Nginx logs (if issues)
sudo tail -20 /var/log/nginx/easy-basket-error.log
```

---

## 🐛 Common Issues

### Issue 1: Nginx server_name Wrong

**Symptom:** Domain doesn't work, but IP does

**Fix:**
```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Change: server_name api.easybasket.in;
sudo nginx -t
sudo systemctl reload nginx
```

### Issue 2: Backend Not Running

**Symptom:** `curl http://localhost:3000/api/health` fails

**Fix:**
```bash
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
```

### Issue 3: Nginx Not Proxying

**Symptom:** `curl http://localhost/api/health` fails

**Fix:**
- Check Nginx config: `sudo nginx -t`
- Check logs: `sudo tail -f /var/log/nginx/easy-basket-error.log`
- Verify proxy_pass is correct: `sudo cat /etc/nginx/conf.d/easy-basket.conf`

---

## ✅ Expected Results

### All these should work:

1. **Backend directly:**
   ```bash
   curl http://localhost:3000/api/health
   # ✅ Returns JSON
   ```

2. **Through Nginx:**
   ```bash
   curl http://localhost/api/health
   # ✅ Returns JSON
   ```

3. **Via domain (from EC2):**
   ```bash
   curl http://api.easybasket.in/api/health
   # ✅ Returns JSON
   ```

4. **Via domain (from your Mac):**
   ```bash
   curl http://api.easybasket.in/api/health
   # ✅ Returns JSON
   ```

---

## 🎯 Quick Test Sequence

Run these in order on EC2:

```bash
# 1. Verify Nginx config
echo "=== Nginx server_name ==="
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

# 2. Check backend
echo "=== PM2 Status ==="
pm2 status

# 3. Test backend
echo "=== Backend Test ==="
curl http://localhost:3000/api/health

# 4. Test Nginx
echo "=== Nginx Test ==="
curl http://localhost/api/health

# 5. Test domain
echo "=== Domain Test ==="
curl http://api.easybasket.in/api/health
```

**All should return JSON responses!**

---

**Run these checks and let me know what you find! 🔍**

