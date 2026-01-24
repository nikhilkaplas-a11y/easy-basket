# Quick HTTPS Setup for Easy Basket Website

You've already created the S3 bucket and have the HTTP URL. Now let's add HTTPS using CloudFront.

## Current Status
- ✅ S3 bucket created: `easybasket-website`
- ✅ Static website hosting enabled
- ✅ HTTP URL working: `http://easybasket-website.s3-website.ap-south-1.amazonaws.com`
- ❌ Need HTTPS for production

## Solution: Add CloudFront Distribution

CloudFront will:
- ✅ Provide HTTPS/SSL
- ✅ Improve performance (CDN)
- ✅ Allow custom domain with SSL certificate

---

## Step 1: Request SSL Certificate (5-10 minutes)

1. **Go to AWS Certificate Manager (ACM)**
   - AWS Console → Search "Certificate Manager"
   - **IMPORTANT**: Make sure you're in **`us-east-1`** region (N. Virginia)
     - CloudFront only accepts certificates from us-east-1
   - Click "Request certificate"

2. **Certificate Details**
   - Choose "Request a public certificate"
   - **Domain name**: `easyBasket.in`
   - **Additional names**: 
     - `*.easyBasket.in` (wildcard for all subdomains)
     - `www.easyBasket.in` (optional)
   - **Validation method**: DNS validation
   - Click "Request"

3. **Validate Certificate in GoDaddy**
   - Click on your certificate in ACM
   - Go to "Domains" tab
   - You'll see CNAME records to add
   - **For each domain** (root, wildcard, www):
     1. Log in to GoDaddy
     2. Go to "My Products" → DNS for `easyBasket.in`
     3. Click "Add" record
     4. **Type**: CNAME
     5. **Name**: Copy from AWS (e.g., `_abc123def456`)
     6. **Value**: Copy from AWS (e.g., `_xyz789.acm-validations.aws.`)
     7. **TTL**: 600
     8. Click "Save"
   - Wait 5-30 minutes for validation
   - Certificate status will change to "Issued"

---

## Step 2: Create CloudFront Distribution (10-15 minutes)

1. **Go to CloudFront Console**
   - AWS Console → Search "CloudFront"
   - Click "Create distribution"

2. **Origin Settings**
   - **Origin domain**: 
     - **IMPORTANT**: Select the **S3 website endpoint**, NOT the regular bucket
     - It should be: `easybasket-website.s3-website.ap-south-1.amazonaws.com`
     - (NOT `easybasket-website.s3.amazonaws.com`)
   - **Origin path**: Leave empty
   - **Name**: Auto-filled

3. **Default Cache Behavior**
   - **Viewer protocol policy**: **Redirect HTTP to HTTPS** ⚠️ (Important!)
   - **Allowed HTTP methods**: GET, HEAD
   - **Cache policy**: CachingOptimized

4. **Distribution Settings**
   - **Price class**: Use all edge locations (or choose based on your audience)
   - **Alternate domain names (CNAMEs)**: 
     - `easyBasket.in`
     - `www.easyBasket.in` (optional)
   - **Custom SSL certificate**: Select the certificate you created in Step 1
   - **Default root object**: `index.html`
   - **Comment**: "Easy Basket Website" (optional)
   - Click "Create distribution"

5. **Wait for Deployment**
   - Status will be "In Progress" for 10-15 minutes
   - Wait until status changes to "Deployed"
   - Copy the **Distribution domain name** (e.g., `d1234567890.cloudfront.net`)

---

## Step 3: Point Domain to CloudFront (GoDaddy)

1. **Log in to GoDaddy**
   - Go to "My Products" → DNS for `easyBasket.in`

2. **Add Root Domain Record**
   - Click "Add" record
   - **Type**: CNAME (or A if CNAME not allowed at root)
   - **Name**: `@` (or leave blank for root domain)
   - **Value**: Your CloudFront distribution domain (e.g., `d1234567890.cloudfront.net`)
   - **TTL**: 600
   - Click "Save"

3. **Optional: Add www Record**
   - Click "Add" record
   - **Type**: CNAME
   - **Name**: `www`
   - **Value**: Same CloudFront distribution domain
   - **TTL**: 600
   - Click "Save"

4. **Note**: Your wildcard `*.easyBasket.in` will continue to work for other subdomains

---

## Step 4: Test HTTPS

1. **Wait for DNS propagation** (15-30 minutes usually)
2. **Test CloudFront directly**:
   - Visit: `https://d1234567890.cloudfront.net` (your distribution domain)
   - Should show HTTPS with SSL
3. **Test custom domain**:
   - Visit: `https://easyBasket.in`
   - Should redirect HTTP to HTTPS automatically

---

## Troubleshooting

### Certificate not showing in CloudFront
- **Problem**: Certificate doesn't appear in dropdown
- **Solution**: Make sure certificate is in `us-east-1` region, not `ap-south-1`

### CloudFront shows "Distribution not ready"
- **Problem**: Distribution still deploying
- **Solution**: Wait 10-15 minutes, refresh the page

### HTTPS not working
- **Problem**: Site loads but shows "Not Secure"
- **Solution**: 
  - Check certificate is "Issued" in ACM
  - Verify certificate is attached to CloudFront distribution
  - Check "Viewer protocol policy" is set to "Redirect HTTP to HTTPS"

### DNS not resolving
- **Problem**: Domain doesn't load
- **Solution**:
  - Wait 15-30 minutes for DNS propagation
  - Verify DNS records in GoDaddy
  - Test with: `nslookup easyBasket.in` or `dig easyBasket.in`

---

## Cost Estimate

- **CloudFront**: ~$0.085 per GB (first 10TB free tier: 1TB/month)
- **S3**: Already set up (minimal cost)
- **ACM Certificate**: Free
- **Total**: ~$1-5/month for low-medium traffic

---

## Summary

After completing these steps:
- ✅ HTTPS enabled via CloudFront
- ✅ Custom domain `easyBasket.in` with SSL
- ✅ Automatic HTTP to HTTPS redirect
- ✅ Fast CDN delivery worldwide
- ✅ Your S3 bucket remains the source

Your website will be accessible at:
- `https://easyBasket.in` ✅
- `https://www.easyBasket.in` ✅ (if configured)

The HTTP S3 URL will still work, but CloudFront HTTPS URL is what you'll use for production.
