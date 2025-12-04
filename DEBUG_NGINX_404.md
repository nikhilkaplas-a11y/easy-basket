# 🔍 Debug Nginx 404 - Step by Step

Still getting 404? Let's check everything systematically.

---

## 🔍 Step 1: Verify Config File Exists and Location

```bash
# Check if file exists
ls -la /etc/nginx/conf.d/easy-basket.conf

# View the file content
sudo cat /etc/nginx/conf.d/easy-basket.conf

# Check file permissions
ls -la /etc/nginx/conf.d/
```

**Should show:** `easy-basket.conf` file exists

---

## 🔍 Step 2: Check Main Nginx Config Includes conf.d

```bash
# Check main nginx.conf
sudo cat /etc/nginx/nginx.conf | grep -A 5 -B 5 "include"
```

**Should show:**
```
include /etc/nginx/conf.d/*.conf;
```

**If NOT present, add it:**

```bash
sudo nano /etc/nginx/nginx.conf
```

**Find the `http {` block and inside it, add:**
```nginx
http {
    # ... existing config ...
    
    include /etc/nginx/conf.d/*.conf;  # Add this line
    
    # ... rest of config ...
}
```

**Save and test:**
```bash
sudo nginx -t
```

---

## 🔍 Step 3: Check for Default Server Block

```bash
# List all config files
ls -la /etc/nginx/conf.d/

# Check if there's a default.conf
cat /etc/nginx/conf.d/default.conf 2>/dev/null
```

**If default.conf exists and has `server_name _;` or `server_name localhost;`, it might be taking precedence.**

**Option 1: Remove default.conf**
```bash
sudo rm /etc/nginx/conf.d/default.conf
sudo nginx -t
sudo systemctl reload nginx
```

**Option 2: Or make your config have higher priority by putting it first**

---

## 🔍 Step 4: Check Nginx Error Logs

```bash
# Check error logs for clues
sudo tail -50 /var/log/nginx/error.log

# Check your specific error log
sudo tail -50 /var/log/nginx/easy-basket-error.log
```

**Look for:**
- Configuration errors
- Permission issues
- Proxy connection errors

---

## 🔍 Step 5: Verify Backend is Running

```bash
# Check PM2
pm2 status

# Test backend directly
curl http://localhost:3000/api/health
```

**If backend not running:**
```bash
cd ~/easy-basket/backend
npm run build
pm2 start dist/index.js --name easy-basket-api
```

---

## 🔍 Step 6: Check What Nginx is Actually Serving

```bash
# Check which server block is being used
curl -v http://localhost/api/health 2>&1 | grep -i "server"

# Check Nginx is listening on port 80
sudo netstat -tuln | grep :80
```

---

## 🔧 Step 7: Complete Fix - Remove Default and Ensure Config

```bash
# 1. Remove default config (if exists)
sudo rm -f /etc/nginx/conf.d/default.conf

# 2. Verify your config exists
sudo cat /etc/nginx/conf.d/easy-basket.conf

# 3. Ensure main config includes conf.d
sudo grep "include.*conf.d" /etc/nginx/nginx.conf

# If not found, add it:
sudo nano /etc/nginx/nginx.conf
# Add: include /etc/nginx/conf.d/*.conf; inside http block

# 4. Test configuration
sudo nginx -t

# 5. Restart Nginx (not just reload)
sudo systemctl restart nginx

# 6. Check status
sudo systemctl status nginx

# 7. Test again
curl http://localhost/api/health
```

---

## 🔧 Alternative: Put Config in sites-available (if conf.d not working)

Some Nginx setups use `sites-available` instead:

```bash
# Create config in sites-available
sudo nano /etc/nginx/sites-available/easy-basket.conf

# Paste your config

# Create symlink to sites-enabled
sudo ln -s /etc/nginx/sites-available/easy-basket.conf /etc/nginx/sites-enabled/

# Test and restart
sudo nginx -t
sudo systemctl restart nginx
```

---

## 🔍 Step 8: Check Nginx Configuration Test Output

```bash
# Run test with verbose output
sudo nginx -T 2>&1 | grep -A 10 "server_name"
```

**This shows all server blocks and their server_name values.**

---

## 🔧 Complete Diagnostic Script

Run this to check everything:

```bash
echo "=== 1. Config file exists? ==="
ls -la /etc/nginx/conf.d/easy-basket.conf

echo "=== 2. Config file content ==="
sudo cat /etc/nginx/conf.d/easy-basket.conf

echo "=== 3. Main config includes conf.d? ==="
sudo grep "include.*conf.d" /etc/nginx/nginx.conf

echo "=== 4. Default config exists? ==="
ls -la /etc/nginx/conf.d/default.conf 2>/dev/null || echo "No default.conf"

echo "=== 5. Backend running? ==="
pm2 status
curl -s http://localhost:3000/api/health | head -1

echo "=== 6. Nginx test ==="
sudo nginx -t

echo "=== 7. Nginx status ==="
sudo systemctl status nginx | head -5

echo "=== 8. Test endpoint ==="
curl -s http://localhost/api/health | head -1
```

---

## 🎯 Most Likely Issues

1. **Main nginx.conf doesn't include conf.d** → Add `include /etc/nginx/conf.d/*.conf;`
2. **Default server block taking precedence** → Remove `default.conf`
3. **Config file not saved correctly** → Recreate it
4. **Nginx not restarted** → Use `restart` instead of `reload`

---

## ✅ Final Fix Sequence

```bash
# 1. Remove default
sudo rm -f /etc/nginx/conf.d/default.conf

# 2. Ensure main config includes conf.d
sudo nano /etc/nginx/nginx.conf
# Add inside http block: include /etc/nginx/conf.d/*.conf;

# 3. Recreate your config
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Paste your config, save

# 4. Test
sudo nginx -t

# 5. Restart (not reload)
sudo systemctl restart nginx

# 6. Test
curl http://localhost/api/health
```

---

**Run the diagnostic script above and share the output! 🔍**

