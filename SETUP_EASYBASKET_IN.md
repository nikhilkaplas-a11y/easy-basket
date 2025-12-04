# 🌐 Setup easybasket.in Domain

Complete guide to configure your `easybasket.in` domain to point to your EC2 instance.

---

## 📋 Your Domain Details

- **Domain:** `easybasket.in`
- **EC2 IP:** `13.60.76.140`
- **Options:**
  - `easybasket.in` (root domain)
  - `api.easybasket.in` (subdomain - recommended for API)

---

## 🎯 Recommended Setup: Use Subdomain

**Use:** `api.easybasket.in` for your API
- Keeps main domain free for website
- Professional API URL
- Easy to add more subdomains later

---

## 🔧 Step 1: Access Your Domain Registrar

### Find Where You Bought the Domain

1. **Check your email** for domain purchase confirmation
2. **Common registrars:**
   - GoDaddy
   - Namecheap
   - Google Domains
   - Route 53 (AWS)
   - Others

3. **Log in** to your domain registrar account

---

## 🌐 Step 2: Configure DNS Records

### Option A: Use Subdomain (api.easybasket.in) - Recommended

1. **Go to DNS Management** (or DNS Settings, DNS Records)

2. **Add A Record:**
   - **Type:** A
   - **Name/Host:** `api`
   - **Value/Points to:** `13.60.76.140`
   - **TTL:** 300 (or 3600)
   - **Save**

3. **Result:** `api.easybasket.in` → `13.60.76.140`

### Option B: Use Root Domain (easybasket.in)

1. **Go to DNS Management**

2. **Add A Record:**
   - **Type:** A
   - **Name/Host:** `@` (or leave blank, or `easybasket.in`)
   - **Value/Points to:** `13.60.76.140`
   - **TTL:** 300
   - **Save**

3. **Result:** `easybasket.in` → `13.60.76.140`

---

## 📝 Step-by-Step for Popular Registrars

### GoDaddy

1. **Log in** → **My Products** → **DNS**

2. **Add Record:**
   - **Type:** A
   - **Name:** `api` (for subdomain) or `@` (for root)
   - **Value:** `13.60.76.140`
   - **TTL:** 600 seconds
   - **Save**

### Namecheap

1. **Log in** → **Domain List** → Click **Manage** next to `easybasket.in`

2. **Advanced DNS** tab

3. **Add New Record:**
   - **Type:** A Record
   - **Host:** `api` (for subdomain) or `@` (for root)
   - **Value:** `13.60.76.140`
   - **TTL:** Automatic (or 300)
   - **Save**

### Google Domains

1. **Log in** → **My domains** → Click `easybasket.in`

2. **DNS** tab

3. **Custom resource records:**
   - **Name:** `api` (for subdomain) or `@` (for root)
   - **Type:** A
   - **Data:** `13.60.76.140`
   - **TTL:** 3600
   - **Add**

### AWS Route 53

1. **Route 53** → **Hosted zones** → **Create hosted zone**

2. **Domain name:** `easybasket.in`
   - **Type:** Public hosted zone
   - **Create**

3. **Copy the 4 nameservers** (e.g., `ns-123.awsdns-12.com`)

4. **Update nameservers at your registrar:**
   - Go to your domain registrar
   - Update nameservers to Route 53 nameservers
   - Save

5. **Create A record in Route 53:**
   - **Record name:** `api` (for subdomain) or leave blank (for root)
   - **Record type:** A
   - **Value:** `13.60.76.140`
   - **TTL:** 300
   - **Create records**

---

## ⏱️ Step 3: Wait for DNS Propagation

**Time:** 15 minutes to 48 hours (usually 15-30 minutes)

### Check if DNS is Working:

```bash
# From your local machine
ping api.easybasket.in

# Or
nslookup api.easybasket.in

# Should show: 13.60.76.140
```

**Online Check:**
- Go to: https://dnschecker.org
- Enter: `api.easybasket.in`
- Check if it shows your EC2 IP: `13.60.76.140`

---

## ⚙️ Step 4: Update Nginx Configuration

### On EC2:

```bash
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

### Update server_name:

**For subdomain (api.easybasket.in):**
```nginx
server {
    listen 80;
    server_name api.easybasket.in;  # Your subdomain

    # ... rest of config
}
```

**For root domain (easybasket.in):**
```nginx
server {
    listen 80;
    server_name easybasket.in www.easybasket.in;  # Root domain

    # ... rest of config
}
```

**Or accept both:**
```nginx
server {
    listen 80;
    server_name api.easybasket.in easybasket.in 13.60.76.140;  # All

    # ... rest of config
}
```

### Test and Reload:

```bash
# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

---

## 🧪 Step 5: Test Domain

### After DNS Propagates:

```bash
# Test subdomain
curl http://api.easybasket.in/api/health

# Or test root domain
curl http://easybasket.in/api/health
```

**Should return:** JSON response from your API

---

## 🔐 Step 6: Set Up SSL (HTTPS) - Recommended

### Install Certbot:

```bash
sudo yum install -y certbot python3-certbot-nginx
```

### Get SSL Certificate:

**For subdomain:**
```bash
sudo certbot --nginx -d api.easybasket.in
```

**For root domain:**
```bash
sudo certbot --nginx -d easybasket.in -d www.easybasket.in
```

**For both:**
```bash
sudo certbot --nginx -d api.easybasket.in -d easybasket.in
```

### Follow Prompts:

1. **Email:** Enter your email
2. **Terms:** Type `A` and press Enter
3. **Share email:** Type `Y` or `N`
4. **Redirect:** Choose `2` (Redirect HTTP to HTTPS)

### Test Auto-Renewal:

```bash
sudo certbot renew --dry-run
```

---

## 📱 Step 7: Update Mobile App

### Update API URL:

**File:** `mobile/lib/config/app_config.dart`

**For subdomain:**
```dart
class AppConfig {
  // Production API URL
  static const String apiBaseUrl = 'https://api.easybasket.in/api';
  // Or HTTP (if SSL not set up yet):
  // static const String apiBaseUrl = 'http://api.easybasket.in/api';
}
```

**For root domain:**
```dart
class AppConfig {
  static const String apiBaseUrl = 'https://easybasket.in/api';
}
```

---

## ✅ Complete Setup Checklist

- [ ] Domain `easybasket.in` purchased/owned
- [ ] DNS A record added (api or @)
- [ ] DNS record points to `13.60.76.140`
- [ ] DNS propagated (checked with ping/nslookup)
- [ ] Nginx config updated with domain name
- [ ] Nginx reloaded
- [ ] Tested: `curl http://api.easybasket.in/api/health`
- [ ] SSL certificate installed (optional)
- [ ] Mobile app updated with new domain URL

---

## 🎯 Recommended Final URLs

### API Endpoints:
- `https://api.easybasket.in/api/health`
- `https://api.easybasket.in/api/categories`
- `https://api.easybasket.in/api/products`

### Or Root Domain:
- `https://easybasket.in/api/health`
- `https://easybasket.in/api/categories`

---

## 🔍 Verify DNS Setup

### Command Line:

```bash
# Check DNS resolution
nslookup api.easybasket.in

# Should show:
# Name: api.easybasket.in
# Address: 13.60.76.140
```

### Online:

1. Go to: https://dnschecker.org
2. Enter: `api.easybasket.in`
3. Select: A record
4. Check if all locations show: `13.60.76.140`

---

## 🐛 Troubleshooting

### Domain Not Resolving

**Check:**
1. DNS record added correctly?
2. TTL expired? (wait longer)
3. Wrong nameservers? (if using Route 53)

**Fix:**
- Verify A record at registrar
- Wait 30 more minutes
- Check nameservers match

### "This site can't be reached"

**Check:**
1. DNS pointing to correct IP?
2. Security group allows port 80?
3. Nginx running?

**Fix:**
```bash
# Check Nginx
sudo systemctl status nginx

# Check security group (port 80 open)
# Check DNS: nslookup api.easybasket.in
```

### SSL Certificate Fails

**Check:**
1. Domain resolves to your IP?
2. Port 80 open in security group?
3. Nginx accessible?

**Fix:**
- Ensure domain works first: `curl http://api.easybasket.in`
- Then try SSL: `sudo certbot --nginx -d api.easybasket.in`

---

## 📋 Quick Setup Summary

1. **Add DNS A Record:**
   - Name: `api`
   - Value: `13.60.76.140`

2. **Wait 15-30 minutes** (DNS propagation)

3. **Update Nginx:**
   ```bash
   sudo nano /etc/nginx/conf.d/easy-basket.conf
   # Change: server_name api.easybasket.in;
   sudo systemctl reload nginx
   ```

4. **Test:**
   ```bash
   curl http://api.easybasket.in/api/health
   ```

5. **Get SSL:**
   ```bash
   sudo certbot --nginx -d api.easybasket.in
   ```

---

## 💡 Pro Tips

1. **Use subdomain:** `api.easybasket.in` (keeps root free)
2. **Get SSL:** Always use HTTPS in production
3. **Test locally:** Use `/etc/hosts` to test before DNS
4. **Keep IP access:** Add IP to server_name so both work

---

**Your domain `easybasket.in` will be ready! 🚀**

