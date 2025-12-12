# 🔧 Fix: 301 Redirect - SSL Setup

301 means HTTP is being redirected to HTTPS. Either set up SSL or use HTTPS in app.

---

## 🔍 Step 1: Check if SSL is Set Up

### On EC2:

```bash
# Check if SSL certificate exists
sudo ls -la /etc/letsencrypt/live/api.easybasket.in/ 2>/dev/null && echo "SSL configured" || echo "SSL not configured"

# Check Nginx config for SSL
sudo grep -A 10 "listen 443" /etc/nginx/conf.d/easy-basket.conf
```

---

## 🔧 Option 1: Set Up SSL (Recommended)

### On EC2:

```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d api.easybasket.in
```

### Follow Prompts:

1. **Email:** Enter your email
2. **Terms:** Type `A` and press Enter
3. **Share email:** Type `Y` or `N`
4. **Redirect:** Choose `2` (Redirect HTTP to HTTPS)

### Test SSL:

```bash
curl https://api.easybasket.in/api/health
```

**Then app will work with HTTPS!**

---

## 🔧 Option 2: Remove HTTP to HTTPS Redirect (Temporary)

### If SSL is NOT Set Up Yet:

**On EC2:**

```bash
# Check Nginx config
sudo cat /etc/nginx/conf.d/easy-basket.conf

# If there's a redirect block like:
# server {
#     listen 80;
#     return 301 https://$server_name$request_uri;
# }
# Comment it out or remove it
```

**Then use HTTP in app:**
```dart
static const String apiBaseUrl = 'http://api.easybasket.in/api';
```

---

## 🔧 Option 3: Update App to Handle Redirects

### If You Want to Keep HTTP but Handle Redirects:

**File:** `mobile/lib/services/api_service.dart`

**The `http` package should follow redirects automatically, but you can verify:**

```dart
// The http package follows redirects by default
// But ensure you're not blocking them
```

**Actually, the issue is that 301 redirects for POST requests might not work properly. Better to use HTTPS directly.**

---

## ✅ Recommended Solution

**Set up SSL and use HTTPS:**

1. **On EC2:**
   ```bash
   sudo yum install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d api.easybasket.in
   ```

2. **App is already updated to HTTPS:**
   ```dart
   static const String apiBaseUrl = 'https://api.easybasket.in/api';
   ```

3. **Rebuild app:**
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

---

## 🔍 Test SSL Setup

### From Your Mac:

```bash
# Test HTTPS
curl https://api.easybasket.in/api/health

# Should return JSON (not redirect)
```

**If this works, SSL is set up and app will work!**

---

## 📋 Quick Decision

- **If SSL is set up:** Use HTTPS in app (already done) ✅
- **If SSL is NOT set up:** Either set it up now, or use HTTP and remove redirect

---

**Check if SSL is set up first, then proceed accordingly! 🔍**

