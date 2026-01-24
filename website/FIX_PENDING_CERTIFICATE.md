# Fix Pending Certificate Validation

Your CNAME record is already in GoDaddy, but AWS still shows "Pending validation". Here's how to fix it:

## ✅ What You've Done
- CNAME record added in GoDaddy for `www.easyBasket.in`
- Record: `_742b4b00aefc8825b78c19ec7d343595.www.easybasket.in` → `_6dfef700b9ad2227d2d23fd783ad70ee.jkddzztszm.acm-validations.aws.`

## 🔍 Troubleshooting Steps

### Step 1: Verify DNS Record Format

In GoDaddy, the record should be:
- **Type**: CNAME
- **Name**: `_742b4b00aefc8825b78c19ec7d343595.www` (without `.easybasket.in` at the end)
  - GoDaddy automatically appends the domain
  - If you entered the full name including `.easybasket.in`, it might be wrong
- **Value**: `_6dfef700b9ad2227d2d23fd783ad70ee.jkddzztszm.acm-validations.aws.` (with trailing dot)
- **TTL**: 1 Hour (or 600 seconds)

### Step 2: Check DNS Propagation

1. **Wait 5-15 minutes** after adding the record
2. **Verify the record exists** using command line:
   ```bash
   # Check if CNAME record is visible
   dig _742b4b00aefc8825b78c19ec7d343595.www.easybasket.in CNAME
   
   # Or use nslookup
   nslookup -type=CNAME _742b4b00aefc8825b78c19ec7d343595.www.easybasket.in
   ```

3. **Expected output** should show:
   ```
   _742b4b00aefc8825b78c19ec7d343595.www.easybasket.in. CNAME _6dfef700b9ad2227d2d23fd783ad70ee.jkddzztszm.acm-validations.aws.
   ```

### Step 3: Common Issues & Fixes

#### Issue 1: Record Name Format
**Problem**: GoDaddy might have added `.easybasket.in` twice
- **Check**: In GoDaddy DNS, the Name field should be just: `_742b4b00aefc8825b78c19ec7d343595.www`
- **Not**: `_742b4b00aefc8825b78c19ec7d343595.www.easybasket.in` (GoDaddy adds domain automatically)

**Fix**:
1. Edit the record in GoDaddy
2. Make sure Name is: `_742b4b00aefc8825b78c19ec7d343595.www` (without `.easybasket.in`)
3. Save and wait 5-10 minutes

#### Issue 2: Missing Trailing Dot
**Problem**: Value might be missing trailing dot
- **Check**: Value should end with `.` (dot)
- **Should be**: `_6dfef700b9ad2227d2d23fd783ad70ee.jkddzztszm.acm-validations.aws.`
- **Not**: `_6dfef700b9ad2227d2d23fd783ad70ee.jkddzztszm.acm-validations.aws` (no trailing dot)

**Fix**: Edit the record and add trailing dot if missing

#### Issue 3: AWS Not Checking Yet
**Problem**: AWS checks validation periodically (every 5-30 minutes)

**Fix**:
1. In AWS Certificate Manager, click on your certificate
2. Go to "Domains" tab
3. Click the **refresh icon** or wait a few more minutes
4. AWS will automatically re-check the DNS records

#### Issue 4: DNS Propagation Delay
**Problem**: DNS changes can take time to propagate globally

**Fix**:
- Wait 15-30 minutes after adding the record
- Use different DNS servers to check:
  ```bash
  # Google DNS
  dig @8.8.8.8 _742b4b00aefc8825b78c19ec7d343595.www.easybasket.in CNAME
  
  # Cloudflare DNS
  dig @1.1.1.1 _742b4b00aefc8825b78c19ec7d343595.www.easybasket.in CNAME
  ```

### Step 4: Manual Re-validation (If Still Pending)

If it's been more than 30 minutes and still pending:

1. **Delete and Re-add the Record**:
   - In GoDaddy, delete the existing CNAME record
   - Wait 2-3 minutes
   - Add it again with exact values from AWS
   - Make sure format is correct (see Step 1)

2. **Request Re-validation in AWS**:
   - In AWS Certificate Manager
   - Click on your certificate
   - Go to "Domains" tab
   - Click on the pending domain
   - Click "Create records in Route 53" (even if using GoDaddy, this might trigger a re-check)
   - Or wait - AWS checks automatically every few minutes

### Step 5: Verify Record in GoDaddy

Double-check in GoDaddy DNS settings:

1. Go to "My Products" → DNS for `easyBasket.in`
2. Look for a CNAME record with:
   - **Name**: `_742b4b00aefc8825b78c19ec7d343595.www`
   - **Value**: `_6dfef700b9ad2227d2d23fd783ad70ee.jkddzztszm.acm-validations.aws.`
3. If it looks different, edit it to match exactly

## ⏱️ Expected Timeline

- **Immediate**: Record added to GoDaddy
- **5-15 minutes**: DNS propagation
- **5-30 minutes**: AWS detects and validates
- **Total**: Usually 15-30 minutes, can take up to 48 hours in rare cases

## ✅ Success Indicators

When validation succeeds:
- Status changes from "Pending validation" to "Success" ✅
- Green checkmark appears
- Certificate status becomes "Issued"
- You can now use it in CloudFront

## 🆘 Still Not Working?

If it's been more than 1 hour and still pending:

1. **Verify the exact CNAME values** match AWS exactly
2. **Check for typos** in the record
3. **Try deleting and re-adding** the record
4. **Contact AWS Support** if it's been 24+ hours

## 💡 Pro Tip

Since you have a wildcard `*.easyBasket.in` DNS record, you might not actually need the `www.easyBasket.in` certificate. However, it's good to have it for explicit www support.

If you want to skip www validation:
- You can remove `www.easyBasket.in` from the certificate
- Request a new certificate with only `easyBasket.in` and `*.easyBasket.in`
- This will validate faster since you already have the root domain validated
