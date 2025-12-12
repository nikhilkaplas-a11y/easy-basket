# 🔍 Complete Nginx Diagnostic

Let's check everything systematically to find the exact issue.

---

## 🔍 Step 1: Run Complete Diagnostic

**Run these commands on EC2 and share ALL output:**

```bash
echo "=== 1. Backend running? ==="
pm2 status
curl -s http://localhost:3000/api/health 2>&1 | head -5

echo "=== 2. Config files in conf.d ==="
ls -la /etc/nginx/conf.d/

echo "=== 3. Your config file content ==="
sudo cat /etc/nginx/conf.d/easy-basket.conf 2>/dev/null || echo "File not found"

echo "=== 4. Main nginx.conf - http block ==="
sudo cat /etc/nginx/nginx.conf | grep -A 50 "http {"

echo "=== 5. All server blocks Nginx sees ==="
sudo nginx -T 2>&1 | grep -B 2 -A 15 "listen 80"

echo "=== 6. Nginx test ==="
sudo nginx -t 2>&1

echo "=== 7. Nginx status ==="
sudo systemctl status nginx | head -10

echo "=== 8. Test endpoint ==="
curl -v http://localhost/api/health 2>&1 | head -20
```

**Share ALL the output from this diagnostic.**

---

## 🔧 Step 2: Check Main nginx.conf for Server Blocks

The main `nginx.conf` might have a server block that's taking precedence:

```bash
# Check for server blocks in main config
sudo grep -A 20 "server {" /etc/nginx/nginx.conf
```

**If there's a server block in main config, we need to remove/comment it.**

---

## 🔧 Step 3: Nuclear Option - Clean Everything

If nothing works, let's start completely fresh:

```bash
# 1. Stop Nginx
sudo systemctl stop nginx

# 2. Backup everything
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
sudo mkdir -p /tmp/nginx-backup
sudo cp -r /etc/nginx/conf.d/* /tmp/nginx-backup/ 2>/dev/null || true

# 3. Remove all configs
sudo rm -f /etc/nginx/conf.d/*.conf

# 4. Check main nginx.conf structure
sudo cat /etc/nginx/nginx.conf
```

**Share the main nginx.conf content** - I'll tell you exactly what to change.

---

## 🔧 Step 4: Check if Backend is Actually Running

```bash
# Check PM2
pm2 status

# If not running, start it
cd ~/easy-basket/backend
npm run build
pm2 start dist/index.js --name easy-basket-api

# Test backend directly
curl http://localhost:3000/api/health
```

**Backend MUST work directly before Nginx can proxy to it.**

---

## 🔧 Step 5: Check What Nginx Actually Sees

```bash
# See complete Nginx configuration
sudo nginx -T 2>&1 | less

# Or search for server blocks
sudo nginx -T 2>&1 | grep -B 5 -A 20 "listen 80"
```

**This shows exactly what Nginx is using.**

---

## 🎯 Most Likely Issues

1. **Main nginx.conf has a server block** → Need to remove/comment it
2. **Backend not running** → Need to start it
3. **Include statement in wrong place** → Need to move it
4. **Multiple server blocks still** → Need to find and remove all

---

## 📋 What I Need From You

**Please run Step 1 diagnostic and share ALL the output.** 

This will show me:
- If backend is running
- What config files exist
- What the main nginx.conf looks like
- What Nginx actually sees
- What the error is

**Then I can give you the exact fix!**

---

**Run the Step 1 diagnostic and share the complete output! 🔍**

