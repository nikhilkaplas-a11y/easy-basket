# 🔧 Fix Nginx Server Name Conflict

The error shows:
- `conflicting server name "_"` - Multiple server blocks
- `open() "/usr/share/nginx/html/api/health"` - Not proxying, serving static files

---

## 🔍 Step 1: Find All Server Blocks

```bash
# Find all server blocks
sudo grep -r "server_name" /etc/nginx/

# List all config files
ls -la /etc/nginx/conf.d/
```

**This will show all server blocks and where they are.**

---

## 🔧 Step 2: Remove Duplicate/Default Server Blocks

```bash
# Remove default configs
sudo rm -f /etc/nginx/conf.d/default.conf
sudo rm -f /etc/nginx/default.conf

# Check main nginx.conf for server blocks
sudo grep -A 10 "server {" /etc/nginx/nginx.conf
```

**If there's a server block in main nginx.conf, either remove it or comment it out.**

---

## 🔧 Step 3: Create Single Clean Config

```bash
# Remove all configs in conf.d (backup first)
sudo mkdir -p /tmp/nginx-backup
sudo cp -r /etc/nginx/conf.d/* /tmp/nginx-backup/ 2>/dev/null || true

# Remove all
sudo rm -f /etc/nginx/conf.d/*.conf

# Create ONE clean config
sudo tee /etc/nginx/conf.d/easy-basket.conf > /dev/null <<'EOF'
server {
    listen 80 default_server;
    server_name _;

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
EOF
```

**Note:** Only ONE server block, with `default_server` and `server_name _;`

---

## 🔍 Step 4: Check Main nginx.conf

```bash
# Check if main config has server blocks
sudo grep -A 20 "server {" /etc/nginx/nginx.conf
```

**If there's a server block in main config, comment it out:**

```bash
sudo nano /etc/nginx/nginx.conf
```

**Find and comment out any server blocks (add # at the start of each line):**

```nginx
# server {
#     listen       80;
#     server_name  _;
#     ...
# }
```

---

## 🔧 Step 5: Ensure Main Config Includes conf.d

```bash
# Check if include exists
sudo grep "include.*conf.d" /etc/nginx/nginx.conf
```

**If not present, add it:**

```bash
sudo nano /etc/nginx/nginx.conf
```

**Inside the `http {` block, add:**

```nginx
http {
    # ... existing config ...
    
    include /etc/nginx/conf.d/*.conf;
    
    # ... rest of config ...
}
```

---

## 🧪 Step 6: Test and Restart

```bash
# Test configuration
sudo nginx -t

# Should show NO warnings about conflicting server names

# Restart Nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx

# Test
curl http://localhost/api/health
```

---

## 🔍 Step 7: Verify Only One Server Block

```bash
# Check active server blocks
sudo nginx -T 2>&1 | grep -A 5 "server {" | grep -E "(listen|server_name)"
```

**Should show only ONE server block with `listen 80 default_server;`**

---

## 📋 Complete Fix Script

Run this to fix everything:

```bash
#!/bin/bash

echo "=== Step 1: Backup existing configs ==="
sudo mkdir -p /tmp/nginx-backup
sudo cp -r /etc/nginx/conf.d/* /tmp/nginx-backup/ 2>/dev/null || true

echo "=== Step 2: Remove all configs ==="
sudo rm -f /etc/nginx/conf.d/*.conf

echo "=== Step 3: Create single clean config ==="
sudo tee /etc/nginx/conf.d/easy-basket.conf > /dev/null <<'EOF'
server {
    listen 80 default_server;
    server_name _;

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
EOF

echo "=== Step 4: Ensure main config includes conf.d ==="
if ! sudo grep -q "include.*conf.d" /etc/nginx/nginx.conf; then
    echo "WARNING: Main config doesn't include conf.d - you need to add it manually"
    echo "Add this line inside http block: include /etc/nginx/conf.d/*.conf;"
fi

echo "=== Step 5: Test config ==="
sudo nginx -t

echo "=== Step 6: Restart Nginx ==="
sudo systemctl restart nginx

echo "=== Step 7: Test ==="
sleep 2
curl -s http://localhost/api/health | head -3
```

**Save as `fix-nginx-conflict.sh`, make executable, and run:**
```bash
chmod +x fix-nginx-conflict.sh
sudo ./fix-nginx-conflict.sh
```

---

## ✅ Expected Result

After fix:
- ✅ No "conflicting server name" warnings
- ✅ `curl http://localhost/api/health` returns JSON
- ✅ Nginx proxies to backend, not serving static files

---

## 🐛 If Still Not Working

Check what server block is actually being used:

```bash
# See all server blocks Nginx sees
sudo nginx -T 2>&1 | grep -B 2 -A 10 "listen 80"
```

**This shows all server blocks. Should be only ONE.**

---

**Run the fix script or do the steps manually. The key is: ONLY ONE server block with default_server! 🔧**

