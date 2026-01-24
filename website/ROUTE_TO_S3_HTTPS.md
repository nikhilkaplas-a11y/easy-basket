# Route Domain to S3 with HTTPS (No CloudFront)

You want to route `easyBasket.in` to your S3 website URL (`http://easybasket-website.s3-website.ap-south-1.amazonaws.com`) with HTTPS, without using CloudFront.

## The Challenge

S3 static website hosting only provides **HTTP**, not HTTPS. To get HTTPS when routing to S3, you need a proxy/CDN layer.

## Solution Options

### Option 1: Cloudflare (Recommended - Free & Easy) ⭐

Cloudflare provides free HTTPS proxy in front of your S3 bucket.

#### Step 1: Sign Up for Cloudflare (Free)

1. Go to [cloudflare.com](https://cloudflare.com) and sign up (free plan)
2. Add your domain `easyBasket.in`
3. Cloudflare will scan your existing DNS records

#### Step 2: Update Nameservers in GoDaddy

1. Cloudflare will give you nameservers (e.g., `ns1.cloudflare.com`, `ns2.cloudflare.com`)
2. In GoDaddy:
   - Go to "My Products" → Domain Settings for `easyBasket.in`
   - Click "Manage DNS" or "Change Nameservers"
   - Replace GoDaddy nameservers with Cloudflare nameservers
   - Save

#### Step 3: Add DNS Record in Cloudflare

1. In Cloudflare dashboard, go to DNS settings
2. Add a CNAME record:
   - **Type**: CNAME
   - **Name**: `@` (for root domain) or `www` (for www)
   - **Target**: `easybasket-website.s3-website.ap-south-1.amazonaws.com`
   - **Proxy status**: ✅ Proxied (orange cloud icon) - **This enables HTTPS**
   - Click "Save"

3. For www subdomain (optional):
   - Add another CNAME:
     - **Name**: `www`
     - **Target**: `easybasket-website.s3-website.ap-south-1.amazonaws.com`
     - **Proxy status**: ✅ Proxied
     - Click "Save"

#### Step 4: Configure SSL in Cloudflare

1. Go to SSL/TLS settings in Cloudflare
2. Set SSL/TLS encryption mode to **"Full"** or **"Full (strict)"**
3. Cloudflare automatically provides SSL certificate (free)

#### Step 5: Wait for DNS Propagation

- Wait 5-30 minutes for nameserver changes to propagate
- Your site will be available at `https://easyBasket.in` ✅

**Benefits:**
- ✅ Free HTTPS
- ✅ Free CDN (faster than direct S3)
- ✅ DDoS protection
- ✅ Easy to set up
- ✅ No EC2 needed

---

### Option 2: EC2 Reverse Proxy (Uses Your Existing Infrastructure)

Use your EC2 instance as a reverse proxy that forwards requests to S3 and adds HTTPS.

#### Step 1: Install Nginx on EC2

```bash
# SSH into EC2
ssh -i ~/your-key.pem ubuntu@your-ec2-ip

# Install Nginx
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### Step 2: Configure Nginx as Reverse Proxy

```bash
sudo nano /etc/nginx/sites-available/easybasket.in
```

Add this configuration:

```nginx
server {
    listen 80;
    server_name easybasket.in www.easybasket.in;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name easybasket.in www.easybasket.in;

    # SSL Certificate (we'll get this with Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/easybasket.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/easybasket.in/privkey.pem;

    # Proxy to S3
    location / {
        proxy_pass http://easybasket-website.s3-website.ap-south-1.amazonaws.com;
        proxy_set_header Host easybasket-website.s3-website.ap-south-1.amazonaws.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Handle redirects from S3
        proxy_redirect off;
    }

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg)$ {
        proxy_pass http://easybasket-website.s3-website.ap-south-1.amazonaws.com;
        proxy_set_header Host easybasket-website.s3-website.ap-south-1.amazonaws.com;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Save and exit.

#### Step 3: Get SSL Certificate

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get certificate
sudo certbot --nginx -d easybasket.in -d www.easybasket.in

# Follow prompts (email, agree to terms, redirect HTTP to HTTPS: Yes)
```

#### Step 4: Enable Site and Test

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/easybasket.in /etc/nginx/sites-enabled/

# Remove default (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

#### Step 5: Point Domain to EC2

1. Get your EC2 public IP
2. In GoDaddy DNS:
   - Update A record for `@` (root domain) to point to EC2 IP
   - Add A record for `www` pointing to EC2 IP (optional)

**Benefits:**
- ✅ Uses existing EC2 infrastructure
- ✅ Free SSL (Let's Encrypt)
- ✅ Full control

---

### Option 3: Direct CNAME to S3 (HTTP Only - No HTTPS)

If you're okay with HTTP only (not recommended for production):

1. In GoDaddy DNS:
   - Add CNAME record:
     - **Type**: CNAME
     - **Name**: `@` (or leave blank for root)
     - **Value**: `easybasket-website.s3-website.ap-south-1.amazonaws.com`
     - **TTL**: 600

**Limitations:**
- ❌ No HTTPS (HTTP only)
- ❌ Browser will show "Not Secure"
- ❌ Not recommended for production

---

## Comparison

| Option | HTTPS | Cost | Setup | Performance |
|--------|-------|------|-------|-------------|
| **Cloudflare** | ✅ Yes | Free | Easy | Fast (CDN) |
| **EC2 Proxy** | ✅ Yes | Free* | Medium | Good |
| **Direct S3** | ❌ No | Free | Easy | Good |

*EC2 cost if you already have it running

## Recommendation

**Use Cloudflare (Option 1)** because:
- ✅ Free HTTPS
- ✅ Free CDN (faster than direct S3)
- ✅ Easy setup (just change nameservers)
- ✅ No server management needed
- ✅ DDoS protection included

## Quick Setup with Cloudflare

1. Sign up at cloudflare.com (free)
2. Add domain `easyBasket.in`
3. Update nameservers in GoDaddy
4. Add CNAME: `@` → `easybasket-website.s3-website.ap-south-1.amazonaws.com` (with proxy enabled)
5. Wait 15-30 minutes
6. Done! ✅ `https://easyBasket.in` will work

---

## Important Notes

### For Cloudflare:
- Keep your wildcard `*.easyBasket.in` DNS record in GoDaddy (it will be migrated to Cloudflare)
- Your `api.easyBasket.in` will continue to work (covered by wildcard)
- You can add specific records in Cloudflare to override wildcard if needed

### For EC2 Proxy:
- Make sure EC2 security group allows HTTP (80) and HTTPS (443) traffic
- EC2 must be running 24/7 for website to work
- Uses your existing EC2 resources

---

## Troubleshooting

### Cloudflare: Site not loading
- Wait 15-30 minutes for DNS propagation
- Check DNS records in Cloudflare dashboard
- Verify proxy is enabled (orange cloud icon)

### EC2 Proxy: 502 Bad Gateway
- Check Nginx error logs: `sudo tail -f /var/log/nginx/error.log`
- Verify S3 bucket name is correct in Nginx config
- Test S3 URL directly: `curl http://easybasket-website.s3-website.ap-south-1.amazonaws.com`

### SSL Certificate Issues
- For Cloudflare: SSL is automatic, just enable proxy
- For EC2: Run `sudo certbot renew --dry-run` to test renewal
