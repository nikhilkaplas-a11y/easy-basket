# 💳 Razorpay Setup Guide

## 📝 Step 1: Create Razorpay Account

### For India (Main Service)
1. **Visit:** https://razorpay.com/
2. **Click:** "Sign Up" (top right)
3. **Choose:** "Business Account" or "Individual Account"
4. **Fill Details:**
   - Business/Individual Name
   - Email Address
   - Phone Number
   - Password
5. **Verify Email & Phone** (OTP verification)
6. **Complete KYC:**
   - Business Details (if business account)
   - Bank Account Details
   - PAN Card
   - Address Proof
   - Business Documents (if applicable)

### Account Types
- **Individual:** For personal/small businesses
- **Business:** For registered companies
- **Startup:** Special plans for startups

---

## 🔑 Step 2: Get API Keys

### After Account Setup:

1. **Login to Razorpay Dashboard**
   - Go to: https://dashboard.razorpay.com/

2. **Navigate to Settings**
   - Click on **Settings** (left sidebar)
   - Go to **API Keys** section

3. **Generate Test Keys (For Development)**
   - Click **"Generate Test Key"**
   - Copy **Key ID** and **Key Secret**
   - ⚠️ **Save these securely!** You won't see the secret again

4. **Generate Live Keys (For Production)**
   - After KYC verification is complete
   - Click **"Generate Live Key"**
   - Copy **Key ID** and **Key Secret**
   - ⚠️ **Keep these secure!**

---

## 🧪 Step 3: Test Mode vs Live Mode

### Test Mode (Development)
- **Purpose:** Testing payment flows without real money
- **Test Cards:** Use Razorpay test cards
- **No Real Transactions:** Money doesn't actually transfer
- **When to Use:** During development and testing

### Live Mode (Production)
- **Purpose:** Real transactions with actual money
- **Real Cards:** Customer's real payment methods
- **Real Transactions:** Money transfers happen
- **When to Use:** After testing, when app goes live

---

## 🔧 Step 4: Configure in Your Project

### Backend Configuration

1. **Add to `.env` file:**
```env
# Razorpay Configuration
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=your_secret_key_here

# For Production
# RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxx
# RAZORPAY_KEY_SECRET=your_live_secret_key_here
```

2. **Backend is Already Configured!**
   - Payment service exists: `backend/src/services/payment.service.ts`
   - Payment controller exists: `backend/src/controllers/payment.controller.ts`
   - Routes exist: `backend/src/routes/payment.routes.ts`

### Frontend Configuration (To Be Done)

1. **Add Razorpay Flutter Package:**
```yaml
# In mobile/pubspec.yaml
dependencies:
  razorpay_flutter: ^1.3.0
```

2. **Initialize in Flutter:**
```dart
// In mobile/lib/main.dart or payment screen
import 'package:razorpay_flutter/razorpay_flutter.dart';

final _razorpay = Razorpay();
_razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
_razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
_razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
```

---

## 🧪 Step 5: Test Cards (Test Mode)

### Success Cards:
- **Card Number:** `4111 1111 1111 1111`
- **CVV:** Any 3 digits (e.g., `123`)
- **Expiry:** Any future date (e.g., `12/25`)
- **Name:** Any name

### Failure Cards:
- **Card Number:** `4000 0000 0000 0002` (Declined)
- **Card Number:** `4000 0000 0000 0069` (Insufficient Funds)

### UPI Test:
- Use any UPI ID (e.g., `test@razorpay`)
- Payment will succeed in test mode

---

## 📋 Step 6: KYC Requirements

### For Individual Account:
- ✅ PAN Card
- ✅ Aadhaar Card / Passport / Voter ID
- ✅ Bank Account Details
- ✅ Address Proof

### For Business Account:
- ✅ Business Registration Certificate
- ✅ PAN Card (Business)
- ✅ Bank Account (Business)
- ✅ Address Proof
- ✅ Authorized Signatory Documents

### KYC Processing Time:
- **Usually:** 1-3 business days
- **Can be faster:** If all documents are clear

---

## 💰 Step 7: Pricing & Fees

### Transaction Fees:
- **Domestic Cards:** 2% per transaction
- **International Cards:** 3% per transaction
- **UPI:** 0% (Free)
- **Netbanking:** 2% per transaction
- **Wallets:** 2% per transaction

### Settlement:
- **T+2:** Money credited to bank in 2 business days
- **T+1:** Available for premium accounts
- **T+0:** Available for enterprise accounts

---

## 🔒 Step 8: Security Best Practices

1. **Never Commit Keys to Git**
   - Use `.env` file (already in `.gitignore`)
   - Don't share keys publicly

2. **Use Environment Variables**
   - Test keys for development
   - Live keys only in production

3. **Webhook Security**
   - Verify webhook signatures
   - Use HTTPS for webhook URLs

4. **Key Rotation**
   - Rotate keys periodically
   - Revoke old keys when rotating

---

## 📱 Step 9: Mobile App Setup

### Android:
1. Add to `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

2. Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS:
1. Add to `ios/Runner/Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>razorpay</string>
</array>
```

---

## 🚀 Step 10: Go Live Checklist

- [ ] Complete KYC verification
- [ ] Test all payment methods
- [ ] Set up webhook endpoint
- [ ] Configure return URLs
- [ ] Test with real small amount
- [ ] Set up refund process
- [ ] Configure email notifications
- [ ] Set up customer support

---

## 📞 Support & Resources

### Razorpay Support:
- **Email:** help@razorpay.com
- **Phone:** 1800-123-1900 (India)
- **Dashboard:** https://dashboard.razorpay.com/
- **Documentation:** https://razorpay.com/docs/

### Useful Links:
- **Test Cards:** https://razorpay.com/docs/payments/test-cards/
- **API Docs:** https://razorpay.com/docs/api/
- **Flutter SDK:** https://razorpay.com/docs/payments/mobile/flutter/

---

## ⚡ Quick Start (Development)

1. **Sign up** at https://razorpay.com/
2. **Get test keys** from dashboard
3. **Add to `.env`:**
   ```
   RAZORPAY_KEY_ID=rzp_test_xxxxx
   RAZORPAY_KEY_SECRET=xxxxx
   ```
4. **Restart backend** to load new env vars
5. **Test with test cards** (see Step 5)

---

## 🎯 Next Steps

After setting up Razorpay account:
1. ✅ Get API keys
2. ✅ Add to `.env` file
3. ✅ Test payment flow
4. ⏳ Integrate Flutter SDK (we'll do this next)
5. ⏳ Test end-to-end payment
6. ⏳ Complete KYC for production

---

**Ready to integrate payments!** 🚀

