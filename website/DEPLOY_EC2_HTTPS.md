# Deploy Website to EC2 with HTTPS (No CloudFront)

Since you don't want to use CloudFront, you can host the website on your existing EC2 instance with Nginx and Let's Encrypt SSL.

## Prerequisites
- ✅ EC2 instance running
- ✅ Nginx installed (or we'll install it)
- ✅ Domain `easyBasket.in` pointing to EC2 (or we'll set it up)

---

## Step 1: Upload Website Files to EC2

### Option A: Using SCP (from your local machine)

```bash
# Navigate to website directory
cd /Users/nikhil/Projects/easyBucket/website

# Upload files to EC2
scp -i ~/your-key.pem index.html styles.css script.js ubuntu@your-ec2-ip:/tmp/website/
```

### Option B: Using Git (if you have git on EC2)

```bash
# SSH into EC2
ssh -i ~/your-key.pem ubuntu@your-ec2-ip

# Clone or pull your repo
cd /tmp
git clone your-repo-url
# Or if repo already exists, just pull the website folder
```

### Option C: Direct Download from S3

```bash
# SSH into EC2
ssh -i ~/your-key.pem ubuntu@your-ec2-ip

# Install AWS CLI if not installed
sudo apt update
sudo apt install awscli -y

# Configure AWS credentials (if not already done)
aws configure

# Download files from S3
aws s3 sync s3://easybasket-website /tmp/website/
```

---

## Step 2: Install Nginx (if not already installed)

```bash
# SSH into EC2
ssh -i ~/your-key.pem ubuntu@your-ec2-ip

# Install Nginx
sudo apt update
sudo apt install nginx -y

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

---

## Step 3: Move Website Files to Nginx Directory

```bash
# Create website directory
sudo mkdir -p /var/www/easybasket.in

# Copy files (adjust path based on where you uploaded them)
sudo cp /tmp/website/* /var/www/easybasket.in/

# Or if files are in /tmp/website
sudo cp -r /tmp/website/* /var/www/easybasket.in/

# Set proper permissions
sudo chown -R www-data:www-data /var/www/easybasket.in
sudo chmod -R 755 /var/www/easybasket.in
```

---

## Step 4: Configure Nginx

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/easybasket.in
```

Add this configuration:

```nginx
server {
    listen 80;
    server_name easybasket.in www.easybasket.in;

    root /var/www/easybasket.in;
    index index.html;

    # Main location
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;
}
```

Save and exit (Ctrl+X, then Y, then Enter)

---

## Step 5: Enable the Site

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/easybasket.in /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# If test passes, reload Nginx
sudo systemctl reload nginx
```

---

## Step 6: Point Domain to EC2 (GoDaddy)

1. **Get your EC2 Public IP**
   ```bash
   # In EC2 console or run:
   curl ifconfig.me
   ```

2. **Update DNS in GoDaddy**
   - Log in to GoDaddy
   - Go to "My Products" → DNS for `easyBasket.in`
   - Find the A record for root domain (`@`)
   - Update the **Value** to your EC2 public IP
   - **TTL**: 600 (or 1 hour)
   - Click "Save"

3. **Optional: Add www record**
   - Add A record:
     - **Type**: A
     - **Name**: `www`
     - **Value**: Same EC2 public IP
     - **TTL**: 600
     - Click "Save"

---

## Step 7: Install SSL Certificate with Let's Encrypt

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Get SSL certificate (this will automatically configure Nginx)
sudo certbot --nginx -d easybasket.in -d www.easybasket.in

# Follow the prompts:
# - Enter your email
# - Agree to terms
# - Choose whether to redirect HTTP to HTTPS (recommended: Yes)
```

Certbot will:
- ✅ Automatically get SSL certificate from Let's Encrypt
- ✅ Configure Nginx for HTTPS
- ✅ Set up auto-renewal

---

## Step 8: Verify HTTPS Works

1. **Wait for DNS propagation** (5-30 minutes)
2. **Test the website**:
   - Visit: `http://easyBasket.in` (should redirect to HTTPS)
   - Visit: `https://easyBasket.in` (should show secure padlock)
3. **Check SSL**:
   - Visit: https://www.ssllabs.com/ssltest/analyze.html?d=easyBasket.in

---

## Step 9: Auto-Renewal (Already Set Up)

Certbot automatically sets up renewal. Test it:

```bash
# Test renewal process
sudo certbot renew --dry-run
```

Renewal runs automatically via cron job.

---

## Troubleshooting

### Website not loading
- Check Nginx status: `sudo systemctl status nginx`
- Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Verify files exist: `ls -la /var/www/easybasket.in/`
- Test Nginx config: `sudo nginx -t`

### SSL not working
- Check certificate: `sudo certbot certificates`
- Verify Nginx config: `sudo nginx -t`
- Check SSL logs: `sudo tail -f /var/log/letsencrypt/letsencrypt.log`

### DNS not resolving
- Wait 15-30 minutes for propagation
- Verify DNS: `nslookup easyBasket.in`
- Check GoDaddy DNS records

### Permission issues
```bash
sudo chown -R www-data:www-data /var/www/easybasket.in
sudo chmod -R 755 /var/www/easybasket.in
```

---

## Update Website Files

When you need to update the website:

```bash
# SSH into EC2
ssh -i ~/your-key.pem ubuntu@your-ec2-ip

# Upload new files (using SCP from local machine)
# Or download from S3
aws s3 sync s3://easybasket-website /tmp/website/

# Copy to Nginx directory
sudo cp -r /tmp/website/* /var/www/easybasket.in/

# Set permissions
sudo chown -R www-data:www-data /var/www/easybasket.in

# No need to restart Nginx for static files
```

---

## Cost

- **EC2**: Uses your existing instance (no extra cost)
- **Let's Encrypt SSL**: Free
- **Total**: $0 additional cost

---

## Summary

✅ Website hosted on your EC2 instance  
✅ HTTPS enabled with Let's Encrypt (free)  
✅ Auto-renewal configured  
✅ No CloudFront needed  
✅ Uses existing infrastructure  

Your website will be available at:
- `https://easyBasket.in` ✅
- `https://www.easyBasket.in` ✅
