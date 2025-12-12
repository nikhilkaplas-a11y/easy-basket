# 🔧 Fix: AWS SNS SMS Failures (0% Delivery Rate)

Your SMS are being sent but failing. This is usually due to AWS SNS SMS restrictions.

---

## 🔍 The Issue

- **Sent:** 3
- **Failed:** 3
- **Delivery rate:** 0%

**This means AWS SNS is receiving requests but failing to deliver.**

---

## 🔧 Fix 1: Request Production Access (Sandbox Removal)

### For India, AWS SNS SMS requires production access:

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Account preferences**
3. **Request production access:**
   - Click **Request production access**
   - Fill out the form:
     - **Use case:** OTP verification for grocery delivery app
     - **Website URL:** `https://api.easybasket.in`
     - **Description:** "We need to send OTP SMS to Indian phone numbers for user authentication in our grocery delivery app Easy Basket."
     - **Monthly SMS volume:** Estimate (e.g., 1000-5000)
   - **Submit**

**AWS will review and approve (usually 24-48 hours).**

---

## 🔧 Fix 2: Verify Phone Numbers (Sandbox Mode)

### If Still in Sandbox:

1. **SNS** → **Text messaging (SMS)**
2. **Phone numbers** tab
3. **Add phone numbers** to verify
4. **Enter phone number** (with country code: +91XXXXXXXXXX)
5. **Verify** (AWS will send verification code)

**In sandbox mode, you can only send to verified numbers.**

---

## 🔧 Fix 3: Check Account Preferences

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Account preferences**
3. **Check:**
   - **Default message type:** Should be "Transactional"
   - **Spending limit:** Should be set (not $0)
   - **Delivery status logging:** Should be enabled
   - **Account status:** Should show "Active" or "Pending"

---

## 🔧 Fix 4: Use Promotional SMS Type (Temporary)

### Update SNS Service:

**File:** `backend/src/services/sns.service.ts`

**Change SMS type from Transactional to Promotional:**

```typescript
MessageAttributes: {
  'AWS.SNS.SMS.SMSType': {
    DataType: 'String',
    StringValue: 'Promotional', // Changed from 'Transactional'
  },
},
```

**Then rebuild and restart:**

```bash
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
```

**Note:** Promotional SMS has lower delivery rates but might work in sandbox.

---

## 🔧 Fix 5: Check IAM Permissions

### Verify IAM User Has Correct Permissions:

1. **IAM** → **Users** → Your SNS user
2. **Permissions** tab
3. **Should have:**
   - `AmazonSNSFullAccess` OR
   - Custom policy with SNS publish permissions

**If missing, add `AmazonSNSFullAccess`.**

---

## 🔍 Step 6: Check Error Details

### In AWS Console:

1. **CloudWatch** → **Logs Insights**
2. **Select log group:** `/aws/sns/eu-north-1` (or your region)
3. **Query:**
   ```
   fields @timestamp, @message
   | filter @message like /failed/ or @message like /error/
   | sort @timestamp desc
   | limit 20
   ```

**This shows why SMS are failing.**

---

## 🔍 Step 7: Check SMS Spending Limits

### In AWS Console:

1. **SNS** → **Text messaging (SMS)**
2. **Account preferences**
3. **Spending limits:**
   - **Monthly spending limit:** Should not be $0
   - **Set a limit** (e.g., $10 or $50)
   - **Save**

**If limit is $0, SMS won't be sent.**

---

## 📋 Common Failure Reasons

1. **Account in sandbox mode** → Request production access
2. **Phone numbers not verified** → Verify in sandbox
3. **Spending limit is $0** → Set spending limit
4. **Account restrictions** → Check account status
5. **India-specific restrictions** → May need special approval

---

## 🔧 Quick Fix Sequence

### Option 1: Request Production Access (Recommended)

1. **AWS Console** → **SNS** → **Text messaging (SMS)**
2. **Account preferences** → **Request production access**
3. **Fill form and submit**
4. **Wait for approval** (24-48 hours)

### Option 2: Verify Phone Numbers (Sandbox)

1. **SNS** → **Text messaging (SMS)** → **Phone numbers**
2. **Add phone numbers** to verify
3. **Verify each number**
4. **Test again**

### Option 3: Set Spending Limit

1. **SNS** → **Text messaging (SMS)** → **Account preferences**
2. **Set monthly spending limit** (e.g., $10)
3. **Save**

---

## 🎯 Most Likely Issue

**Account is in sandbox mode and needs production access.**

**Fix:**
1. Request production access in AWS Console
2. Or verify phone numbers if staying in sandbox

---

## 📋 Action Items

1. **Request production access** (AWS Console)
2. **Set spending limit** (if not set)
3. **Verify phone numbers** (if in sandbox)
4. **Check account status** in SNS console
5. **Wait for approval** (if requested)

---

**Request production access in AWS SNS console - that's most likely the issue! 🔧**

