# Complete SSL Certificate Validation - Step by Step

## 🔍 Current Status

- ✅ Certificate requested in ACM
- ⚠️ Status: **"Pending validation"**
- ❌ Need to add DNS records in GoDaddy

---

## Step 1: Get DNS Validation Records from ACM

### 1.1 Open Certificate in ACM

**AWS Console:**
1. Go to **Certificate Manager (ACM)**
2. Make sure you're in the **correct region** (same as your ALB)
3. Click on your certificate (status: "Pending validation")
4. Expand the **"Domains"** section

### 1.2 Copy CNAME Records

**You'll see CNAME records like this:**

**For `api.easybasket.in`:**
```
Name:  _abc123def456.api.easybasket.in
Value: _xyz789ghi012.acm-validations.aws.
```

**For `*.easybasket.in` (if you added wildcard):**
```
Name:  _abc123def456.easybasket.in
Value: _xyz789ghi012.acm-validations.aws.
```

**📋 Copy BOTH Name and Value for each domain!**

**Important:**
- **Name:** Copy exactly as shown (e.g., `_abc123def456.api.easybasket.in`)
- **Value:** Copy exactly as shown, including the trailing dot `.` at the end

---

## Step 2: Add CNAME Records in GoDaddy

### 2.1 Login to GoDaddy

1. Go to **https://www.godaddy.com**
2. **Login** to your account
3. Go to **"My Products"** → **"Domains"**
4. Find **"easybasket.in"** → Click **"DNS"** or **"Manage DNS"**

### 2.2 Add First CNAME Record (for api.easybasket.in)

**In GoDaddy DNS Management:**

1. Scroll down to **"Records"** section
2. Find **"CNAME"** records section
3. Click **"Add"** or **"+"** button

**Fill in the form:**

**For `api.easybasket.in` validation:**
- **Type:** CNAME (should be pre-selected)
- **Name:** `_abc123def456.api` 
  - ⚠️ **IMPORTANT:** Remove `.easybasket.in` from the end!
  - AWS shows: `_abc123def456.api.easybasket.in`
  - GoDaddy needs: `_abc123def456.api` (without `.easybasket.in`)
- **Value:** `_xyz789ghi012.acm-validations.aws.`
  - ⚠️ **IMPORTANT:** Include the trailing dot `.` at the end!
  - Copy exactly from AWS
- **TTL:** 600 (or leave default)
- Click **"Save"** or **"Add Record"**

### 2.3 Add Second CNAME Record (for *.easybasket.in, if applicable)

**If you added wildcard domain (`*.easybasket.in`):**

1. Click **"Add"** again for another CNAME record
2. **Fill in:**
   - **Type:** CNAME
   - **Name:** `_abc123def456`
     - ⚠️ **IMPORTANT:** Remove `.easybasket.in` from the end!
     - AWS shows: `_abc123def456.easybasket.in`
     - GoDaddy needs: `_abc123def456` (without `.easybasket.in`)
   - **Value:** `_xyz789ghi012.acm-validations.aws.`
     - ⚠️ **IMPORTANT:** Include the trailing dot `.` at the end!
   - **TTL:** 600
3. Click **"Save"**

---

## Step 3: Verify DNS Records Are Added

### 3.1 Check in GoDaddy

**In GoDaddy DNS Management:**
- You should see your new CNAME records in the list
- Verify:
  - ✅ Name is correct (without `.easybasket.in` at the end)
  - ✅ Value is correct (with trailing dot `.`)

### 3.2 Verify DNS Propagation (Optional)

**Using command line (Mac/Linux):**
```bash
# Check api.easybasket.in validation record
dig _abc123def456.api.easybasket.in CNAME

# Check wildcard validation record (if applicable)
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

## Step 4: Wait for Validation

### 4.1 AWS Automatic Validation

**AWS automatically checks DNS records:**
- Checks every few minutes
- Once validated, status changes to **"Issued"**
- **No manual action needed!**

### 4.2 Check Certificate Status

**AWS Console:**
1. Go back to **Certificate Manager (ACM)**
2. Click on your certificate
3. **Status** will change from:
   - **"Pending validation"** (yellow) → **"Issued"** (green)

**Timeline:**
- **Usually:** 5-10 minutes after adding DNS records
- **Maximum:** Up to 72 hours (rare, usually much faster)

### 4.3 Refresh the Page

**If status doesn't update:**
- Click **"Refresh"** button in ACM
- Or wait a few more minutes
- AWS checks periodically, not instantly

---

## Step 5: Verify Certificate is Issued

### 5.1 Check Status

**In AWS Certificate Manager:**
- ✅ Status: **"Issued"** (green)
- ✅ Expiration date shown (1 year from now)
- ✅ Auto-renewal enabled automatically

**Certificate is ready to use!** 🎉

---

## Troubleshooting

### Issue 1: Status Still "Pending validation" After 30 Minutes

**Possible causes:**
- DNS records not added correctly
- DNS propagation not complete
- Wrong CNAME name or value

**Solution:**
1. **Double-check DNS records in GoDaddy:**
   - Name should NOT include `.easybasket.in` at the end
   - Value should include trailing dot `.` at the end
   - Type should be CNAME (not A or TXT)

2. **Verify DNS propagation:**
   ```bash
   dig _abc123def456.api.easybasket.in CNAME
   ```
   Should return the AWS validation value.

3. **Wait longer:**
   - DNS can take up to 48 hours (usually 5-10 minutes)
   - Check again after 1 hour

4. **Check for typos:**
   - Compare Name and Value exactly with ACM
   - No extra spaces or characters

### Issue 2: "Invalid CNAME Record" Error

**Possible causes:**
- Wrong record type (should be CNAME, not A or TXT)
- Name includes `.easybasket.in` (GoDaddy adds it automatically)
- Value missing trailing dot `.`

**Solution:**
1. **Delete the incorrect record**
2. **Add new CNAME record** with correct format:
   - Name: Without `.easybasket.in` at the end
   - Value: With trailing dot `.` at the end

### Issue 3: DNS Records Not Showing in GoDaddy

**Possible causes:**
- Records not saved properly
- Wrong domain in GoDaddy

**Solution:**
1. **Verify you're editing the correct domain:** `easybasket.in`
2. **Check if records were saved:**
   - Refresh the DNS management page
   - Look for your CNAME records
3. **Try adding again:**
   - Delete if exists
   - Add fresh record

### Issue 4: Certificate Shows "Validation timed out"

**Possible causes:**
- DNS records not added within 72 hours
- DNS records incorrect

**Solution:**
1. **Delete the certificate** (if timed out)
2. **Request new certificate** in ACM
3. **Add DNS records immediately** (within 72 hours)
4. **Follow this guide again**

---

## Quick Checklist

**Before waiting for validation:**

- [ ] CNAME records added in GoDaddy
- [ ] Name field: Without `.easybasket.in` at the end
- [ ] Value field: With trailing dot `.` at the end
- [ ] Record type: CNAME (not A or TXT)
- [ ] Records saved in GoDaddy
- [ ] DNS propagation verified (optional)

**After adding records:**

- [ ] Wait 5-10 minutes
- [ ] Check ACM certificate status
- [ ] Status should be "Issued" (green)
- [ ] Certificate ready to use with ALB

---

## Common Mistakes to Avoid

### ❌ Wrong: Including `.easybasket.in` in Name Field

**GoDaddy automatically adds the domain:**
- ❌ Name: `_abc123def456.api.easybasket.in` (WRONG - GoDaddy adds `.easybasket.in`)
- ✅ Name: `_abc123def456.api` (CORRECT)

### ❌ Wrong: Missing Trailing Dot in Value

**The trailing dot is important:**
- ❌ Value: `_xyz789ghi012.acm-validations.aws` (WRONG - missing dot)
- ✅ Value: `_xyz789ghi012.acm-validations.aws.` (CORRECT - with dot)

### ❌ Wrong: Using Wrong Record Type

**Must be CNAME:**
- ❌ Type: A (WRONG)
- ❌ Type: TXT (WRONG)
- ✅ Type: CNAME (CORRECT)

---

## Step-by-Step Example

**Let's say ACM shows:**

```
Domain: api.easybasket.in
Name:  _a1b2c3d4e5.api.easybasket.in
Value: _x9y8z7w6v5.acm-validations.aws.
```

**In GoDaddy, add CNAME record:**

```
Type:  CNAME
Name:  _a1b2c3d4e5.api          ← Remove .easybasket.in
Value: _x9y8z7w6v5.acm-validations.aws.  ← Keep trailing dot
TTL:   600
```

**Save and wait 5-10 minutes!** ✅

---

## Next Steps After Validation

**Once certificate status is "Issued":**

1. ✅ **Go to ALB setup** (Step 3.2 in `ALB_SETUP_COMPLETE_GUIDE.md`)
2. ✅ **Configure HTTPS listener** with this certificate
3. ✅ **Test HTTPS** endpoint

**Your certificate is ready!** 🎉

---

## Quick Reference

**Time needed:** 10-15 minutes total
- Get DNS records: 2 minutes
- Add in GoDaddy: 3 minutes
- Wait for validation: 5-10 minutes

**If stuck:** Check troubleshooting section above! 🔧

