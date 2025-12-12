# ✅ Fix: Update Nginx server_name

**Problem:** Your Nginx config has `server_name _;` but should include `api.easybasket.in`.

---

## 🔧 Step 1: Update Nginx Config

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Find this line:**
```nginx
    server_name _;
```

**Change it to:**
```nginx
    server_name api.easybasket.in localhost 13.60.76.140 _;
```

**Complete config should look like:**
```nginx
server {
    listen 80 default_server;
    server_name api.easybasket.in localhost 13.60.76.140 _;

    access_log /var/log/nginx/easy-basket-access.log;
    error_log /var/log/nginx/easy-basket-error.log;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Save:** `Ctrl+X`, `Y`, `Enter`

---

## 🧪 Step 2: Test and Reload

```bash
# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Test locally
curl http://localhost/api/health

# Test via IP (from EC2)
curl http://13.60.76.140/api/health

# Test via domain (from EC2)
curl http://api.easybasket.in/api/health
```

---

## 🔍 Step 3: Check Security Group (If IP Test Fails)

If `curl http://13.60.76.140/api/health` times out, check security group:

1. **AWS Console** → **EC2** → **Instances** → Select your instance
2. **Security** tab → **Security groups**
3. **Inbound rules** should have:
   - **Type:** HTTP
   - **Port:** 80
   - **Source:** `0.0.0.0/0`

**If missing, add it.**

---

## ✅ Verification

After updating, verify:

```bash
# Check config
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

# Should show:
# server_name api.easybasket.in localhost 13.60.76.140 _;

# Test all endpoints
curl http://localhost/api/health
curl http://13.60.76.140/api/health
curl http://api.easybasket.in/api/health
```

**All should return JSON!**

---

## 📋 Quick One-Liner Fix

```bash
sudo sed -i 's/server_name _;/server_name api.easybasket.in localhost 13.60.76.140 _;/' /etc/nginx/conf.d/easy-basket.conf && sudo nginx -t && sudo systemctl reload nginx && curl http://api.easybasket.in/api/health
```

---

**Update the server_name and test again! 🚀**

