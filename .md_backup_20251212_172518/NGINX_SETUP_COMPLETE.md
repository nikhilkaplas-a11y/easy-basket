# 🌐 Complete Nginx Setup Guide for Easy Basket

Step-by-step guide to set up Nginx reverse proxy for your backend API.

---

## 📋 Prerequisites

- EC2 instance running
- Backend running on port 3000
- Domain name (optional, can use IP)

---

## 🔧 Step 1: Install Nginx

### On Amazon Linux 2023:

```bash
sudo yum update -y
sudo yum install -y nginx
```

### On Ubuntu:

```bash
sudo apt update
sudo apt install -y nginx
```

### Verify Installation:

```bash
nginx -v
# Should show: nginx version: nginx/1.x.x
```

---

## 🚀 Step 2: Start and Enable Nginx

```bash
# Start Nginx
sudo systemctl start nginx

# Enable Nginx to start on boot
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx

# Should show: active (running)
```

---

## ⚙️ Step 3: Configure Nginx

### Create Configuration File

```bash
# Create config file for Easy Basket
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

### Add This Configuration:

```nginx
server {
    listen 80;
    server_name 13.60.76.140;  # Your EC2 IP or domain name

    # Logging
    access_log /var/log/nginx/easy-basket-access.log;
    error_log /var/log/nginx/easy-basket-error.log;

    # Proxy settings
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Cache bypass
        proxy_cache_bypass $http_upgrade;
    }

    # Health check endpoint (optional)
    location /health {
        proxy_pass http://localhost:3000/api/health;
        access_log off;
    }
}
```

**Save:** `Ctrl+X`, then `Y`, then `Enter`

---

## 🔍 Step 4: Test Nginx Configuration

```bash
# Test configuration syntax
sudo nginx -t

# Should show:
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**If there are errors, fix them before proceeding!**

---

## 🔄 Step 5: Reload Nginx

```bash
# Reload Nginx (applies new configuration)
sudo systemctl reload nginx

# Or restart
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

---

## 🧪 Step 6: Test Nginx

### Test from EC2 (Local):

```bash
# Test Nginx
curl http://localhost

# Should return: "Easy Basket Backend is running"

# Test health endpoint
curl http://localhost/api/health
```

### Test from Your Local Machine:

```bash
# Test via Nginx (port 80)
curl http://13.60.76.140

# Test health endpoint
curl http://13.60.76.140/api/health

# Test categories
curl http://13.60.76.140/api/categories
```

---

## 🔒 Step 7: Update Security Group

### Allow HTTP (Port 80) and HTTPS (Port 443)

1. **AWS Console** → **EC2** → **Instances** → Select your instance
2. Click **Security** tab → Click security group
3. **Inbound rules** → **Edit inbound rules** → **Add rules:**

   **Rule 1:**
   - **Type:** HTTP
   - **Port:** 80
   - **Source:** 0.0.0.0/0
   - **Description:** Allow HTTP

   **Rule 2:**
   - **Type:** HTTPS
   - **Port:** 443
   - **Source:** 0.0.0.0/0
   - **Description:** Allow HTTPS

4. **Save rules**

**Optional:** You can now remove port 3000 from security group (Nginx handles it)

---

## 🌐 Step 8: Configure Domain (Optional)

### If You Have a Domain:

1. **Update DNS:**
   - Go to your domain registrar
   - Add A record:
     - **Name:** `@` (or `api` for api.yourdomain.com)
     - **Type:** A
     - **Value:** `13.60.76.140` (your EC2 IP)
     - **TTL:** 300

2. **Update Nginx Config:**

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

Change:
```nginx
server_name 13.60.76.140;
```

To:
```nginx
server_name api.yourdomain.com yourdomain.com;
```

3. **Reload Nginx:**

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔐 Step 9: Set Up SSL with Let's Encrypt (Recommended)

### Install Certbot:

```bash
# Amazon Linux 2023
sudo yum install -y certbot python3-certbot-nginx

# Ubuntu
sudo apt install -y certbot python3-certbot-nginx
```

### Get SSL Certificate:

```bash
# If using domain
sudo certbot --nginx -d api.yourdomain.com -d yourdomain.com

# Follow prompts:
# - Enter email address
# - Agree to terms
# - Choose: 2 (Redirect HTTP to HTTPS)
```

### Auto-Renewal:

```bash
# Test renewal
sudo certbot renew --dry-run

# Certbot automatically sets up renewal (runs twice daily)
```

---

## 📋 Step 10: Update Mobile App Configuration

### Update API Base URL:

**File:** `mobile/lib/config/app_config.dart`

```dart
class AppConfig {
  // Production API URL (via Nginx)
  static const String apiBaseUrl = 'http://13.60.76.140/api';
  // Or with domain:
  // static const String apiBaseUrl = 'https://api.yourdomain.com/api';
  
  // For HTTPS (after SSL setup):
  // static const String apiBaseUrl = 'https://13.60.76.140/api';
}
```

---

## 🔍 Step 11: Verify Everything Works

### Test Endpoints:

```bash
# Root
curl http://13.60.76.140

# Health
curl http://13.60.76.140/api/health

# Categories
curl http://13.60.76.140/api/categories

# Products
curl http://13.60.76.140/api/products
```

### Check Nginx Logs:

```bash
# Access logs
sudo tail -f /var/log/nginx/easy-basket-access.log

# Error logs
sudo tail -f /var/log/nginx/easy-basket-error.log

# General error log
sudo tail -f /var/log/nginx/error.log
```

---

## 🐛 Troubleshooting

### Error: "502 Bad Gateway"

**Cause:** Backend not running or wrong port

**Fix:**
```bash
# Check if backend is running
pm2 status

# Check if port 3000 is listening
sudo lsof -i :3000

# Restart backend
pm2 restart easy-basket-api

# Check Nginx error log
sudo tail -f /var/log/nginx/error.log
```

### Error: "Connection refused"

**Cause:** Backend not accessible from Nginx

**Fix:**
```bash
# Test backend directly
curl http://localhost:3000

# If works, check Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Error: "nginx: [emerg] bind() to 0.0.0.0:80 failed"

**Cause:** Port 80 already in use

**Fix:**
```bash
# Check what's using port 80
sudo lsof -i :80

# Stop conflicting service or change Nginx port
```

### Nginx Not Starting

**Fix:**
```bash
# Check configuration
sudo nginx -t

# Check error log
sudo tail -f /var/log/nginx/error.log

# Check status
sudo systemctl status nginx
```

---

## 📊 Nginx Commands Reference

```bash
# Start Nginx
sudo systemctl start nginx

# Stop Nginx
sudo systemctl stop nginx

# Restart Nginx
sudo systemctl restart nginx

# Reload Nginx (without downtime)
sudo systemctl reload nginx

# Check status
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# View logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## ✅ Complete Setup Checklist

- [ ] Nginx installed
- [ ] Nginx started and enabled
- [ ] Configuration file created (`/etc/nginx/conf.d/easy-basket.conf`)
- [ ] Configuration tested (`nginx -t`)
- [ ] Nginx reloaded
- [ ] Security group allows port 80 (and 443 for HTTPS)
- [ ] Backend running on port 3000
- [ ] Tested via Nginx: `curl http://13.60.76.140`
- [ ] SSL certificate installed (optional)
- [ ] Mobile app updated with new API URL

---

## 🎯 Quick Setup Commands

```bash
# 1. Install
sudo yum install -y nginx

# 2. Start
sudo systemctl start nginx
sudo systemctl enable nginx

# 3. Create config
sudo nano /etc/nginx/conf.d/easy-basket.conf
# (Paste configuration from Step 3)

# 4. Test and reload
sudo nginx -t
sudo systemctl reload nginx

# 5. Test
curl http://13.60.76.140/api/health
```

---

## 📝 Configuration File Location

- **Main config:** `/etc/nginx/nginx.conf`
- **Site config:** `/etc/nginx/conf.d/easy-basket.conf`
- **Access logs:** `/var/log/nginx/easy-basket-access.log`
- **Error logs:** `/var/log/nginx/easy-basket-error.log`

---

## 🔄 After Backend Changes

When you update backend code:

```bash
# Backend changes don't require Nginx restart
# Just restart PM2:
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api

# Nginx will automatically proxy to the restarted backend
```

---

## 🌟 Benefits of Nginx

1. **Single Port:** Access via port 80 (standard HTTP)
2. **SSL Support:** Easy HTTPS setup
3. **Load Balancing:** Can add more backend instances later
4. **Caching:** Can cache static responses
5. **Security:** Hide backend port from public
6. **Domain Support:** Use custom domain names

---

**Your API is now accessible via Nginx on port 80! 🚀**

