# 🔧 Complete Nginx Fix - Step by Step

Still getting 404? Let's fix it completely.

---

## 🔍 Step 1: Check Current State

Run these commands and share the output:

```bash
# 1. Check if config file exists
echo "=== Config file ==="
ls -la /etc/nginx/conf.d/easy-basket.conf

# 2. Check main nginx.conf
echo "=== Main config includes ==="
sudo cat /etc/nginx/nginx.conf | grep -i include

# 3. Check for default config
echo "=== Default config ==="
ls -la /etc/nginx/conf.d/default.conf 2>/dev/null || echo "No default.conf"

# 4. Check backend
echo "=== Backend ==="
pm2 status
curl -s http://localhost:3000/api/health 2>&1 | head -3

# 5. Check Nginx test
echo "=== Nginx test ==="
sudo nginx -t 2>&1
```

---

## 🔧 Step 2: Complete Fix - Do All Steps

### A. Remove Default Config (if exists)

```bash
sudo rm -f /etc/nginx/conf.d/default.conf
sudo rm -f /etc/nginx/default.conf
```

### B. Check Main nginx.conf Structure

```bash
# View the http block
sudo cat /etc/nginx/nginx.conf | grep -A 20 "http {"
```

**Look for:** `include /etc/nginx/conf.d/*.conf;`

**If NOT found, add it:**

```bash
sudo nano /etc/nginx/nginx.conf
```

**Find the `http {` block. It should look like:**

```nginx
http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # ADD THIS LINE HERE:
    include /etc/nginx/conf.d/*.conf;  # <-- ADD THIS

    # ... rest of config ...
}
```

**Save:** `Ctrl+X`, `Y`, `Enter`

### C. Verify Your Config File

```bash
# Check your config file
sudo cat /etc/nginx/conf.d/easy-basket.conf
```

**Should show your complete server block.**

**If file doesn't exist or is wrong, recreate it:**

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Paste this EXACT config:**

```nginx
server {
    listen 80 default_server;
    server_name api.easybasket.in localhost 13.60.76.140 _;

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

    location /api/health {
        proxy_pass http://localhost:3000/api/health;
        access_log off;
    }
}
```

**Note:** Added `default_server` and `_` to catch all requests.

**Save:** `Ctrl+X`, `Y`, `Enter`

### D. Test Configuration

```bash
# Test
sudo nginx -t
```

**Should show:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**If there are errors, fix them before proceeding.**

### E. Restart Nginx (Not Reload)

```bash
# Stop Nginx
sudo systemctl stop nginx

# Start Nginx
sudo systemctl start nginx

# Or use restart
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

**Should show:** `active (running)`

### F. Test Endpoints

```bash
# Test backend directly
echo "=== Backend direct ==="
curl http://localhost:3000/api/health

# Test through Nginx
echo "=== Through Nginx ==="
curl http://localhost/api/health

# Test /health
echo "=== /health ==="
curl http://localhost/health

# Test /api/health
echo "=== /api/health ==="
curl http://localhost/api/health
```

---

## 🔍 Step 3: Check Nginx Logs

If still not working:

```bash
# Check error logs
sudo tail -50 /var/log/nginx/error.log

# Check your specific error log
sudo tail -50 /var/log/nginx/easy-basket-error.log

# Check access logs
sudo tail -20 /var/log/nginx/easy-basket-access.log
```

---

## 🔧 Step 4: Alternative - Put Config in Main File

If `conf.d` still doesn't work, add config directly to main file:

```bash
# Backup main config
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Edit main config
sudo nano /etc/nginx/nginx.conf
```

**Add your server block at the END of the `http {` block, before the closing `}`:**

```nginx
http {
    # ... existing config ...
    
    include /etc/nginx/conf.d/*.conf;
    
    # Add your server block here
    server {
        listen 80 default_server;
        server_name api.easybasket.in localhost 13.60.76.140 _;

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

        location /api/health {
            proxy_pass http://localhost:3000/api/health;
            access_log off;
        }
    }
}
```

**Save and test:**
```bash
sudo nginx -t
sudo systemctl restart nginx
```

---

## 📋 Complete Fix Script

Run this complete sequence:

```bash
#!/bin/bash

echo "=== Step 1: Remove defaults ==="
sudo rm -f /etc/nginx/conf.d/default.conf
sudo rm -f /etc/nginx/default.conf

echo "=== Step 2: Check main config ==="
if ! sudo grep -q "include.*conf.d" /etc/nginx/nginx.conf; then
    echo "Adding include to main config..."
    # This is tricky - you'll need to edit manually
    echo "Please edit /etc/nginx/nginx.conf and add: include /etc/nginx/conf.d/*.conf; inside http block"
else
    echo "Main config already includes conf.d"
fi

echo "=== Step 3: Create config file ==="
sudo tee /etc/nginx/conf.d/easy-basket.conf > /dev/null <<'EOF'
server {
    listen 80 default_server;
    server_name api.easybasket.in localhost 13.60.76.140 _;

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

    location /api/health {
        proxy_pass http://localhost:3000/api/health;
        access_log off;
    }
}
EOF

echo "=== Step 4: Test config ==="
sudo nginx -t

echo "=== Step 5: Restart Nginx ==="
sudo systemctl restart nginx

echo "=== Step 6: Check status ==="
sudo systemctl status nginx | head -5

echo "=== Step 7: Test ==="
curl -s http://localhost/api/health | head -3
```

**Save as `fix-nginx.sh`, make executable, and run:**
```bash
chmod +x fix-nginx.sh
sudo ./fix-nginx.sh
```

---

## ✅ Final Verification

After all steps, these should ALL work:

```bash
curl http://localhost:3000/api/health      # Backend direct
curl http://localhost/api/health            # Through Nginx
curl http://localhost/health               # Alternative path
curl http://api.easybasket.in/api/health   # Via domain
```

---

**Run Step 1 diagnostic first and share the output, then we'll fix it! 🔍**

