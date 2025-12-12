# 🔧 Fix: Pinpoint Subscription Error

The error indicates AWS PinpointSmsVoiceV2 service needs to be subscribed/enabled.

---

## 🔍 The Issue

**Error:** "The AWS Access Key Id needs a subscription for the service (Service: PinpointSmsVoiceV2)"

**This means:** Your AWS account needs to enable/subscribe to Pinpoint SMS service.

---

## 🔧 Fix 1: Enable Pinpoint SMS Service

### In AWS Console:

1. **Pinpoint** → **SMS and voice** (or go to https://console.aws.amazon.com/pinpoint/)
2. **If Pinpoint is not set up:**
   - Click **Get started** or **Create a project**
   - Create a project (e.g., "Easy Basket SMS")
   - **Enable SMS** for the project

### Alternative: Use SNS Directly (Without Pinpoint)

AWS SNS can send SMS directly without Pinpoint. The error might be because the console is trying to use Pinpoint features.

---

## 🔧 Fix 2: Use SNS Directly (Recommended)

### Your code is already using SNS directly, which is correct!

**The error is from AWS Console UI, not your code.**

**Your backend code uses:**
- `@aws-sdk/client-sns` ✅ (Direct SNS, not Pinpoint)

**The console error is just a UI issue - your code should still work.**

---

## 🔧 Fix 3: Check SNS Account Status

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Try to view account preferences**
3. **If error persists, try:**
   - **CloudWatch** → **Metrics** → **SNS**
   - Check if SMS metrics are available

---

## 🔧 Fix 4: Verify SMS is Working Despite Error

### Test if SMS Actually Works:

**On EC2:**

```bash
# Test sending OTP
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "YOUR_PHONE_NUMBER"}'

# Check logs
pm2 logs easy-basket-api --lines 20 | grep -i "sns\|otp"
```

**If logs show "OTP SMS sent successfully", it's working despite the console error!**

---

## 🔧 Fix 5: Enable Pinpoint (If Needed)

### If You Want to Use Pinpoint Features:

1. **Pinpoint** → **Get started**
2. **Create project:**
   - Project name: "Easy Basket"
   - Region: eu-north-1
3. **Enable SMS:**
   - Go to **SMS and voice**
   - **Request phone number** or **Enable SMS**
4. **Configure:**
   - Set up sender ID (optional)
   - Configure delivery settings

**Note:** For simple OTP sending, SNS direct is sufficient. Pinpoint is for more advanced features.

---

## 🔍 Step 6: Check if SMS Actually Works

### Despite the Console Error:

**The console error might be a UI issue. Your code might still work!**

### Test:

```bash
# From your Mac
curl -X POST http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "YOUR_PHONE_NUMBER"}'

# Wait 2-5 minutes
# Check your phone for SMS
```

**If SMS arrives, the console error is just a UI issue and can be ignored.**

---

## 🔧 Fix 7: Use Different AWS Region

### If Pinpoint Issues Persist:

**Your code uses `eu-north-1`. Try a different region:**

**File:** `backend/.env`

```env
AWS_REGION=ap-south-1  # Mumbai (closer to India, better for SMS)
```

**Then rebuild and restart:**

```bash
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
```

**ap-south-1 (Mumbai) is often better for Indian SMS.**

---

## 📋 Quick Decision Tree

1. **Test if SMS actually works** (despite console error)
   - If works → Console error is just UI, ignore it ✅
   - If doesn't work → Continue below

2. **Check delivery status in CloudWatch**
   - CloudWatch → Metrics → SNS → Check delivery metrics

3. **Try different region**
   - Change to `ap-south-1` (Mumbai)

4. **Enable Pinpoint** (if needed for advanced features)

---

## 🎯 Most Likely Solution

**The console error is a UI issue. Your code uses SNS directly and should work.**

**Test if SMS actually arrives:**
1. Send OTP via API
2. Wait 2-5 minutes
3. Check phone (including spam)

**If SMS arrives, ignore the console error!**

---

## ✅ Verification

**Test SMS delivery:**

```bash
# Send OTP
curl -X POST http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "YOUR_PHONE"}'

# Check logs
pm2 logs easy-basket-api --lines 10 | grep -i "sns\|otp"
```

**If logs show "OTP SMS sent successfully" and you receive SMS, it's working!**

---

**Test if SMS actually works first - the console error might just be a UI issue! 🔍**

