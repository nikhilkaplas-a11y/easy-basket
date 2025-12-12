# ✅ Check SMS Delivery Status

Your AWS SNS is working! Logs show OTPs are being sent. Let's check delivery status.

---

## ✅ What's Working

From your logs:
- ✅ AWS SNS initialized successfully
- ✅ OTP SMS sent successfully
- ✅ MessageId received (means AWS accepted the request)

**The backend is working correctly!**

---

## 🔍 Step 1: Check AWS SNS Delivery Status

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Delivery status** tab
3. **Check recent messages:**
   - Look for your phone number
   - Check delivery status (Success/Failed)
   - Check delivery time

**This shows if SMS was delivered or failed.**

---

## 🔍 Step 2: Check CloudWatch Logs

### In AWS Console:

1. **CloudWatch** → **Log groups**
2. **Search:** `/aws/sns/eu-north-1`
3. **View recent logs** for delivery status

**Or check metrics:**
1. **CloudWatch** → **Metrics** → **SNS**
2. **View:** NumberOfMessagesPublished, NumberOfMessagesDelivered

---

## 🔍 Step 3: Verify Phone Number

### Check:

1. **Phone number is correct?**
   - Format: `9876543210` (10 digits)
   - Should be active and can receive SMS

2. **Try with different phone number:**
   ```bash
   curl -X POST http://api.easybasket.in/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber": "YOUR_ACTUAL_PHONE_NUMBER"}'
   ```

---

## 🔍 Step 4: Check SMS Delivery Delays

### Common Issues:

1. **Carrier delays:** Can take 1-5 minutes
2. **Spam filtering:** Check spam/junk folder
3. **DND (Do Not Disturb):** Phone might have DND enabled
4. **Network issues:** Poor signal can delay SMS

---

## 🔍 Step 5: Test with Real Phone Number

### From Your Mac:

```bash
# Replace with YOUR actual phone number (10 digits, no +91)
curl -X POST http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "YOUR_PHONE_NUMBER"}'
```

**Wait 1-2 minutes and check your phone.**

---

## 🔍 Step 6: Check AWS SNS Account Preferences

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Account preferences**
3. **Check:**
   - **Default message type:** Should be "Transactional"
   - **Spending limit:** Should not be $0
   - **Delivery status logging:** Should be enabled

---

## 🔍 Step 7: Check Phone Number Restrictions

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Phone numbers** tab
3. **Check if your number is blocked or restricted**

---

## 🔍 Step 8: Test Directly with AWS CLI

### On EC2 (if AWS CLI installed):

```bash
# Test sending SMS directly
aws sns publish \
  --phone-number "+91YOUR_PHONE_NUMBER" \
  --message "Test OTP: 123456" \
  --region eu-north-1

# Check response
```

**If this works, SNS is fine. If not, check IAM permissions or account settings.**

---

## 📋 Common Reasons SMS Not Received

1. **SMS in spam/junk folder** → Check spam folder
2. **Carrier delay** → Wait 2-5 minutes
3. **DND enabled** → Disable DND on phone
4. **Wrong phone number** → Verify number is correct
5. **Network issues** → Check phone signal
6. **AWS account restrictions** → Check SNS account preferences
7. **Spending limit reached** → Check spending limits

---

## 🔍 Step 9: Check MessageId in AWS Console

### From Your Logs:

You have MessageIds like:
- `6de8560b-13ee-5f92-b522-37a0ba6f7d5a`

### In AWS Console:

1. **CloudWatch** → **Logs Insights**
2. **Select log group:** `/aws/sns/eu-north-1`
3. **Query:**
   ```
   fields @timestamp, @message
   | filter @message like /6de8560b-13ee-5f92-b522-37a0ba6f7d5a/
   | sort @timestamp desc
   ```

**This shows delivery status for that specific message.**

---

## ✅ Verification Steps

1. **Check AWS SNS Console** → Delivery status
2. **Check phone spam folder**
3. **Wait 2-5 minutes** (carrier delays)
4. **Try with different phone number**
5. **Check CloudWatch logs** for delivery status

---

## 🎯 Quick Test

**Test with your actual phone number:**

```bash
# Replace YOUR_PHONE with your 10-digit number
curl -X POST http://api.easybasket.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "YOUR_PHONE"}'
```

**Then:**
1. Wait 2-5 minutes
2. Check phone (including spam folder)
3. Check AWS SNS console for delivery status

---

**Your backend is working! Check AWS SNS console for delivery status. 📱**

