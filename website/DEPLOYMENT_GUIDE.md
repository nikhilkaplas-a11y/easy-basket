# Easy Basket Website Deployment Guide

This guide will help you deploy the Easy Basket landing page to your domain **easyBasket.in**.

## 🎯 Quick Overview

The website is a static HTML/CSS/JS site that can be deployed using multiple methods. We'll cover the best options for your setup.

## 📝 GoDaddy Users - Quick Reference

If you're using **GoDaddy** for your domain (easyBasket.in), here's what you need to know:

- ✅ **SSL Certificate Validation**: Add CNAME records in GoDaddy DNS (see Step 3)
- ✅ **Domain Configuration**: Point domain to CloudFront using CNAME or A record (see Step 5)
- ⚠️ **Note**: GoDaddy may not allow CNAME at root domain - if so, consider using Route 53 for DNS (free, better CloudFront integration)
- 📍 **GoDaddy DNS Location**: My Products → DNS (or Manage DNS) → Records section
- 🌐 **Wildcard DNS**: You have `*.easyBasket.in` wildcard record - this covers all subdomains (api, www, etc.)
  - **Important**: Wildcard does NOT cover root domain (`easyBasket.in`) - you still need a specific record for that

---

## Option 1: AWS S3 + CloudFront (Recommended)

This is the best option if you want:
- ✅ Fast global CDN delivery
- ✅ Low cost (S3 is very cheap for static sites)
- ✅ SSL certificate via AWS Certificate Manager
- ✅ Easy to maintain
- ✅ Scales automatically

### Domain Structure Overview

Your domain setup will be:
- **`easyBasket.in`** → Website (CloudFront) ← **We're setting this up** (needs specific DNS record)
- **`www.easyBasket.in`** → Website (CloudFront) ← Optional (covered by wildcard `*.easyBasket.in`)
- **`api.easyBasket.in`** → API Server (Existing) ← **Covered by wildcard `*.easyBasket.in`**

**About Wildcard DNS (`*.easyBasket.in`):**
- ✅ Covers all subdomains: `api`, `www`, `admin`, `test`, etc.
- ❌ Does NOT cover root domain: `easyBasket.in` needs its own record
- 🔒 If you have a specific subdomain record (e.g., `api`), it takes precedence over the wildcard
- 📝 You only need to add a DNS record for the root domain (`easyBasket.in`)

### Step 1: Create S3 Bucket

1. **Go to AWS S3 Console**
   - Navigate to S3 service
   - Click "Create bucket"

2. **Bucket Configuration**
   - **Bucket name**: `easybasket-website` (or any unique name)
   - **Region**: Choose your preferred region (e.g., `ap-south-1` for Mumbai)
   - **Uncheck**: "Block all public access" (we need public access for website)
   - **Enable**: "Bucket Versioning" (optional but recommended)
   - Click "Create bucket"

3. **Enable Static Website Hosting**
   - Click on your bucket
   - Go to "Properties" tab
   - Scroll to "Static website hosting"
   - Click "Edit"
   - Enable "Static website hosting"
   - **Index document**: `index.html`
   - **Error document**: `index.html` (for SPA routing)
   - Click "Save changes"

4. **Set Bucket Policy**
   - Go to "Permissions" tab
   - Click "Bucket policy"
   - Add this policy (replace `YOUR-BUCKET-NAME`):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
        }
    ]
}
```

### Step 2: Upload Website Files

1. **Upload files to S3**
   ```bash
   cd website
   aws s3 sync . s3://YOUR-BUCKET-NAME --delete
   ```

   Or manually:
   - Click "Upload" in S3 console
   - Upload `index.html`, `styles.css`, and `script.js`
   - Make sure all files are set to "Public read"

2. **Get Website URL**
   - Go to "Properties" → "Static website hosting"
   - Copy the "Bucket website endpoint" URL
   - It will look like: `http://YOUR-BUCKET-NAME.s3-website-ap-south-1.amazonaws.com`

### Step 3: Request SSL Certificate

1. **Go to AWS Certificate Manager (ACM)**
   - Navigate to Certificate Manager
   - Make sure you're in the same region as CloudFront (us-east-1 for CloudFront)
   - Click "Request certificate"

2. **Certificate Configuration**
   - Choose "Request a public certificate"
   - **Domain name**: `easyBasket.in`
   - **Additional names**: 
     - `*.easyBasket.in` (wildcard - covers all subdomains including api, www, etc.)
     - `www.easyBasket.in` (optional, but recommended for explicit www support)
   - **Validation method**: DNS validation (recommended)
   - Click "Request"
   
   **Note**: Including `*.easyBasket.in` in the certificate will cover all your subdomains (api, www, etc.) with SSL, which is recommended since you're using a wildcard DNS record.

3. **Validate Certificate (GoDaddy)**
   - Click on the certificate
   - Go to "Domains" section
   - You'll see CNAME records that need to be added (one for each domain)
   - **For GoDaddy DNS:**
     1. Log in to your GoDaddy account
     2. Go to "My Products" → Click "DNS" next to your domain `easyBasket.in`
     3. Scroll down to "Records" section
     4. Click "Add" to create a new record
     5. **For root domain (`easyBasket.in`):**
        - **Type**: CNAME
        - **Name**: Copy the "Name" value from AWS (e.g., `_abc123def456.easyBasket.in` or just the prefix part)
        - **Value**: Copy the "Value" from AWS (e.g., `_xyz789.acm-validations.aws.`)
        - **TTL**: 600 (or 1 hour)
        - Click "Save"
     6. **For wildcard (`*.easyBasket.in`):**
        - Click "Add" to create another record
        - **Type**: CNAME
        - **Name**: Copy the "Name" value from AWS (e.g., `_abc123def456.*.easyBasket.in` or just the prefix part)
        - **Value**: Copy the "Value" from AWS (should be different from root domain)
        - **TTL**: 600 (or 1 hour)
        - Click "Save"
     7. **For www subdomain (if added explicitly):**
        - Repeat step 4-5 with the www CNAME record from AWS
   - Wait for validation (usually 5-30 minutes)
   - AWS will automatically detect the records and validate
   - Certificate status will change to "Issued" when validated
   
   **Note**: You'll need to add validation CNAME records for each domain you included in the certificate (root domain, wildcard, and optionally www).

### Step 4: Create CloudFront Distribution

1. **Go to CloudFront Console**
   - Navigate to CloudFront
   - Click "Create distribution"

2. **Origin Configuration**
   - **Origin domain**: Select your S3 bucket (the one with website endpoint, not the regular bucket)
   - **Origin path**: Leave empty
   - **Name**: Auto-filled

3. **Default Cache Behavior**
   - **Viewer protocol policy**: Redirect HTTP to HTTPS
   - **Allowed HTTP methods**: GET, HEAD
   - **Cache policy**: CachingOptimized (or create custom)

4. **Distribution Settings**
   - **Price class**: Use all edge locations (or choose based on your audience)
   - **Alternate domain names (CNAMEs)**: 
     - `easyBasket.in` (required - root domain)
     - `www.easyBasket.in` (optional - explicit www support)
     - **Note**: You don't need to add `*.easyBasket.in` here - CloudFront doesn't support wildcard CNAMEs. The wildcard DNS record will handle routing subdomains, but CloudFront only accepts specific domain names.
   - **SSL certificate**: Select the certificate you created (should include `easyBasket.in`, `*.easyBasket.in`, and optionally `www.easyBasket.in`)
   - **Default root object**: `index.html`
   - Click "Create distribution"

5. **Wait for Deployment**
   - CloudFront takes 10-15 minutes to deploy
   - Status will change from "In Progress" to "Deployed"

### Step 5: Configure DNS (GoDaddy)

1. **Log in to GoDaddy**
   - Go to [godaddy.com](https://godaddy.com) and sign in
   - Click "My Products"
   - Find `easyBasket.in` and click "DNS" (or "Manage DNS")

2. **Important: Existing DNS Records**
   - You have a **wildcard DNS record** `*.easyBasket.in` that covers all subdomains
   - This means `api.easyBasket.in`, `www.easyBasket.in`, and any other subdomain are already covered
   - **DO NOT modify or delete the wildcard record** - it will continue to work for all subdomains
   - **You only need to add ONE record**: for the root domain (`easyBasket.in`)
   - Your DNS records will look like:
     - `*` → CNAME → (your existing wildcard target) ✅ Keep this
     - `@` → (new record for website root domain) ← **Add this only**
   
   **How Wildcard Works:**
   - `*.easyBasket.in` matches: `api.easyBasket.in`, `www.easyBasket.in`, `admin.easyBasket.in`, etc.
   - `*.easyBasket.in` does NOT match: `easyBasket.in` (root domain needs its own record)
   - If you have both wildcard and specific records (e.g., `api`), the specific record takes precedence

3. **Point Domain to CloudFront**
   
   **For root domain (`easyBasket.in`):**
   - Scroll to "Records" section
   - Look for existing A record with Name `@` (or blank)
   - **Option A - Use CNAME (Recommended for CloudFront):**
     - If there's an A record, you may need to delete it first (GoDaddy allows CNAME at root for some setups)
     - Click "Add" to create new record
     - **Type**: CNAME
     - **Name**: `@` (or leave blank for root domain)
     - **Value**: Your CloudFront distribution domain (e.g., `d1234567890.cloudfront.net`)
     - **TTL**: 600 (or 1 hour)
     - Click "Save"
   
   **Option B - Use A Record (If CNAME not allowed at root):**
     - GoDaddy may not allow CNAME at root - in that case:
     - Click "Add" to create new record
     - **Type**: A
     - **Name**: `@` (or leave blank)
     - **Value**: You'll need to get the IP from CloudFront (not recommended, use Route 53 Alias instead)
     - **Note**: For root domain with CloudFront, it's better to use Route 53 with Alias record, or use CNAME if GoDaddy supports it

   **For www subdomain (optional):**
   - **Note**: `www.easyBasket.in` is already covered by your wildcard `*.easyBasket.in`
   - If the wildcard points to your API server, you may want to add a specific `www` record to override it:
     - Click "Add" to create new record
     - **Type**: CNAME
     - **Name**: `www`
     - **Value**: Your CloudFront distribution domain (e.g., `d1234567890.cloudfront.net`)
     - **TTL**: 600 (or 1 hour)
     - Click "Save"
   - **Or**: If you want `www` to also point to CloudFront, you can leave it covered by wildcard (if wildcard points to CloudFront) or add the specific record above

3. **Important Notes for GoDaddy:**
   - **CNAME at root**: Some GoDaddy accounts support CNAME at root, some don't
   - **If CNAME not allowed**: Consider using AWS Route 53 for DNS management (free hosted zone, just pay for queries)
   - **DNS Propagation**: Changes take 5 minutes to 48 hours (usually 15-30 minutes)
   - **Verify**: Use `nslookup easyBasket.in` or `dig easyBasket.in` to check DNS

4. **Alternative: Use Route 53 (Recommended)**
   If GoDaddy doesn't support CNAME at root, transfer DNS to Route 53:
   - Create hosted zone in Route 53 for `easyBasket.in`
   - Update nameservers in GoDaddy to point to Route 53
   - Create Alias A record in Route 53 pointing to CloudFront (this works perfectly)

### Step 6: Test Your Website

1. Wait for DNS propagation (5 minutes to 48 hours, usually 15-30 minutes)
2. Visit `https://easyBasket.in`
3. Test all pages and links
4. **Verify API subdomain still works**: Check that `https://api.easyBasket.in` still points to your API (should be unaffected)

---

## Option 2: Deploy on Existing EC2 Instance

If you want to host on your existing EC2 instance:

### Step 1: Install Nginx

```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Step 2: Upload Website Files

```bash
# Create website directory
sudo mkdir -p /var/www/easybasket.in

# Upload files (use scp or git)
cd website
sudo cp -r * /var/www/easybasket.in/

# Set permissions
sudo chown -R www-data:www-data /var/www/easybasket.in
sudo chmod -R 755 /var/www/easybasket.in
```

### Step 3: Configure Nginx

Create nginx config file:

```bash
sudo nano /etc/nginx/sites-available/easybasket.in
```

Add this configuration:

```nginx
server {
    listen 80;
    server_name easybasket.in www.easybasket.in;

    root /var/www/easybasket.in;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/easybasket.in /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Step 4: Setup SSL with Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d easybasket.in -d www.easybasket.in
```

Follow the prompts. Certbot will automatically configure SSL.

### Step 5: Configure DNS

Point your domain to your EC2 instance IP:
- **Type**: A
- **Name**: `@`
- **Value**: Your EC2 public IP
- **TTL**: 300

---

## Option 3: Deploy on Netlify (Easiest)

1. **Create Netlify Account**
   - Go to [netlify.com](https://netlify.com)
   - Sign up for free

2. **Deploy**
   - Drag and drop the `website` folder to Netlify dashboard
   - Or connect GitHub repository

3. **Custom Domain**
   - Go to Site settings → Domain management
   - Add custom domain: `easyBasket.in`
   - Follow DNS instructions

4. **SSL**
   - Netlify automatically provides SSL via Let's Encrypt

---

## Option 4: Deploy on Vercel

1. **Install Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **Deploy**
   ```bash
   cd website
   vercel
   ```

3. **Add Custom Domain**
   - Go to Vercel dashboard
   - Add domain: `easyBasket.in`
   - Configure DNS as instructed

---

## 📋 Pre-Deployment Checklist

- [ ] Test website locally (open `index.html` in browser)
- [ ] Verify all links work
- [ ] Check mobile responsiveness
- [ ] Test download buttons (they show "Launching Soon" alert)
- [ ] Ensure images/assets load correctly
- [ ] Check browser console for errors

---

## 🔧 Post-Deployment Tasks

1. **Update Download Links**
   - When apps are published, update the download button URLs in `index.html`
   - Replace `href="#"` with actual Google Play and App Store links

2. **Add Analytics** (Optional)
   - Add Google Analytics or similar
   - Add tracking code before `</head>` in `index.html`

3. **SEO Optimization**
   - The site already has meta descriptions
   - Consider adding Open Graph tags for social sharing
   - Submit sitemap to Google Search Console

4. **Monitor Performance**
   - Use Google PageSpeed Insights
   - Monitor uptime (if using CloudFront, it's 99.99% uptime)

---

## 🚀 Quick Deploy Script (S3)

Create a file `deploy.sh` in the website directory:

```bash
#!/bin/bash

BUCKET_NAME="easybasket-website"
REGION="ap-south-1"

echo "Deploying Easy Basket website to S3..."

# Build (if needed)
# No build step for static site

# Upload to S3
aws s3 sync . s3://$BUCKET_NAME \
    --region $REGION \
    --delete \
    --exclude "*.md" \
    --exclude ".git/*" \
    --exclude "deploy.sh"

echo "Deployment complete!"
echo "Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
```

Make it executable:
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 💰 Cost Estimates

### AWS S3 + CloudFront
- **S3 Storage**: ~$0.023 per GB/month (first 50TB)
- **S3 Requests**: ~$0.0004 per 1,000 requests
- **CloudFront**: ~$0.085 per GB (first 10TB)
- **Total**: ~$1-5/month for low traffic

### EC2 + Nginx
- Uses existing EC2 instance (no extra cost)
- Only domain and SSL certificate costs

### Netlify/Vercel
- Free tier available
- Paid plans start at $19/month

---

## 🆘 Troubleshooting

### Website not loading
- Check DNS propagation: `dig easyBasket.in`
- Verify CloudFront distribution is deployed
- Check S3 bucket permissions

### SSL Certificate issues
- Ensure certificate is in `us-east-1` for CloudFront
- Verify DNS validation records are correct
- Wait for certificate validation (can take up to 30 minutes)
- **GoDaddy users**: Make sure CNAME records are added exactly as shown in AWS (check Name and Value match exactly)
- **GoDaddy users**: If validation fails, verify the CNAME record appears in GoDaddy DNS records list

### 403 Forbidden (S3)
- Check bucket policy allows public read
- Verify "Block public access" is disabled
- Ensure files have public read permissions

### Mixed content warnings
- Ensure all resources use HTTPS
- Check for hardcoded HTTP URLs

### GoDaddy DNS Issues
- **CNAME at root not allowed**: GoDaddy may not allow CNAME records at root domain (@)
  - **Solution**: Use Route 53 for DNS management (transfer nameservers)
  - **Alternative**: Use A record with CloudFront IP (not recommended, IPs can change)
- **DNS not propagating**: 
  - Wait 15-30 minutes after changes
  - Clear DNS cache: `sudo dscacheutil -flushcache` (Mac) or `ipconfig /flushdns` (Windows)
  - Verify records: Use `dig easyBasket.in` or `nslookup easyBasket.in`
- **Can't find DNS settings**: 
  - Go to GoDaddy → My Products → Find your domain → Click "DNS" or "Manage DNS"
  - Look for "Records" section at the bottom
- **API subdomain stopped working**: 
  - Check that `*.easyBasket.in` wildcard record still exists in GoDaddy DNS
  - Verify it wasn't accidentally deleted or modified
  - Test API: `curl https://api.easyBasket.in/health` (or your API endpoint)
  - If wildcard is missing, re-add the wildcard CNAME record `*` pointing to your API server
  - **Note**: Since you're using a wildcard, `api.easyBasket.in` is covered by `*.easyBasket.in`
- **Wildcard DNS behavior**: 
  - Remember: `*.easyBasket.in` covers all subdomains but NOT the root domain
  - Root domain (`easyBasket.in`) always needs its own specific DNS record
  - Specific subdomain records (if any) take precedence over wildcard

---

## 📞 Need Help?

If you encounter issues:
1. Check AWS CloudWatch logs (for CloudFront)
2. Check Nginx error logs: `sudo tail -f /var/log/nginx/error.log`
3. Verify DNS: Use `nslookup easyBasket.in`
4. Test SSL: Use [SSL Labs](https://www.ssllabs.com/ssltest/)

---

**Recommended**: Use **Option 1 (AWS S3 + CloudFront)** for best performance, scalability, and cost-effectiveness.
