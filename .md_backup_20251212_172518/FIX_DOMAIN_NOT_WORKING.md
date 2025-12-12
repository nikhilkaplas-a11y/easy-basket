# 🔧 Fix: api.easybasket.in Not Working

Complete step-by-step guide to fix domain access.

---

## 🔍 Step 1: Run Complete Diagnostic

**Run these commands on EC2 and share the output:**

```bash
echo "=== 1. Test locally on EC2 ==="
curl -s http://localhost/api/health | head -3

echo "=== 2. Test via IP ==="
curl -s http://13.60.76.140/api/health | head -3

echo "=== 3. Test via domain from EC2 ==="
curl -s http://api.easybasket.in/api/health | head -3

echo "=== 4. Check DNS resolution ==="
nslookup api.easybasket.in

echo "=== 5. Check Nginx is listening ==="
sudo netstat -tuln | grep :80

echo "=== 6. Check Nginx config ==="
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

echo "=== 7. Check Nginx error logs ==="
sudo tail -10 /var/log/nginx/easy-basket-error.log
```

**Share ALL output.**

---

## 🔍 Step 2: Check DNS Resolution

### From Your Local Machine:

```bash
# Check if domain resolves
nslookup api.easybasket.in

# Or
ping api.easybasket.in
```

**Should show:** `13.60.76.140`

**If not showing your IP:**
- DNS not fully propagated (wait 15-30 more minutes)
- Check GoDaddy DNS settings
- Verify A record: `api` → `13.60.76.140`

---

## 🔍 Step 3: Check Security Group

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Security** tab → **Security groups**
3. **Inbound rules** should have:
   - **Type:** HTTP
   - **Port:** 80
   - **Source:** `0.0.0.0/0`

**If missing, add it:**
- **Edit inbound rules** → **Add rule**
- **Type:** HTTP (port 80)
- **Source:** `0.0.0.0/0`
- **Save**

---

## 🔍 Step 4: Check Nginx is Listening on All Interfaces

### On EC2:

```bash
# Check what Nginx is listening on
sudo netstat -tuln | grep :80
```

**Should show:**
```
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN
```

**If it shows `127.0.0.1:80` instead, that's the problem!**

---

## 🔧 Step 5: Verify Nginx Config

### On EC2:

```bash
# Check your config
sudo cat /etc/nginx/conf.d/easy-basket.conf
```

**Should have:**
```nginx
server {
    listen 80 default_server;
    server_name api.easybasket.in localhost 13.60.76.140 _;
    # ... rest of config
}
```

**If `server_name` doesn't include your domain, update it:**

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Change to:**
```nginx
server {
    listen 80 default_server;
    server_name api.easybasket.in localhost 13.60.76.140 _;
    
    # ... rest of config
}
```

**Save and reload:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔧 Step 6: Check Firewall

### On EC2:

```bash
# Check if firewall is blocking
sudo firewall-cmd --list-all 2>/dev/null || echo "Firewall not active or not firewalld"

# If firewall is active, allow HTTP
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

---

## 🔧 Step 7: Test from Different Locations

### From EC2:
```bash
curl http://api.easybasket.in/api/health
```

### From Your Local Machine:
```bash
curl http://api.easybasket.in/api/health
```

### Test IP Directly:
```bash
curl http://13.60.76.140/api/health
```

**Compare results:**
- If IP works but domain doesn't → DNS issue
- If localhost works but IP doesn't → Security group issue
- If nothing works externally → Security group or firewall

---

## 🔧 Step 8: Complete Fix Sequence

### If DNS is the issue:

1. **Check GoDaddy DNS:**
   - Log in to GoDaddy
   - Go to DNS Management
   - Verify A record: `api` → `13.60.76.140`
   - TTL: 300 or 3600

2. **Wait for propagation:**
   - Can take 15 minutes to 48 hours
   - Usually 15-30 minutes

3. **Check propagation:**
   ```bash
   # From your local machine
   nslookup api.easybasket.in
   ```

### If Security Group is the issue:

1. **AWS Console** → **EC2** → **Security Groups**
2. **Select your security group**
3. **Inbound rules** → **Edit inbound rules**
4. **Add rule:**
   - **Type:** HTTP
   - **Port:** 80
   - **Source:** `0.0.0.0/0`
5. **Save**

### If Nginx config is the issue:

```bash
# Update config to include domain
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Ensure:**
```nginx
server {
    listen 80 default_server;
    server_name api.easybasket.in localhost 13.60.76.140 _;
    # ... rest
}
```

**Test and reload:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔧 Step 9: Complete Diagnostic Script

**Run this on EC2:**

```bash
#!/bin/bash

echo "=== COMPLETE DIAGNOSTIC ==="
echo ""

echo "1. Backend status:"
pm2 status | grep easy-basket-api
echo ""

echo "2. Backend test (localhost:3000):"
curl -s http://localhost:3000/api/health | head -1
echo ""

echo "3. Nginx test (localhost:80):"
curl -s http://localhost/api/health | head -1
echo ""

echo "4. IP test (13.60.76.140):"
curl -s http://13.60.76.140/api/health | head -1
echo ""

echo "5. Domain test from EC2:"
curl -s http://api.easybasket.in/api/health | head -1
echo ""

echo "6. DNS resolution:"
nslookup api.easybasket.in | grep -A 2 "Name:"
echo ""

echo "7. Nginx listening:"
sudo netstat -tuln | grep :80
echo ""

echo "8. Nginx config server_name:"
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name
echo ""

echo "9. Recent Nginx errors:"
sudo tail -5 /var/log/nginx/easy-basket-error.log 2>/dev/null || echo "No errors"
echo ""
```

**Save as `diagnose-domain.sh`, make executable, and run:**
```bash
chmod +x diagnose-domain.sh
./diagnose-domain.sh
```

**Share the complete output.**

---

## 🎯 Most Common Issues & Fixes

### Issue 1: DNS Not Propagated

**Symptom:** Domain doesn't resolve to your IP

**Fix:**
- Wait 15-30 minutes
- Check GoDaddy DNS settings
- Verify A record is correct

### Issue 2: Security Group Blocking

**Symptom:** IP works locally but not from outside

**Fix:**
- AWS Console → Security Groups
- Add inbound rule: HTTP (port 80) from 0.0.0.0/0

### Issue 3: Nginx Not Listening on All Interfaces

**Symptom:** `netstat` shows `127.0.0.1:80` instead of `0.0.0.0:80`

**Fix:**
- Check Nginx config has `listen 80;` (not `listen 127.0.0.1:80;`)
- Restart Nginx: `sudo systemctl restart nginx`

### Issue 4: Firewall Blocking

**Symptom:** Everything works locally but not externally

**Fix:**
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

---

## ✅ Verification Checklist

- [ ] DNS resolves to 13.60.76.140 (`nslookup api.easybasket.in`)
- [ ] Security group allows HTTP (port 80) from 0.0.0.0/0
- [ ] Nginx listening on 0.0.0.0:80 (`netstat -tuln | grep :80`)
- [ ] Nginx config includes domain in server_name
- [ ] Backend running (`pm2 status`)
- [ ] `curl http://localhost/api/health` works
- [ ] `curl http://13.60.76.140/api/health` works
- [ ] `curl http://api.easybasket.in/api/health` works

---

## 📋 Quick Fix Sequence

```bash
# 1. Verify backend
pm2 status
curl http://localhost:3000/api/health

# 2. Verify Nginx locally
curl http://localhost/api/health

# 3. Check Nginx config
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

# 4. Update config if needed
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Ensure: server_name api.easybasket.in localhost 13.60.76.140 _;

# 5. Test and reload
sudo nginx -t
sudo systemctl reload nginx

# 6. Check listening
sudo netstat -tuln | grep :80

# 7. Test from EC2
curl http://api.easybasket.in/api/health

# 8. Test from local machine
curl http://api.easybasket.in/api/health
```

---

**Run Step 1 diagnostic first and share the output, then we'll fix it! 🔍**

