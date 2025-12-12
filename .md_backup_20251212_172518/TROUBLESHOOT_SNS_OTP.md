# 🔧 Troubleshoot: OTP Not Received

Step-by-step guide to fix OTP not being sent via AWS SNS.

---

## 🔍 Step 1: Check Backend Logs

### On EC2:

```bash
# Check recent logs
pm2 logs easy-basket-api --lines 50

# Look for:
# - "AWS SNS initialized successfully" ✅
# - "OTP SMS sent successfully" ✅
# - "Error sending OTP via AWS SNS" ❌
# - "AWS SNS not initialized" ❌
```

**Share the log output, especially around OTP sending.**

---

## 🔍 Step 2: Verify AWS Credentials

### On EC2:

```bash
# Check .env file has AWS credentials
cat ~/easy-basket/backend/.env | grep AWS

# Should show:
# AWS_REGION=eu-north-1
# AWS_ACCESS_KEY_ID=AKIA...
# AWS_SECRET_ACCESS_KEY=...
```

**If missing or incorrect, add/update them.**

---

## 🔍 Step 3: Test SNS Directly

### On EC2:

```bash
# Test if AWS CLI can access SNS (if AWS CLI installed)
aws sns list-topics --region eu-north-1

# Or test with Node.js script
cd ~/easy-basket/backend
node -e "
const { SNSClient } = require('@aws-sdk/client-sns');
require('dotenv').config();
const client = new SNSClient({
  region: process.env.AWS_REGION || 'eu-north-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});
console.log('SNS Client created:', client ? 'Success' : 'Failed');
"
```

---

## 🔍 Step 4: Check IAM Permissions

### In AWS Console:

1. **IAM** → **Users** → Your SNS user
2. **Permissions** tab
3. **Check if `AmazonSNSFullAccess` is attached**

**If missing, add it:**
1. **Add permissions** → **Attach policies directly**
2. **Search:** `AmazonSNSFullAccess`
3. **Select** → **Add permissions**

---

## 🔍 Step 5: Check Phone Number Format

### Verify in Logs:

```bash
# Check what phone number is being sent
pm2 logs easy-basket-api | grep -i "phone\|otp\|sns" | tail -20
```

**Phone number should be:**
- ✅ `+919876543210` (E.164 format)
- ✅ `9876543210` (will be auto-formatted to +91)

---

## 🔍 Step 6: Test API Endpoint Directly

### From Your Mac:

```bash
# Test login endpoint
curl -X POST http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}' -v

# Check response and any errors
```

---

## 🔍 Step 7: Check SNS Service Initialization

### On EC2:

```bash
# Check if SNS service is loading
pm2 logs easy-basket-api | grep -i "sns\|aws" | tail -20
```

**Should see:** `AWS SNS initialized successfully`

**If not, check:**
- AWS credentials in `.env`
- Credentials are correct
- No typos in environment variable names

---

## 🔧 Fix 1: Verify Environment Variables

### On EC2:

```bash
cd ~/easy-basket/backend

# Check .env file
cat .env | grep AWS

# If missing, add them:
echo "" >> .env
echo "# AWS SNS Configuration" >> .env
echo "AWS_REGION=eu-north-1" >> .env
echo "AWS_ACCESS_KEY_ID=your-key-here" >> .env
echo "AWS_SECRET_ACCESS_KEY=your-secret-here" >> .env

# Rebuild and restart
npm run build
pm2 restart easy-basket-api
```

---

## 🔧 Fix 2: Test SNS with AWS CLI

### On EC2 (if AWS CLI installed):

```bash
# Configure AWS CLI
aws configure

# Enter:
# AWS Access Key ID: your-key
# AWS Secret Access Key: your-secret
# Default region: eu-north-1
# Default output format: json

# Test SNS
aws sns publish \
  --phone-number "+919876543210" \
  --message "Test OTP: 123456" \
  --region eu-north-1
```

**If this works, SNS is configured correctly. If not, check IAM permissions.**

---

## 🔧 Fix 3: Check SNS Service Code

### Verify SNS Service is Being Called:

**File:** `backend/src/services/sns.service.ts`

**Check:**
- Service initializes on module load
- `sendOTP` method is async
- Error handling is in place

---

## 🔍 Step 8: Enable Detailed Logging

### Update SNS Service (Temporary):

**File:** `backend/src/services/sns.service.ts`

**Add more logging:**

```typescript
static async sendOTP(phoneNumber: string, otp: string): Promise<boolean> {
  console.log(`[SNS] Attempting to send OTP to: ${phoneNumber}, OTP: ${otp}`);
  
  if (!this.snsClient) {
    console.error('[SNS] SNS client not initialized');
    return false;
  }

  // ... rest of code with more console.log statements
}
```

**Then rebuild and test:**

```bash
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
```

---

## 🔍 Step 9: Check AWS SNS Console

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Delivery status** → Check recent messages
3. **Look for:**
   - Failed deliveries
   - Error messages
   - Delivery attempts

**This shows if SNS is receiving requests but failing to deliver.**

---

## 🔍 Step 10: Check Phone Number Restrictions

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Account preferences**
3. **Check:**
   - **Default message type:** Should be "Transactional" or "Promotional"
   - **Spending limit:** Should not be $0
   - **Delivery status logging:** Should be enabled

---

## 📋 Complete Diagnostic Script

**Run this on EC2:**

```bash
echo "=== 1. AWS Credentials in .env ==="
cd ~/easy-basket/backend
cat .env | grep AWS || echo "❌ AWS credentials not found"

echo ""
echo "=== 2. PM2 Logs (SNS related) ==="
pm2 logs easy-basket-api --lines 30 --nostream | grep -i "sns\|aws\|otp" || echo "No SNS logs found"

echo ""
echo "=== 3. Test API Endpoint ==="
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}' 2>&1 | head -5

echo ""
echo "=== 4. Check Recent Logs After Test ==="
sleep 2
pm2 logs easy-basket-api --lines 10 --nostream | tail -10
```

**Share the complete output.**

---

## 🎯 Most Likely Issues

1. **AWS credentials missing/incorrect** → Check `.env` file
2. **IAM permissions missing** → Add `AmazonSNSFullAccess`
3. **SNS not initialized** → Check logs for initialization message
4. **Phone number format** → Should be +91XXXXXXXXXX
5. **Spending limit reached** → Check AWS SNS console

---

## 🔧 Quick Fix Sequence

```bash
# 1. Verify credentials
cat ~/easy-basket/backend/.env | grep AWS

# 2. Rebuild
cd ~/easy-basket/backend
npm install @aws-sdk/client-sns
npm run build

# 3. Restart
pm2 restart easy-basket-api

# 4. Check logs
pm2 logs easy-basket-api --lines 30

# 5. Test
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'
```

---

**Run the diagnostic script and share the output - that will tell us exactly what's wrong! 🔍**

