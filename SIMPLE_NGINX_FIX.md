# ✅ Simple Nginx Fix - No tcp_nodelay Needed

`tcp_nodelay` is optional - not needed for basic functionality. Let's fix the 404 issue.

---

## 🔧 Simple Fix - 3 Steps

### Step 1: Check Main nginx.conf

```bash
# View the http block
sudo cat /etc/nginx/nginx.conf
```

**Look for:** `include /etc/nginx/conf.d/*.conf;` inside the `http {` block

**If NOT there, add it:**

```bash
sudo nano /etc/nginx/nginx.conf
```

**Find the `http {` block. It might look like:**

```nginx
http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # ADD THIS LINE (if not present):
    include /etc/nginx/conf.d/*.conf;
}
```

**Save:** `Ctrl+X`, `Y`, `Enter`

---

### Step 2: Ensure Config File Exists

```bash
# Check if file exists
ls -la /etc/nginx/conf.d/easy-basket.conf

# If not, create it
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Paste this (simple version, no tcp_nodelay needed):**

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

    location /api/health {
        proxy_pass http://localhost:3000/api/health;
    }
}
```

**Save:** `Ctrl+X`, `Y`, `Enter`

---

### Step 3: Test and Restart

```bash
# Test configuration
sudo nginx -t

# Should show: syntax is ok, test is successful

# Restart Nginx
sudo systemctl restart nginx

# Test
curl http://localhost/api/health
```

---

## 🔍 Quick Check: What's in Your nginx.conf?

Run this to see the structure:

```bash
sudo cat /etc/nginx/nginx.conf | grep -A 30 "http {"
```

**Share the output** - I'll tell you exactly where to add the include line.

---

## 📋 One-Line Fix (if include missing)

If the include line is missing, you can add it with:

```bash
# Check if include exists
sudo grep -q "include.*conf.d" /etc/nginx/nginx.conf && echo "Already exists" || echo "include /etc/nginx/conf.d/*.conf;" | sudo tee -a /etc/nginx/nginx.conf
```

**But this might add it in the wrong place. Better to edit manually.**

---

## ✅ Minimal Working Config

Your `easy-basket.conf` only needs this:

```nginx
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
    }
}
```

**That's it!** The `default_server` and `_` will catch all requests.

---

## 🎯 Focus on These 3 Things

1. **Main nginx.conf includes conf.d** → `include /etc/nginx/conf.d/*.conf;`
2. **Config file exists** → `/etc/nginx/conf.d/easy-basket.conf`
3. **Nginx restarted** → `sudo systemctl restart nginx`

**tcp_nodelay is NOT needed!**

---

**Show me your nginx.conf http block and I'll tell you exactly where to add the include! 🔍**

