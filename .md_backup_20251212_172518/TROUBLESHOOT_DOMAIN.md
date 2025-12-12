# 🔧 Troubleshooting: api.easybasket.in Not Responding

Step-by-step troubleshooting guide when your domain is not responding.

---

## 🔍 Step 1: Check DNS Resolution

### From Your Local Machine:

```bash
# Check if DNS resolves to your EC2 IP
ping api.easybasket.in

# Or use nslookup
nslookup api.easybasket.in

# Should show: 13.60.76.140
```

**If DNS not working:**
- Wait longer (can take up to 48 hours, usually 15-30 min)
- Double-check GoDaddy DNS settings
- Verify A record is correct: `api` → `13.60.76.140`

**Online Check:**
- Go to: https://dnschecker.org
- Enter: `api.easybasket.in`
- Check if it shows: `13.60.76.140`

---

## 🔍 Step 2: Check if Backend is Running

### SSH to EC2:

```bash
ssh -i your-key.pem ec2-user@13.60.76.140
```

### Check PM2 Status:

```bash
pm2 status
```

**Should show:** `easy-basket-api` is `online`

**If not running:**
```bash
cd ~/easy-basket/backend
pm2 restart easy-basket-api
pm2 logs easy-basket-api --lines 50
```

### Test Backend Locally on EC2:

```bash
curl http://localhost:3000/api/health
```

**Should return:** JSON response

**If not working:**
- Check backend logs: `pm2 logs easy-basket-api`
- Check if port 3000 is listening: `netstat -tuln | grep 3000`

---

## 🔍 Step 3: Check Nginx Status

### On EC2:

```bash
# Check if Nginx is running
sudo systemctl status nginx

# Should show: active (running)
```

**If not running:**
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Check Nginx Configuration:

```bash
# Test configuration
sudo nginx -t

# Should show: syntax is ok, test is successful
```

**If error:**
- Check the config file: `sudo cat /etc/nginx/conf.d/easy-basket.conf`
- Verify `server_name api.easybasket.in;` is correct

### Check Nginx Logs:

```bash
# Error logs
sudo tail -f /var/log/nginx/easy-basket-error.log

# Access logs
sudo tail -f /var/log/nginx/easy-basket-access.log
```

---

## 🔍 Step 4: Check Security Group (AWS)

### In AWS Console:

1. **EC2** → **Instances** → Select your instance
2. **Security** tab → **Security groups**
3. **Inbound rules** should have:
   - **Type:** HTTP
   - **Port:** 80
   - **Source:** 0.0.0.0/0 (or your IP)

**If missing:**
- **Edit inbound rules** → **Add rule**
- **Type:** HTTP (port 80)
- **Source:** 0.0.0.0/0
- **Save**

---

## 🔍 Step 5: Test from EC2

### Test Domain from EC2:

```bash
# Test domain
curl http://api.easybasket.in/api/health

# Test IP directly
curl http://13.60.76.140/api/health

# Test localhost
curl http://localhost:3000/api/health
```

**Compare results:**
- If IP works but domain doesn't → DNS issue
- If localhost works but IP doesn't → Security group issue
- If nothing works → Backend issue

---

## 🔍 Step 6: Verify Nginx Configuration

### Check Current Config:

```bash
sudo cat /etc/nginx/conf.d/easy-basket.conf
```

**Should have:**
```nginx
server {
    listen 80;
    server_name api.easybasket.in;  # Your domain
    
    location / {
        proxy_pass http://localhost:3000;
        # ... rest of config
    }
}
```

**If wrong:**
```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Update server_name to: api.easybasket.in
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔍 Step 7: Check Firewall (if any)

### On EC2:

```bash
# Check if firewall is blocking
sudo firewall-cmd --list-all

# If firewall is active, allow HTTP
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

---

## 🔍 Step 8: Test with Different Methods

### Test 1: Direct IP

```bash
curl http://13.60.76.140/api/health
```

**If this works:** Domain/DNS issue

### Test 2: Domain with Host Header

```bash
curl -H "Host: api.easybasket.in" http://13.60.76.140/api/health
```

**If this works:** DNS issue, but Nginx config is correct

### Test 3: From Browser

Open: `http://api.easybasket.in/api/health`

**Check browser console** for errors

---

## 🔍 Step 9: Common Issues & Fixes

### Issue 1: DNS Not Propagated

**Symptom:** `ping api.easybasket.in` doesn't show your IP

**Fix:**
- Wait 15-30 more minutes
- Check GoDaddy DNS settings
- Verify A record: `api` → `13.60.76.140`

### Issue 2: Nginx Not Running

**Symptom:** `sudo systemctl status nginx` shows inactive

**Fix:**
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Issue 3: Backend Not Running

**Symptom:** `pm2 status` shows backend offline

**Fix:**
```bash
cd ~/easy-basket/backend
pm2 restart easy-basket-api
pm2 logs easy-basket-api
```

### Issue 4: Wrong server_name

**Symptom:** Nginx returns default page or 404

**Fix:**
```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Change server_name to: api.easybasket.in
sudo nginx -t
sudo systemctl reload nginx
```

### Issue 5: Security Group Blocking

**Symptom:** IP works locally but not from outside

**Fix:**
- AWS Console → EC2 → Security Groups
- Add inbound rule: HTTP (port 80) from 0.0.0.0/0

### Issue 6: Port 3000 Not Listening

**Symptom:** Backend not accessible

**Fix:**
```bash
# Check if port is listening
netstat -tuln | grep 3000

# If not, restart backend
pm2 restart easy-basket-api
```

---

## 🔍 Step 10: Complete Diagnostic

### Run All Checks:

```bash
# On EC2, run these commands:

# 1. Check DNS
nslookup api.easybasket.in

# 2. Check backend
pm2 status
curl http://localhost:3000/api/health

# 3. Check Nginx
sudo systemctl status nginx
sudo nginx -t

# 4. Check config
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

# 5. Test locally
curl http://localhost/api/health

# 6. Test domain
curl http://api.easybasket.in/api/health

# 7. Check logs
sudo tail -20 /var/log/nginx/easy-basket-error.log
pm2 logs easy-basket-api --lines 20
```

---

## 📋 Quick Fix Checklist

- [ ] DNS resolves to 13.60.76.140? (`ping api.easybasket.in`)
- [ ] Backend running? (`pm2 status`)
- [ ] Backend accessible? (`curl http://localhost:3000/api/health`)
- [ ] Nginx running? (`sudo systemctl status nginx`)
- [ ] Nginx config correct? (`sudo nginx -t`)
- [ ] server_name is `api.easybasket.in`? (`sudo cat /etc/nginx/conf.d/easy-basket.conf`)
- [ ] Security group allows port 80? (AWS Console)
- [ ] Test from EC2: `curl http://api.easybasket.in/api/health`

---

## 🎯 Most Common Fix

**90% of the time, it's one of these:**

1. **DNS not propagated** → Wait 15-30 minutes
2. **Nginx server_name wrong** → Update to `api.easybasket.in`
3. **Security group blocking** → Add HTTP rule (port 80)
4. **Backend not running** → `pm2 restart easy-basket-api`

---

**Run through these steps and let me know what you find! 🔍**

