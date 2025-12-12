# ✅ Domain Setup Complete!

Your domain `api.easybasket.in` is now working! 🎉

---

## ✅ What Was Fixed

1. **DNS Configuration** ✅
   - Added A record in GoDaddy: `api` → `13.60.76.140`
   - DNS propagated successfully

2. **Nginx Configuration** ✅
   - Created config in `/etc/nginx/conf.d/easy-basket.conf`
   - Commented out conflicting server block in main `nginx.conf`
   - Nginx now properly proxies to backend

3. **Backend Running** ✅
   - PM2 process `easy-basket-api` is online
   - Backend responding on port 3000

4. **Security Group** ✅
   - Ports 80, 443, 22 are open

---

## 🧪 Test Your Domain

### From EC2:
```bash
curl http://api.easybasket.in/api/health
```

### From Your Local Machine:
```bash
curl http://api.easybasket.in/api/health
```

### In Browser:
```
http://api.easybasket.in/api/health
```

**Should return:**
```json
{
  "status": "ok",
  "message": "Easy Basket Backend is running",
  "timestamp": "..."
}
```

---

## 🔐 Next Step: Set Up SSL (HTTPS)

### Install Certbot:
```bash
sudo yum install -y certbot python3-certbot-nginx
```

### Get SSL Certificate:
```bash
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

**Your API will then be accessible via HTTPS! 🔒**

---

## 📱 Update Mobile App

### Update API URL:

**File:** `mobile/lib/config/app_config.dart`

**Change to:**
```dart
class AppConfig {
  // Production API URL
  static const String apiBaseUrl = 'https://api.easybasket.in/api';
  // Or HTTP (if SSL not set up yet):
  // static const String apiBaseUrl = 'http://api.easybasket.in/api';
}
```

### Rebuild App:
```bash
cd mobile
flutter clean
flutter pub get
flutter run -d chrome  # Test on web first
```

---

## 📋 Current Status

- ✅ Domain: `api.easybasket.in`
- ✅ DNS: Resolving to `13.60.76.140`
- ✅ Nginx: Proxying correctly
- ✅ Backend: Running on PM2
- ✅ HTTP: Working (`http://api.easybasket.in`)
- ⏳ HTTPS: Not set up yet (optional but recommended)

---

## 🎯 Your API Endpoints

All these should work now:

- `http://api.easybasket.in/api/health`
- `http://api.easybasket.in/api/categories`
- `http://api.easybasket.in/api/products`
- `http://api.easybasket.in/api/auth/login`
- `http://api.easybasket.in/api/orders`
- And all other endpoints...

---

## 🔧 Useful Commands

### Check Nginx Status:
```bash
sudo systemctl status nginx
```

### Check Backend Status:
```bash
pm2 status
pm2 logs easy-basket-api
```

### Test Domain:
```bash
curl http://api.easybasket.in/api/health
```

### View Nginx Logs:
```bash
sudo tail -f /var/log/nginx/easy-basket-access.log
sudo tail -f /var/log/nginx/easy-basket-error.log
```

---

## 🎉 Congratulations!

Your Easy Basket API is now accessible via a professional domain name!

**Next steps:**
1. Set up SSL for HTTPS (recommended)
2. Update mobile app with new domain URL
3. Test all endpoints
4. Deploy to production! 🚀

---

**Your domain setup is complete! 🎊**

