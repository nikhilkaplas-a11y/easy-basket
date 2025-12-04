# ✅ Next Steps After GoDaddy DNS Setup

You've added the DNS A record in GoDaddy. Here's what to do next:

---

## 🔍 Step 1: Verify DNS is Working

### Check DNS Propagation (from your local machine):

```bash
# Check if domain resolves to your EC2 IP
ping api.easybasket.in

# Or use nslookup
nslookup api.easybasket.in

# Should show: 13.60.76.140
```

**Or check online:**
- Go to: https://dnschecker.org
- Enter: `api.easybasket.in`
- Check if it shows: `13.60.76.140`

**⏱️ If not working yet:**
- Wait 15-30 minutes (DNS propagation takes time)
- Refresh and check again

---

## ⚙️ Step 2: Update Nginx Configuration on EC2

### Connect to EC2:

```bash
ssh -i your-key.pem ec2-user@13.60.76.140
```

### Edit Nginx Config:

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

### Update server_name:

**Find this line:**
```nginx
server_name _;  # or whatever is there
```

**Change to:**
```nginx
server_name api.easybasket.in;  # Your domain
```

**Or if you want both domain and IP to work:**
```nginx
server_name api.easybasket.in 13.60.76.140;  # Both
```

**Complete config should look like:**
```nginx
server {
    listen 80;
    server_name api.easybasket.in;  # Your domain

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
}
```

### Test Nginx Configuration:

```bash
sudo nginx -t
```

**Should show:** `syntax is ok` and `test is successful`

### Reload Nginx:

```bash
sudo systemctl reload nginx
```

---

## 🧪 Step 3: Test Your Domain

### From EC2:

```bash
curl http://api.easybasket.in/api/health
```

**Should return:** JSON response like:
```json
{
  "status": "ok",
  "message": "Easy Basket Backend is running",
  "timestamp": "2025-12-03T..."
}
```

### From Your Local Machine:

```bash
curl http://api.easybasket.in/api/health
```

**Or test in browser:**
- Open: `http://api.easybasket.in/api/health`
- Should see JSON response

### Test Other Endpoints:

```bash
# Test categories
curl http://api.easybasket.in/api/categories

# Test products
curl http://api.easybasket.in/api/products
```

---

## 🔐 Step 4: Set Up SSL (HTTPS) - Recommended

### Install Certbot:

```bash
sudo yum install -y certbot python3-certbot-nginx
```

### Get SSL Certificate:

```bash
sudo certbot --nginx -d api.easybasket.in
```

### Follow Prompts:

1. **Email address:** Enter your email (for renewal notices)
   - Press Enter

2. **Terms of Service:** Type `A` and press Enter (to agree)

3. **Share email:** Type `Y` or `N` and press Enter

4. **Redirect HTTP to HTTPS:** Choose `2` (Redirect) and press Enter

### Certbot will:
- ✅ Get SSL certificate from Let's Encrypt
- ✅ Update Nginx configuration automatically
- ✅ Set up auto-renewal

### Test SSL:

```bash
curl https://api.easybasket.in/api/health
```

**Should work with HTTPS!**

### Test Auto-Renewal:

```bash
sudo certbot renew --dry-run
```

---

## 📱 Step 5: Update Mobile App

### Update API URL:

**File:** `mobile/lib/config/app_config.dart`

**Change from:**
```dart
static const String apiBaseUrl = 'http://localhost:3000/api';  // or current URL
```

**To:**
```dart
static const String apiBaseUrl = 'https://api.easybasket.in/api';  // Your domain
```

**Or if SSL not set up yet:**
```dart
static const String apiBaseUrl = 'http://api.easybasket.in/api';
```

### Rebuild App:

```bash
cd mobile
flutter clean
flutter pub get
flutter run -d chrome  # Test on web first
```

---

## ✅ Verification Checklist

- [ ] DNS resolves to EC2 IP (`ping api.easybasket.in`)
- [ ] Nginx config updated with domain name
- [ ] Nginx reloaded successfully
- [ ] API accessible via domain: `curl http://api.easybasket.in/api/health`
- [ ] SSL certificate installed (optional but recommended)
- [ ] HTTPS working: `curl https://api.easybasket.in/api/health`
- [ ] Mobile app updated with new domain URL

---

## 🎯 Final URLs

### After Setup:

**HTTP (if SSL not set up):**
- `http://api.easybasket.in/api/health`
- `http://api.easybasket.in/api/categories`
- `http://api.easybasket.in/api/products`

**HTTPS (recommended):**
- `https://api.easybasket.in/api/health`
- `https://api.easybasket.in/api/categories`
- `https://api.easybasket.in/api/products`

---

## 🐛 Troubleshooting

### Domain Not Resolving

**Check:**
```bash
nslookup api.easybasket.in
```

**If not showing your IP:**
- Wait longer (DNS can take up to 48 hours, usually 15-30 min)
- Double-check GoDaddy DNS settings
- Verify A record is correct

### "This site can't be reached"

**Check:**
1. DNS working? (`ping api.easybasket.in`)
2. Nginx running? (`sudo systemctl status nginx`)
3. Security group allows port 80? (AWS Console → EC2 → Security Groups)

**Fix:**
```bash
# Check Nginx
sudo systemctl status nginx
sudo systemctl start nginx  # If not running

# Check logs
sudo tail -f /var/log/nginx/easy-basket-error.log
```

### SSL Certificate Fails

**Check:**
1. Domain resolves to your IP?
2. Port 80 open in security group?
3. Nginx accessible via HTTP?

**Fix:**
- Ensure HTTP works first: `curl http://api.easybasket.in/api/health`
- Then try SSL again: `sudo certbot --nginx -d api.easybasket.in`

---

## 📋 Quick Command Summary

```bash
# 1. Connect to EC2
ssh -i your-key.pem ec2-user@13.60.76.140

# 2. Update Nginx
sudo nano /etc/nginx/conf.d/easy-basket.conf
# Change: server_name api.easybasket.in;

# 3. Test and reload
sudo nginx -t
sudo systemctl reload nginx

# 4. Test domain
curl http://api.easybasket.in/api/health

# 5. Get SSL (optional)
sudo certbot --nginx -d api.easybasket.in

# 6. Test HTTPS
curl https://api.easybasket.in/api/health
```

---

**Your domain `api.easybasket.in` will be ready! 🚀**

