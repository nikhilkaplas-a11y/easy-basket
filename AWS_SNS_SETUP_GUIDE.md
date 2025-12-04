# 📱 AWS SNS Setup for OTP Delivery

Complete guide to set up AWS SNS for sending OTP via SMS.

---

## 📋 Step 1: Install AWS SDK

### On EC2 (or locally):

```bash
cd ~/easy-basket/backend
npm install @aws-sdk/client-sns
```

---

## 🔑 Step 2: Create IAM User for SNS

### In AWS Console:

1. **IAM** → **Users** → **Create user**
2. **User name:** `easy-basket-sns-user` (or your choice)
3. **Access type:** Programmatic access
4. **Next**

### Attach Policy:

1. **Attach policies directly**
2. **Search:** `AmazonSNSFullAccess`
3. **Select** → **Next**
4. **Create user**

### Save Credentials:

1. **Access key ID:** Copy this
2. **Secret access key:** Copy this (shown only once!)

**Save these securely - you'll need them for `.env`**

---

## 🔧 Step 3: Update Environment Variables

### On EC2:

```bash
cd ~/easy-basket/backend
nano .env
```

### Add These Lines:

```env
# AWS SNS Configuration
AWS_REGION=eu-north-1
AWS_ACCESS_KEY_ID=your-access-key-id-here
AWS_SECRET_ACCESS_KEY=your-secret-access-key-here
```

**Replace with your actual credentials from Step 2.**

### Save and Exit:

`Ctrl+X`, `Y`, `Enter`

---

## 🧪 Step 4: Test SNS Setup

### On EC2:

```bash
# Rebuild backend
cd ~/easy-basket/backend
npm install
npm run build

# Restart PM2
pm2 restart easy-basket-api

# Check logs
pm2 logs easy-basket-api --lines 20
```

**Should see:** `AWS SNS initialized successfully`

---

## 📱 Step 5: Test OTP Sending

### From Your Mac:

```bash
# Send OTP (replace with your phone number)
curl -X POST http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'
```

**Check your phone for SMS with OTP!**

---

## 🔍 Step 6: Verify SNS is Working

### Check Backend Logs:

```bash
pm2 logs easy-basket-api --lines 50
```

**Look for:**
- `AWS SNS initialized successfully`
- `OTP SMS sent successfully to +91...`

**If you see errors:**
- Check AWS credentials in `.env`
- Verify IAM user has SNS permissions
- Check phone number format

---

## 📋 Phone Number Format

### Important:

AWS SNS requires phone numbers in **E.164 format**:
- ✅ `+919876543210` (with country code)
- ✅ `+91 9876543210` (with space - will be formatted)
- ❌ `9876543210` (without country code - will be auto-formatted to +91)

**The service automatically adds `+91` if missing for 10-digit Indian numbers.**

---

## 💰 AWS SNS Pricing

### SMS Pricing (India):

- **Transactional SMS:** ~₹0.20-0.50 per SMS
- **Promotional SMS:** ~₹0.10-0.30 per SMS
- **Free Tier:** First 100 SMS/month free (for new accounts)

**Check:** https://aws.amazon.com/sns/pricing/

---

## 🔧 Step 7: Configure SMS Spending Limit (Recommended)

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Account preferences**
3. **Set spending limit:** Set a monthly limit (e.g., ₹1000)
4. **Save**

**This prevents unexpected charges.**

---

## 🔍 Step 8: Test Different Scenarios

### Test 1: Valid Phone Number

```bash
curl -X POST http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'
```

**Should receive SMS.**

### Test 2: Invalid Phone Number

```bash
curl -X POST http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "123"}'
```

**Should fail gracefully.**

---

## 🐛 Troubleshooting

### Issue 1: "AWS SNS not initialized"

**Check:**
- AWS credentials in `.env`
- Credentials are correct
- IAM user has SNS permissions

**Fix:**
```bash
# Verify .env has credentials
cat ~/easy-basket/backend/.env | grep AWS

# Should show:
# AWS_REGION=eu-north-1
# AWS_ACCESS_KEY_ID=...
# AWS_SECRET_ACCESS_KEY=...
```

### Issue 2: "InvalidParameter" Error

**Cause:** Phone number format incorrect

**Fix:**
- Ensure phone number is in E.164 format
- Service auto-formats 10-digit Indian numbers to +91

### Issue 3: "AccessDenied" Error

**Cause:** IAM user doesn't have SNS permissions

**Fix:**
1. **IAM** → **Users** → Your user
2. **Add permissions** → **Attach policies**
3. **Add:** `AmazonSNSFullAccess`
4. **Save**

### Issue 4: SMS Not Received

**Check:**
- Phone number is correct
- Phone can receive SMS
- Check AWS SNS logs in CloudWatch
- Verify spending limit not exceeded

---

## 📊 Monitor SNS Usage

### In AWS Console:

1. **CloudWatch** → **Metrics** → **SNS**
2. **View:** NumberOfMessagesPublished
3. **Set up alarms** for high usage

---

## 🔐 Security Best Practices

1. **Use IAM roles** (if on EC2) instead of access keys
2. **Rotate access keys** regularly
3. **Set spending limits** to prevent abuse
4. **Monitor usage** in CloudWatch
5. **Store credentials** securely in `.env` (never commit to Git)

---

## ✅ Verification Checklist

- [ ] AWS SDK installed: `npm install @aws-sdk/client-sns`
- [ ] IAM user created with SNS permissions
- [ ] AWS credentials added to `.env`
- [ ] Backend rebuilt: `npm run build`
- [ ] PM2 restarted: `pm2 restart easy-basket-api`
- [ ] Logs show: "AWS SNS initialized successfully"
- [ ] Test OTP sent and received SMS
- [ ] Spending limit configured

---

## 🎯 Quick Setup Summary

1. **Create IAM user** with `AmazonSNSFullAccess`
2. **Get access keys** (Access Key ID + Secret)
3. **Add to `.env`:**
   ```env
   AWS_REGION=eu-north-1
   AWS_ACCESS_KEY_ID=your-key
   AWS_SECRET_ACCESS_KEY=your-secret
   ```
4. **Install SDK:** `npm install @aws-sdk/client-sns`
5. **Rebuild & restart:** `npm run build && pm2 restart easy-basket-api`
6. **Test:** Send OTP and check phone

---

## 📝 Environment Variables

Add these to your `.env` file:

```env
# AWS SNS Configuration
AWS_REGION=eu-north-1
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

**Region should match your EC2 region (eu-north-1 for your setup).**

---

**Your OTP will now be sent via AWS SNS! 📱**

