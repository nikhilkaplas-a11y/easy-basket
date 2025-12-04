# ✅ Next Steps - Domain Working!

Your domain `api.easybasket.in` is now working! Here's what to do next.

---

## 🔐 Step 1: Set Up SSL (HTTPS) - Recommended

### On EC2:

```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d api.easybasket.in
```

### Follow Prompts:

1. **Email address:** Enter your email (for renewal notices)
2. **Terms of Service:** Type `A` and press Enter (to agree)
3. **Share email:** Type `Y` or `N` (your choice)
4. **Redirect HTTP to HTTPS:** Choose `2` (Redirect) and press Enter

### Test SSL:

```bash
# Test HTTPS
curl https://api.easybasket.in/api/health

# Should return JSON
```

### Test Auto-Renewal:

```bash
sudo certbot renew --dry-run
```

**Your API will now be accessible via HTTPS! 🔒**

---

## 📱 Step 2: Update Mobile App

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

## 🧪 Step 3: Test All Endpoints

### From Your Mac:

```bash
# Health check
curl https://api.easybasket.in/api/health

# Categories
curl https://api.easybasket.in/api/categories

# Products
curl https://api.easybasket.in/api/products

# Test in browser
# https://api.easybasket.in/api/health
```

**All should return JSON responses.**

---

## ✅ Step 4: Final Verification Checklist

- [ ] Domain working: `curl http://api.easybasket.in/api/health` ✅
- [ ] SSL certificate installed (optional but recommended)
- [ ] HTTPS working: `curl https://api.easybasket.in/api/health`
- [ ] Mobile app updated with new domain URL
- [ ] All endpoints tested and working
- [ ] Backend running on PM2
- [ ] Nginx configured correctly
- [ ] Security group allows HTTP/HTTPS
- [ ] DNS pointing to correct IP

---

## 🔧 Step 5: Update DNS (If Not Done)

### In GoDaddy:

1. **DNS Management**
2. **A record** for `api`:
   - **Value:** `13.62.13.171` (your current IP)
   - **TTL:** 300
3. **Save**

**Note:** If you have an Elastic IP, use that instead (won't change on restart).

---

## 📋 Step 6: Production Readiness Checklist

### Backend:
- [ ] Environment variables configured (`.env` file)
- [ ] Database connected (RDS)
- [ ] PM2 running and auto-start on boot
- [ ] Logs configured and monitored
- [ ] Error handling in place

### Security:
- [ ] SSL certificate installed
- [ ] Security group configured correctly
- [ ] Database credentials secure
- [ ] JWT secret is strong
- [ ] API rate limiting (optional)

### Monitoring:
- [ ] PM2 monitoring: `pm2 monit`
- [ ] Nginx logs: `sudo tail -f /var/log/nginx/easy-basket-access.log`
- [ ] Backend logs: `pm2 logs easy-basket-api`
- [ ] Health endpoint working

---

## 🚀 Step 7: Deploy Mobile App

### Build for Production:

```bash
cd mobile

# Android
flutter build apk --release

# iOS (if needed)
flutter build ios --release

# Web (if needed)
flutter build web --release
```

---

## 📊 Step 8: Set Up Monitoring (Optional)

### PM2 Monitoring:

```bash
# View real-time monitoring
pm2 monit

# Set up PM2 to start on boot
pm2 startup
pm2 save
```

### Nginx Log Monitoring:

```bash
# Monitor access logs
sudo tail -f /var/log/nginx/easy-basket-access.log

# Monitor error logs
sudo tail -f /var/log/nginx/easy-basket-error.log
```

---

## 🎯 Quick Summary

1. ✅ **Domain working** - `api.easybasket.in` → `13.62.13.171`
2. 🔐 **Get SSL** - `sudo certbot --nginx -d api.easybasket.in`
3. 📱 **Update app** - Change API URL in `app_config.dart`
4. 🧪 **Test endpoints** - Verify all APIs work
5. 🚀 **Deploy** - Build and deploy mobile app

---

## 📝 Important Notes

### Elastic IP (Recommended):

If your instance IP changes on restart, assign an Elastic IP:

1. **EC2** → **Elastic IPs** → **Allocate Elastic IP address**
2. **Allocate**
3. **Actions** → **Associate Elastic IP address**
4. **Select your instance** → **Associate**
5. **Update DNS** to point to Elastic IP

**This ensures your IP never changes.**

---

## 🔧 Useful Commands

### Check Status:

```bash
# Backend
pm2 status
pm2 logs easy-basket-api

# Nginx
sudo systemctl status nginx
sudo tail -f /var/log/nginx/easy-basket-access.log

# Test domain
curl https://api.easybasket.in/api/health
```

### Restart Services:

```bash
# Backend
pm2 restart easy-basket-api

# Nginx
sudo systemctl restart nginx
```

---

## 🎉 Congratulations!

Your Easy Basket API is now:
- ✅ Accessible via domain: `api.easybasket.in`
- ✅ Running on production server
- ✅ Ready for mobile app integration

**Next: Set up SSL and update your mobile app! 🚀**

