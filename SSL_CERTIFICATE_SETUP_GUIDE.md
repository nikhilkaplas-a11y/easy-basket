# Complete SSL Certificate Setup Guide for api.easybasket.in

## 📚 What is an SSL Certificate?

An SSL (Secure Sockets Layer) certificate encrypts the connection between your website and users' browsers. It:
- ✅ Makes your site secure (HTTPS instead of HTTP)
- ✅ Shows a padlock icon in browsers
- ✅ Required for modern web apps
- ✅ Improves SEO and user trust

## 🎯 Why Use AWS Certificate Manager (ACM)?

**Benefits:**
- ✅ **100% FREE** (unlimited certificates)
- ✅ **Automatic renewal** (no manual work)
- ✅ **Easy integration** with ALB
- ✅ **Managed by AWS** (no server configuration)
- ✅ **Works with ALB** (just select it in listener)

**Requirements:**
- Domain must be registered (you have `api.easybasket.in`)
- Must validate ownership via DNS

---

## Step 1: Request Certificate in AWS Certificate Manager

### 1.1 Open AWS Certificate Manager

**AWS Console:**
1. Go to **AWS Console** → Search for **"Certificate Manager"** or **"ACM"**
2. Make sure you're in the **correct region** (same as your ALB)
   - Check your ALB region (e.g., `eu-north-1`, `us-east-1`)
   - ACM certificate must be in **same region** as ALB
3. Click **"Request a certificate"**

### 1.2 Request Public Certificate

1. Select **"Request a public certificate"**
2. Click **"Next"**

### 1.3 Enter Domain Name

**Domain names:**
- **Fully qualified domain name (FQDN):** `api.easybasket.in`
- **Optionally add:** `*.easybasket.in` (wildcard for subdomains)
  - This covers `api.easybasket.in`, `www.easybasket.in`, etc.
  - **Recommended:** Add both `api.easybasket.in` AND `*.easybasket.in`

**Example:**
```
Domain name 1: api.easybasket.in
Domain name 2: *.easybasket.in
```

**Click "Next"**

### 1.4 Choose Validation Method

**Select:** **"DNS validation"** (recommended)
- ✅ Faster (5-10 minutes)
- ✅ No email required
- ✅ Works automatically

**Click "Next"**

### 1.5 Add Tags (Optional)

- Skip or add tags if needed
- **Click "Request"**

### 1.6 Certificate Status

**Status:** **"Pending validation"** (yellow)

**You'll see:**
- Certificate ARN (e.g., `arn:aws:acm:eu-north-1:123456789012:certificate/abc-123-def-456`)
- **Domain validation records** (CNAME records to add in GoDaddy)

**⚠️ IMPORTANT:** Don't close this page yet! You need the CNAME records.

---

## Step 2: Add DNS Records in GoDaddy

### 2.1 Get DNS Validation Records

**In AWS Certificate Manager:**
1. Click on your certificate (status: "Pending validation")
2. Expand **"Domains"** section
3. You'll see **CNAME records** for each domain:

**Example:**
```
Domain: api.easybasket.in
Name: _abc123def456.api.easybasket.in
Value: _xyz789ghi012.acm-validations.aws.
```

**For wildcard (*.easybasket.in):**
```
Domain: *.easybasket.in
Name: _abc123def456.easybasket.in
Value: _xyz789ghi012.acm-validations.aws.
```

**📋 Copy both Name and Value for each domain!**

### 2.2 Login to GoDaddy

1. Go to **https://www.godaddy.com**
2. **Login** to your account
3. Go to **"My Products"** → **"Domains"**
4. Find **"easybasket.in"** → Click **"DNS"** or **"Manage DNS"**

### 2.3 Add CNAME Records

**In GoDaddy DNS Management:**

1. **Scroll down** to **"Records"** section
2. Find **"CNAME"** records section
3. **Click "Add"** or **"+"** to add new CNAME record

**For `api.easybasket.in`:**
- **Type:** CNAME
- **Name:** `_abc123def456.api` (copy from AWS, but remove `.easybasket.in` from the end)
  - AWS shows: `_abc123def456.api.easybasket.in`
  - GoDaddy needs: `_abc123def456.api` (without `.easybasket.in`)
- **Value:** `_xyz789ghi012.acm-validations.aws.` (copy exactly from AWS, including the trailing dot)
- **TTL:** 600 (or default)
- **Click "Save"**

**For `*.easybasket.in` (wildcard):**
- **Type:** CNAME
- **Name:** `_abc123def456` (copy from AWS, but remove `.easybasket.in` from the end)
  - AWS shows: `_abc123def456.easybasket.in`
  - GoDaddy needs: `_abc123def456` (without `.easybasket.in`)
- **Value:** `_xyz789ghi012.acm-validations.aws.` (copy exactly from AWS, including the trailing dot)
- **TTL:** 600 (or default)
- **Click "Save"**

**⚠️ Important Notes:**
- **Name field:** Remove `.easybasket.in` from the end (GoDaddy adds it automatically)
- **Value field:** Include the trailing dot (`.`) at the end
- **Wait 5-10 minutes** for DNS propagation

### 2.4 Verify DNS Records

**Check if records are added correctly:**

**Using `dig` command (Mac/Linux):**
```bash
# Check api.easybasket.in validation record
dig _abc123def456.api.easybasket.in CNAME

# Check wildcard validation record
dig _abc123def456.easybasket.in CNAME
```

**Expected output:**
```
_abc123def456.api.easybasket.in. 600 IN CNAME _xyz789ghi012.acm-validations.aws.
```

**Or use online tool:**
- Go to **https://dnschecker.org**
- Enter the CNAME name (e.g., `_abc123def456.api.easybasket.in`)
- Select **CNAME** record type
- Check if it resolves to the AWS validation value

---

## Step 3: Wait for Validation

### 3.1 Check Certificate Status

**AWS Certificate Manager:**
1. Go back to **AWS Certificate Manager**
2. Click on your certificate
3. **Status** will change from:
   - **"Pending validation"** (yellow) → **"Issued"** (green)

**Timeline:**
- **Usually:** 5-10 minutes after adding DNS records
- **Maximum:** Up to 72 hours (rare)

### 3.2 Automatic Validation

**AWS automatically checks DNS records:**
- Checks every few minutes
- Once validated, status changes to **"Issued"**
- **No manual action needed!**

### 3.3 Verify Certificate is Issued

**In AWS Certificate Manager:**
- ✅ Status: **"Issued"** (green)
- ✅ Expiration date shown (1 year from now)
- ✅ Auto-renewal enabled automatically

**Certificate is ready to use!** 🎉

---

## Step 4: Use Certificate with ALB

### 4.1 Configure HTTPS Listener

**AWS Console:**
1. **EC2** → **Load Balancers** → Select your ALB
2. **Listeners** tab → **Add listener** (or edit existing)
3. **Configure:**
   - **Protocol:** HTTPS
   - **Port:** 443
   - **Default SSL certificate:**
     - Select **"From ACM"**
     - **Certificate:** Select `api.easybasket.in` (your certificate)
   - **Default action:** Forward to
   - **Target group:** Select `easy-basket-backend`
4. **Click "Save"**

### 4.2 Verify Certificate is Attached

**Check Listeners tab:**
- ✅ HTTPS (Port 443) listener exists
- ✅ Certificate shows: `api.easybasket.in`
- ✅ Status: Active

**Your ALB is now using SSL!** 🔒

---

## Step 5: Test HTTPS

### 5.1 Test via Browser

**Open browser:**
```
https://api.easybasket.in/api/health
```

**Expected:**
- ✅ Padlock icon in address bar
- ✅ URL shows `https://` (not `http://`)
- ✅ No security warnings
- ✅ API responds correctly

### 5.2 Test via Command Line

```bash
# Test HTTPS endpoint
curl https://api.easybasket.in/api/health

# Check SSL certificate details
curl -v https://api.easybasket.in/api/health 2>&1 | grep -i "SSL\|certificate"

# Test with SSL verification
curl -vI https://api.easybasket.in/api/health
```

**Expected output:**
```
* SSL connection using TLSv1.2
* Server certificate: api.easybasket.in
* SSL certificate verify ok
```

---

## Troubleshooting

### Issue 1: Certificate Status Stuck on "Pending validation"

**Possible causes:**
- DNS records not added correctly
- DNS propagation not complete (wait longer)
- Wrong CNAME name or value

**Solution:**
1. **Verify DNS records in GoDaddy:**
   - Check Name field (should NOT include `.easybasket.in` at the end)
   - Check Value field (should include trailing dot `.`)
   - Check TTL (should be 600 or lower)

2. **Verify DNS propagation:**
   ```bash
   dig _abc123def456.api.easybasket.in CNAME
   ```
   Should return the AWS validation value.

3. **Wait longer:**
   - DNS can take up to 48 hours (usually 5-10 minutes)
   - Check again after 30 minutes

4. **Re-request certificate:**
   - Delete current certificate
   - Request new one
   - Add DNS records again

### Issue 2: "Certificate not found" in ALB Listener

**Possible causes:**
- Certificate in wrong region
- Certificate not issued yet

**Solution:**
1. **Check certificate region:**
   - Certificate must be in **same region** as ALB
   - Check ALB region: `eu-north-1`, `us-east-1`, etc.
   - Check certificate region in ACM

2. **Request certificate in correct region:**
   - Go to correct region in AWS Console
   - Request certificate there
   - Use that certificate in ALB

### Issue 3: "Invalid certificate" or Browser Warning

**Possible causes:**
- Certificate not attached to listener
- Wrong domain in certificate
- Certificate expired (unlikely, auto-renewal)

**Solution:**
1. **Check ALB listener:**
   - Verify HTTPS listener exists
   - Verify certificate is selected
   - Verify certificate status is "Issued"

2. **Check certificate domain:**
   - Certificate must match domain exactly
   - `api.easybasket.in` certificate won't work for `www.easybasket.in`
   - Use wildcard `*.easybasket.in` to cover all subdomains

### Issue 4: DNS Records Not Working

**Check:**
```bash
# Check if CNAME record exists
dig _abc123def456.api.easybasket.in CNAME

# Check DNS propagation globally
# Use: https://dnschecker.org
```

**Common mistakes:**
- ❌ Including `.easybasket.in` in Name field (GoDaddy adds it automatically)
- ❌ Missing trailing dot `.` in Value field
- ❌ Wrong record type (should be CNAME, not A or TXT)

---

## Quick Reference: Complete Steps Summary

### 1. Request Certificate (5 minutes)
```
AWS Console → Certificate Manager → Request certificate
→ Enter: api.easybasket.in
→ Choose: DNS validation
→ Request
```

### 2. Add DNS Records (5 minutes)
```
GoDaddy → DNS Management → Add CNAME records
→ Copy Name and Value from AWS
→ Save
```

### 3. Wait for Validation (5-10 minutes)
```
AWS Certificate Manager → Check status
→ Status: Pending validation → Issued
```

### 4. Use with ALB (2 minutes)
```
EC2 → Load Balancers → ALB → Listeners
→ Add HTTPS listener (Port 443)
→ Select certificate from ACM
→ Save
```

### 5. Test (1 minute)
```
Browser: https://api.easybasket.in/api/health
→ Should show padlock ✅
```

**Total time: ~20-30 minutes** ⏱️

---

## AWS CLI Commands (Optional)

### Request Certificate via CLI

```bash
# Request certificate
aws acm request-certificate \
  --domain-name api.easybasket.in \
  --subject-alternative-names *.easybasket.in \
  --validation-method DNS \
  --region eu-north-1  # Use your ALB region

# Get certificate ARN
CERT_ARN=$(aws acm list-certificates \
  --region eu-north-1 \
  --query "CertificateSummaryList[?DomainName=='api.easybasket.in'].CertificateArn" \
  --output text)

echo "Certificate ARN: $CERT_ARN"

# Get DNS validation records
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region eu-north-1 \
  --query 'Certificate.DomainValidationOptions[*].[DomainName,ResourceRecord.Name,ResourceRecord.Value]' \
  --output table
```

### Check Certificate Status

```bash
# List all certificates
aws acm list-certificates \
  --region eu-north-1 \
  --output table

# Describe certificate
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region eu-north-1 \
  --query 'Certificate.[Status,DomainName,IssuedAt,NotAfter]' \
  --output table
```

---

## Important Notes

### ✅ Best Practices

1. **Use wildcard certificate** (`*.easybasket.in`) to cover all subdomains
2. **Request in correct region** (same as ALB)
3. **Keep DNS records** (needed for auto-renewal)
4. **Monitor expiration** (auto-renewal handles it, but good to know)

### ⚠️ Common Mistakes

1. ❌ Requesting certificate in wrong region
2. ❌ Including `.easybasket.in` in GoDaddy Name field
3. ❌ Missing trailing dot in Value field
4. ❌ Using wrong record type (should be CNAME)
5. ❌ Deleting DNS records after validation (needed for renewal)

### 🔄 Auto-Renewal

**AWS automatically renews certificates:**
- ✅ No action needed
- ✅ Renews 60 days before expiration
- ✅ DNS records must still exist for renewal validation
- ✅ **Don't delete DNS validation records!**

---

## Next Steps

After SSL certificate is set up:

1. ✅ **Configure ALB HTTPS listener** (Step 4 above)
2. ✅ **Configure HTTP to HTTPS redirect** (in ALB listener)
3. ✅ **Update app to use HTTPS** (if hardcoded URLs)
4. ✅ **Test all endpoints** with HTTPS

**Your API is now secure!** 🔒✨

