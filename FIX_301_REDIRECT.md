# 🔧 Fix: 301 Redirect Error

301 status means "Moved Permanently" - usually HTTP to HTTPS redirect or trailing slash issue.

---

## 🔍 Step 1: Check if SSL is Set Up

### On EC2:

```bash
# Check if Certbot/SSL is configured
sudo ls -la /etc/letsencrypt/live/api.easybasket.in/ 2>/dev/null && echo "SSL configured" || echo "SSL not configured"

# Check Nginx config for redirect
sudo grep -A 5 "return 301" /etc/nginx/conf.d/easy-basket.conf
```

**If SSL is set up, Nginx might be redirecting HTTP to HTTPS.**

---

## 🔧 Fix 1: Update App to Use HTTPS

### If SSL is Set Up:

**File:** `mobile/lib/config/app_config.dart`

**Change to:**
```dart
static const String apiBaseUrl = 'https://api.easybasket.in/api';
```

**Then rebuild:**
```bash
cd mobile
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 🔧 Fix 2: Disable HTTP to HTTPS Redirect (Temporary)

### If SSL is NOT Set Up Yet:

**On EC2:**

```bash
# Check Nginx config
sudo cat /etc/nginx/conf.d/easy-basket.conf

# If there's a redirect block like:
# return 301 https://$server_name$request_uri;
# Comment it out temporarily
```

---

## 🔍 Step 2: Check API Service Follows Redirects

### Check API Service:

**File:** `mobile/lib/services/api_service.dart`

**The HTTP client should follow redirects automatically, but let's verify:**

```dart
// Should handle redirects automatically
// But check if there's any redirect handling
```

---

## 🔧 Fix 3: Update API Service to Handle Redirects

### If API Service Doesn't Follow Redirects:

**File:** `mobile/lib/services/api_service.dart`

**Ensure the HTTP client follows redirects:**

```dart
// In your HTTP client initialization
// Most HTTP clients follow redirects by default
// But if using custom client, ensure maxRedirects is set
```

---

## 🔍 Step 3: Test API Directly

### From Your Mac:

```bash
# Test HTTP (should work or redirect)
curl -v http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9876543210"}' 2>&1 | head -30

# Test HTTPS (if SSL is set up)
curl -v https://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9876543210"}' 2>&1 | head -30
```

**Check the response - does it redirect? What's the final status?**

---

## 🔧 Fix 4: Check URL Construction

### Verify API Service Builds URLs Correctly:

**The API service should build:**
- Base: `http://api.easybasket.in/api`
- Endpoint: `/auth/login`
- Final: `http://api.easybasket.in/api/auth/login`

**Not:**
- `http://api.easybasket.in/api/auth/login/` (trailing slash might cause redirect)

---

## 🔍 Step 4: Check Nginx Config for Redirects

### On EC2:

```bash
# Check for redirect rules
sudo grep -r "return 301" /etc/nginx/

# Check easy-basket config
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep -A 3 -B 3 "301\|redirect"
```

**If there's a redirect, either:**
1. Use HTTPS in app (if SSL is set up)
2. Remove redirect (if SSL not set up yet)

---

## 🔧 Quick Fix: Use HTTPS in App

### If SSL is Already Set Up:

**File:** `mobile/lib/config/app_config.dart`

```dart
static const String apiBaseUrl = 'https://api.easybasket.in/api';
```

**Rebuild app:**
```bash
cd mobile
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 🔧 Alternative: Set Up SSL Now

### On EC2:

```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d api.easybasket.in

# Follow prompts
# Then update app to use HTTPS
```

---

## 📋 Complete Diagnostic

**Run this on EC2:**

```bash
echo "=== 1. SSL Status ==="
sudo ls -la /etc/letsencrypt/live/api.easybasket.in/ 2>/dev/null && echo "SSL configured" || echo "SSL not configured"

echo ""
echo "=== 2. Nginx Redirect Rules ==="
sudo grep -r "return 301" /etc/nginx/conf.d/ 2>/dev/null || echo "No redirect rules found"

echo ""
echo "=== 3. Test HTTP ==="
curl -v http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9876543210"}' 2>&1 | grep -E "(HTTP|Location|301|302)" | head -5

echo ""
echo "=== 4. Test HTTPS (if SSL exists) ==="
curl -v https://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9876543210"}' 2>&1 | grep -E "(HTTP|200|401|400)" | head -5
```

**Share the output.**

---

## 🎯 Most Likely Issues

1. **SSL is set up and redirecting HTTP to HTTPS** → Use HTTPS in app
2. **Nginx has redirect rule** → Either use HTTPS or remove redirect
3. **URL has trailing slash** → Check API service URL construction

---

## ✅ Quick Fix Sequence

1. **Check if SSL is set up:**
   ```bash
   sudo ls /etc/letsencrypt/live/api.easybasket.in/ 2>/dev/null
   ```

2. **If SSL exists, use HTTPS in app:**
   ```dart
   static const String apiBaseUrl = 'https://api.easybasket.in/api';
   ```

3. **If SSL doesn't exist, check for redirects:**
   ```bash
   sudo grep "return 301" /etc/nginx/conf.d/easy-basket.conf
   ```

---

**Check if SSL is set up first, then either use HTTPS or remove the redirect! 🔍**

