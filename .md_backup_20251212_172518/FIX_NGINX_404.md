# 🔧 Fix Nginx 404 Error

Nginx is running but showing 404. This means the configuration isn't being loaded correctly.

---

## 🔍 Step 1: Check if Config File Exists

```bash
# Check if config file exists
ls -la /etc/nginx/conf.d/easy-basket.conf

# View the file
sudo cat /etc/nginx/conf.d/easy-basket.conf
```

**If file doesn't exist, create it.**

---

## 🔧 Step 2: Create/Update Nginx Config

### Create the config file:

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

### Paste this complete configuration:

```nginx
server {
    listen 80;
    server_name api.easybasket.in localhost 13.60.76.140;

    access_log /var/log/nginx/easy-basket-access.log;
    error_log /var/log/nginx/easy-basket-error.log;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://localhost:3000/api/health;
        access_log off;
    }
}
```

**Save:** `Ctrl+X`, then `Y`, then `Enter`

---

## 🔍 Step 3: Verify Main Nginx Config Includes conf.d

```bash
# Check main nginx.conf
sudo cat /etc/nginx/nginx.conf | grep include
```

**Should show:**
```
include /etc/nginx/conf.d/*.conf;
```

**If not present, add it:**

```bash
sudo nano /etc/nginx/nginx.conf
```

**Find the `http` block and add:**
```nginx
http {
    # ... existing config ...
    
    include /etc/nginx/conf.d/*.conf;  # Add this line
    
    # ... rest of config ...
}
```

---

## 🧪 Step 4: Test and Reload Nginx

```bash
# Test configuration
sudo nginx -t

# Should show: syntax is ok, test is successful

# Reload Nginx
sudo systemctl reload nginx

# Or restart if reload doesn't work
sudo systemctl restart nginx
```

---

## 🧪 Step 5: Test Again

```bash
# Test backend directly (should work)
curl http://localhost:3000/api/health

# Test through Nginx (should now work)
curl http://localhost/api/health

# Test domain
curl http://api.easybasket.in/api/health
```

**All should return JSON now!**

---

## 🔍 Step 6: Check Nginx Logs (if still not working)

```bash
# Check error logs
sudo tail -f /var/log/nginx/easy-basket-error.log

# Check access logs
sudo tail -f /var/log/nginx/easy-basket-access.log

# Check main error log
sudo tail -f /var/log/nginx/error.log
```

---

## 🐛 Common Issues

### Issue 1: Config File Not in Right Location

**Fix:**
```bash
# Make sure file is in conf.d directory
sudo cp /tmp/easy-basket.conf /etc/nginx/conf.d/easy-basket.conf
sudo chmod 644 /etc/nginx/conf.d/easy-basket.conf
```

### Issue 2: Default Server Block Taking Over

**Check:**
```bash
# Check for default server
ls -la /etc/nginx/conf.d/

# If there's a default.conf, either:
# Option A: Remove it
sudo rm /etc/nginx/conf.d/default.conf

# Option B: Or make sure your config has higher priority
# (server_name should match your domain)
```

### Issue 3: Backend Not Running

**Check:**
```bash
pm2 status
curl http://localhost:3000/api/health
```

**If backend not running:**
```bash
cd ~/easy-basket/backend
npm run build
pm2 start dist/index.js --name easy-basket-api
```

---

## 📋 Complete Fix Sequence

```bash
# 1. Create config file
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Paste the config above, save

# 2. Verify main config includes conf.d
sudo cat /etc/nginx/nginx.conf | grep "include.*conf.d"

# 3. Test and reload
sudo nginx -t
sudo systemctl reload nginx

# 4. Test endpoints
curl http://localhost:3000/api/health
curl http://localhost/api/health
curl http://api.easybasket.in/api/health
```

---

## ✅ Verification

After fixing, all these should work:

```bash
# Backend directly
curl http://localhost:3000/api/health
# ✅ JSON response

# Through Nginx
curl http://localhost/api/health
# ✅ JSON response

# Via domain
curl http://api.easybasket.in/api/health
# ✅ JSON response
```

---

**After creating/updating the config file, the 404 should be fixed! 🚀**

