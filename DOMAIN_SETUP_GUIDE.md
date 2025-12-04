# 🌐 Complete Domain Setup Guide for Easy Basket

Step-by-step guide to configure a custom domain name for your EC2 instance.

---

## 📋 What is Domain Configuration?

Instead of accessing your API via IP address (`http://13.60.76.140`), you can use a custom domain like:
- `http://api.easybasket.com`
- `http://easybasket.com`
- `http://api.yourdomain.com`

**Benefits:**
- Professional URL
- Easy to remember
- Can add SSL certificate easily
- Better for production

---

## 🎯 Step 1: Get a Domain Name

### Option 1: Buy a New Domain

**Popular Domain Registrars:**
- **Namecheap:** https://www.namecheap.com
- **GoDaddy:** https://www.godaddy.com
- **Google Domains:** https://domains.google
- **Route 53:** AWS's own service

**Cost:** Usually $10-15/year for `.com` domains

### Option 2: Use Existing Domain

If you already have a domain, you can use it.

---

## 🔧 Step 2: Choose Your Domain Structure

### Option A: Subdomain (Recommended)
- `api.easybasket.com` - For API
- `www.easybasket.com` - For website (future)
- `admin.easybasket.com` - For admin panel (future)

### Option B: Root Domain
- `easybasket.com` - Direct domain

### Option C: Both
- `easybasket.com` - Main site
- `api.easybasket.com` - API

**For now, we'll use:** `api.easybasket.com` (or your choice)

---

## 🌐 Step 3: Configure DNS Records

### Method 1: Using Your Domain Registrar (Easiest)

1. **Log in to your domain registrar** (Namecheap, GoDaddy, etc.)

2. **Go to DNS Management** (or DNS Settings)

3. **Add A Record:**
   - **Type:** A
   - **Name/Host:** `api` (for api.yourdomain.com) or `@` (for root domain)
   - **Value/Points to:** `13.60.76.140` (your EC2 public IP)
   - **TTL:** 300 (or default)

4. **Save changes**

5. **Wait 5-15 minutes** for DNS to propagate

### Method 2: Using AWS Route 53 (More Control)

#### 3.1 Create Hosted Zone

1. **AWS Console** → **Route 53** → **Hosted zones**

2. **Create hosted zone**

3. **Enter domain name:** `easybasket.com` (your domain)

4. **Type:** Public hosted zone

5. **Create**

6. **Copy the 4 nameservers** shown (e.g., `ns-123.awsdns-12.com`)

#### 3.2 Update Nameservers at Registrar

1. **Go to your domain registrar** (where you bought the domain)

2. **Find "Nameservers" or "DNS" settings**

3. **Change nameservers** to the 4 Route 53 nameservers you copied

4. **Save**

5. **Wait 24-48 hours** for propagation (usually faster)

#### 3.3 Create A Record in Route 53

1. **In Route 53** → Your hosted zone → **Create record**

2. **Record configuration:**
   - **Record name:** `api` (for api.easybasket.com)
   - **Record type:** A
   - **Value:** `13.60.76.140` (your EC2 IP)
   - **TTL:** 300
   - **Routing policy:** Simple routing

3. **Create records**

---

## ⚙️ Step 4: Update Nginx Configuration

### Get Your Domain Ready

Once DNS propagates (check with `ping api.yourdomain.com`), update Nginx:

```bash
# Edit Nginx config
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

### Update Configuration:

```nginx
server {
    listen 80;
    server_name api.easybasket.com;  # Your domain here

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

**Or if you want to accept both IP and domain:**

```nginx
server {
    listen 80;
    server_name api.easybasket.com 13.60.76.140;  # Both domain and IP

    # ... rest of config
}
```

### Reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🧪 Step 5: Test Domain

### Check DNS Propagation:

```bash
# From your local machine
ping api.easybasket.com

# Should show your EC2 IP: 13.60.76.140
```

### Test API via Domain:

```bash
# Test health endpoint
curl http://api.easybasket.com/api/health

# Test categories
curl http://api.easybasket.com/api/categories
```

---

## 🔐 Step 6: Set Up SSL (HTTPS) - Recommended

### Install Certbot:

```bash
sudo yum install -y certbot python3-certbot-nginx
```

### Get SSL Certificate:

```bash
# For subdomain
sudo certbot --nginx -d api.easybasket.com

# For root domain
sudo certbot --nginx -d easybasket.com

# For both
sudo certbot --nginx -d api.easybasket.com -d easybasket.com
```

### Follow Prompts:

1. **Enter email address** (for renewal notices)
2. **Agree to terms** (type `A` and press Enter)
3. **Share email** (optional, type `Y` or `N`)
4. **Choose redirect:** `2` (Redirect HTTP to HTTPS)

### Certbot will automatically:
- Get SSL certificate from Let's Encrypt
- Update Nginx configuration
- Set up auto-renewal

### Test Auto-Renewal:

```bash
sudo certbot renew --dry-run
```

---

## 📋 Complete Example: api.easybasket.com

### 1. Buy Domain: `easybasket.com`

### 2. Add DNS Record:
- **Type:** A
- **Name:** `api`
- **Value:** `13.60.76.140`
- **TTL:** 300

### 3. Wait for DNS (5-15 minutes)

### 4. Update Nginx:
```nginx
server_name api.easybasket.com;
```

### 5. Get SSL:
```bash
sudo certbot --nginx -d api.easybasket.com
```

### 6. Test:
```bash
curl https://api.easybasket.com/api/health
```

---

## 🎯 DNS Record Types Explained

### A Record
- **Purpose:** Points domain to IP address
- **Example:** `api.easybasket.com` → `13.60.76.140`
- **Use for:** Direct IP mapping

### CNAME Record
- **Purpose:** Points domain to another domain
- **Example:** `www.easybasket.com` → `easybasket.com`
- **Use for:** Aliases

### For Your API:
- **Use A Record** pointing to your EC2 IP

---

## 🔍 Check DNS Propagation

### Online Tools:
- **DNS Checker:** https://dnschecker.org
- Enter: `api.easybasket.com`
- Check if it shows your EC2 IP

### Command Line:

```bash
# Check DNS
nslookup api.easybasket.com

# Or
dig api.easybasket.com

# Should show your EC2 IP: 13.60.76.140
```

---

## 🐛 Troubleshooting

### Domain Not Resolving

**Cause:** DNS not propagated yet

**Fix:**
- Wait 15-30 minutes
- Check DNS settings at registrar
- Verify A record is correct

### "This site can't be reached"

**Cause:** DNS pointing to wrong IP or not propagated

**Fix:**
```bash
# Check what IP domain resolves to
nslookup api.easybasket.com

# Should show: 13.60.76.140
# If different, check DNS settings
```

### Nginx Shows Default Page

**Cause:** Wrong server_name in config

**Fix:**
```bash
# Check Nginx config
sudo cat /etc/nginx/conf.d/easy-basket.conf | grep server_name

# Should match your domain
# Update if needed and reload
```

### SSL Certificate Fails

**Cause:** Domain not pointing to server or port 80 blocked

**Fix:**
- Ensure domain resolves to your IP
- Ensure port 80 is open in security group
- Try again: `sudo certbot --nginx -d api.easybasket.com`

---

## 📝 Quick Setup Checklist

- [ ] Domain purchased/available
- [ ] A record created pointing to EC2 IP
- [ ] DNS propagated (checked with ping/nslookup)
- [ ] Nginx config updated with domain name
- [ ] Nginx reloaded
- [ ] Tested: `curl http://api.easybasket.com/api/health`
- [ ] SSL certificate installed (optional but recommended)
- [ ] Mobile app updated with new domain URL

---

## 🎯 Example: Complete Setup

### Domain: `api.easybasket.com`

**1. DNS Setup (at registrar):**
```
Type: A
Name: api
Value: 13.60.76.140
TTL: 300
```

**2. Nginx Config:**
```nginx
server_name api.easybasket.com;
```

**3. SSL Setup:**
```bash
sudo certbot --nginx -d api.easybasket.com
```

**4. Final URL:**
```
https://api.easybasket.com/api/health
```

---

## 💡 Tips

1. **Use subdomain for API:** `api.yourdomain.com` (keeps main domain free)
2. **Wait for DNS:** Can take 5 minutes to 48 hours (usually 15-30 min)
3. **Get SSL:** Always use HTTPS in production
4. **Test locally first:** Use `/etc/hosts` to test before DNS propagates

---

## 🔧 Test Domain Locally (Before DNS)

Edit `/etc/hosts` on your local machine:

```bash
# On Mac/Linux
sudo nano /etc/hosts

# Add this line:
13.60.76.140 api.easybasket.com

# Save and test
curl http://api.easybasket.com/api/health
```

This lets you test the domain before DNS propagates!

---

**Your API will be accessible via your custom domain! 🚀**

