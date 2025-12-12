# 📱 Google Play Console Account Setup Guide

Complete step-by-step guide to create a Google Play Console account and launch Easy Basket.

---

## 📋 Prerequisites

Before you start, you'll need:

1. **Google Account** (Gmail)
   - If you don't have one, create at: https://accounts.google.com/signup

2. **Payment Method**
   - Credit card or debit card
   - For one-time $25 registration fee

3. **Business Information** (optional but recommended)
   - Business name (if applicable)
   - Address
   - Phone number

---

## 🚀 Step 1: Create Google Play Console Account

### 1.1 Go to Play Console

1. Open your browser
2. Go to: **https://play.google.com/console**
3. Sign in with your Google account

### 1.2 Accept Terms

1. Read the **Developer Distribution Agreement**
2. Check the box to accept terms
3. Click **"Continue"**

### 1.3 Pay Registration Fee

1. You'll see: **"Pay registration fee"**
2. **Fee:** $25 USD (one-time, lifetime)
3. Click **"Pay registration fee"**
4. Enter payment details:
   - Card number
   - Expiry date
   - CVV
   - Billing address
5. Click **"Buy"**
6. Wait for payment confirmation

**Note:** This is a one-time fee. You won't be charged again.

---

## 📝 Step 2: Complete Account Details

### 2.1 Account Type

1. Choose account type:
   - **Individual** - Personal developer account ✅ **RECOMMENDED FOR YOU**
   - **Organization** - Business/company account

2. **For Easy Basket, choose:**
   - ✅ **Individual** - Choose this if you don't have an organization yet
   - **Organization** - Only if you have a registered business/company

**Why Individual?**
- ✅ Easier to set up (no business documents needed)
- ✅ Same features as Organization account
- ✅ Can upgrade to Organization later if needed
- ✅ Perfect for starting out
- ✅ $25 fee is the same for both

### 2.2 Account Information

**For Individual:**
- Full name
- Email (already filled from Google account)
- Phone number
- Country/Region

**For Organization:**
- Organization name
- Contact name
- Email
- Phone number
- Address
- Country/Region

### 2.3 Verify Phone Number

1. Enter your phone number
2. Click **"Send verification code"**
3. Enter the code you receive via SMS
4. Click **"Verify"**

---

## ✅ Step 3: Complete Account Setup

### 3.1 Developer Profile

1. Fill in developer information:
   - **Developer name** (shown on Play Store)
   - **Email** (for support)
   - **Website** (optional)
   - **Phone** (for support)

2. Click **"Complete registration"**

### 3.2 Wait for Approval

- Account setup usually completes immediately
- Sometimes takes 24-48 hours for verification
- You'll receive an email when ready

---

## 📱 Step 4: Create Your First App

### 4.1 Create App

1. Once in Play Console, click **"Create app"**
2. Fill in app details:

   **App name:** Easy Basket
   
   **Default language:** English (India)
   
   **App or game:** App
   
   **Free or paid:** Free
   
   **Declarations:**
   - ☑ I understand that I need to comply with all applicable laws
   - ☑ I understand that I need to comply with Google Play policies

3. Click **"Create app"**

### 4.2 App Details

You'll be taken to the app dashboard. Don't worry about filling everything now - you can do it later.

---

## 🔐 Step 5: Set Up App Signing

### 5.1 App Signing by Google Play (Recommended)

**Where to Find App Signing:**

1. In Google Play Console, go to your app (Easy Basket)
2. In the left sidebar, look for:
   - **"Release"** → **"Setup"** → **"App signing"**
   - OR **"Setup"** → **"App signing"**
   - OR **"App integrity"** → **"App signing"**

3. You'll see **"App signing by Google Play"** section
4. Google Play will automatically manage your signing key
5. This is **enabled by default** for new apps

**Benefits:**
- ✅ Google stores your key securely
- ✅ You can't lose it
- ✅ Automatic key management
- ✅ No action needed - it's automatic!

**Note:** For new apps, Google Play automatically manages app signing. You don't need to do anything - it's already set up!

### 5.2 Alternative: Upload Your Own Key (Not Recommended)

If you prefer to manage your own key (advanced):
1. Generate keystore (we already have script: `generate-keystore.sh`)
2. Upload to Play Console
3. More complex, but you have full control

**For Easy Basket, we recommend using Google-managed signing (default).**

### 5.3 How to Verify App Signing is Set Up

1. Go to your app in Play Console
2. Navigate to: **"Release"** → **"Setup"** → **"App signing"**
3. You should see:
   - ✅ "App signing by Google Play" (enabled)
   - Upload key certificate (if you've uploaded an app)
   - App signing key certificate (managed by Google)

**If you can't find it:**
- It might appear after you upload your first app
- Or it might be under **"App integrity"** in the sidebar
- Don't worry - it's automatic for new apps!

---

## 📋 Step 6: Complete Required Information

### 6.1 Store Listing (Required)

1. Go to **"Store presence"** → **"Main store listing"**

2. **Required fields:**
   - **App name:** Easy Basket
   - **Short description:** (80 characters max)
     ```
     Instant grocery delivery in Nurpur Bedi. Order fresh groceries in 10-20 minutes!
     ```
   - **Full description:** (4000 characters max)
     ```
     Easy Basket - Your Instant Grocery Delivery Partner

     🚀 Get groceries delivered to your doorstep in just 10-20 minutes!

     Easy Basket brings you the convenience of instant grocery delivery right in Nurpur Bedi. Whether you need fresh vegetables, daily essentials, or snacks, we've got you covered.

     ✨ Features:
     • Fast Delivery: Get your groceries in 10-20 minutes
     • Wide Selection: Browse hundreds of products across multiple categories
     • Easy Ordering: Simple, intuitive interface for quick shopping
     • Multiple Payment Options: Pay via UPI, cards, or cash on delivery
     • Order Tracking: Track your order in real-time
     • Save Addresses: Save multiple addresses for quick checkout
     • Order History: View all your past orders

     🛒 How It Works:
     1. Browse products by category
     2. Add items to cart
     3. Select delivery address
     4. Choose payment method
     5. Get your order delivered in minutes!

     📍 Service Area:
     Currently serving Nurpur Bedi and surrounding areas (1-2 km radius).

     💳 Payment Options:
     • Razorpay (UPI, Cards, Net Banking)
     • Cash on Delivery (COD)

     📞 Support:
     Need help? Contact us through the app or email support@easybasket.in

     Download Easy Basket now and experience the fastest grocery delivery in town!
     ```

3. **Graphics:**
   - **App icon:** 512x512px PNG (required)
   - **Feature graphic:** 1024x500px PNG (required)
   - **Screenshots:** At least 2, max 8 (required)
     - Phone screenshots: 16:9 or 9:16
     - Minimum width: 320px
     - Maximum width: 3840px

4. Click **"Save"**

### 6.2 Content Rating (Required)

1. Go to **"Store presence"** → **"Content rating"**
2. Click **"Start questionnaire"**
3. Answer questions:
   - **Category:** Shopping
   - **User-generated content:** No
   - **Violence, etc.:** None
4. Submit for rating
5. **Wait 1-2 days** for rating to complete

### 6.3 Privacy Policy (Required)

1. Go to **"Store presence"** → **"Main store listing"**
2. Scroll to **"Privacy Policy"**
3. Enter URL: `https://easybasket.in/privacy-policy` (or your hosted URL)

**If you don't have a privacy policy yet:**
- Create one using a privacy policy generator
- Host it on GitHub Pages (free)
- Or host on your website

**Quick Privacy Policy Template:**
```
Privacy Policy for Easy Basket

Last updated: [Date]

1. Information We Collect
   - Phone number (for login)
   - Delivery addresses
   - Order history
   - Location data (for delivery)

2. How We Use Information
   - Process orders
   - Deliver products
   - Improve service

3. Data Security
   - Encrypted storage
   - Secure API connections

4. Contact
   Email: support@easybasket.in
```

### 6.4 App Access (Required)

1. Go to **"Store presence"** → **"App access"**
2. Select: **"All functionality is available without restrictions"**
3. Click **"Save"**

### 6.5 Target Audience (Required)

1. Go to **"Store presence"** → **"Target audience"**
2. Select: **"All ages"**
3. Complete questionnaire
4. Click **"Save"**

---

## 📤 Step 7: Upload Your App

### 7.1 Build App Bundle

**On your Mac:**

```bash
cd mobile
./build-release.sh
```

**Or manually:**

```bash
cd mobile
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### 7.2 Create Production Release

1. Go to **"Production"** → **"Create new release"**
2. Click **"Upload"**
3. Select your `app-release.aab` file
4. Wait for upload to complete

### 7.3 Add Release Notes

**Release name:** `1.0.0 - Initial Release`

**Release notes:**
```
🎉 Welcome to Easy Basket!

• Instant grocery delivery in Nurpur Bedi
• Browse products by category
• Fast checkout with multiple payment options
• Real-time order tracking
• Save multiple delivery addresses
```

5. Click **"Save"**

---

## ✅ Step 8: Review and Submit

### 8.1 Pre-Launch Checklist

Before submitting, verify:

- [ ] App bundle uploaded
- [ ] Store listing complete
- [ ] Screenshots added (at least 2)
- [ ] Privacy policy URL added
- [ ] Content rating complete
- [ ] App access configured
- [ ] Target audience set
- [ ] App tested on real device
- [ ] API endpoints working
- [ ] No crashes or errors

### 8.2 Submit for Review

1. Go to **"Production"** → **"Review"**
2. Review all sections (green checkmarks)
3. Click **"Start rollout to Production"**
4. Confirm submission

### 8.3 Review Process

- **Review time:** 1-7 days (usually 1-3 days)
- **You'll receive email:** When approved or rejected
- **If rejected:** Check email for reasons and fix issues

---

## 📊 Step 9: After Approval

### 9.1 App Goes Live

- App will be available on Play Store
- Users can search and download
- You can track downloads and reviews

### 9.2 Monitor Your App

1. **Dashboard:** View stats, downloads, ratings
2. **Reviews:** Respond to user feedback
3. **Analytics:** Track user behavior
4. **Crashes:** Monitor app stability

---

## 🔄 Step 10: Update Your App

### 10.1 For Future Updates

1. **Increment version:**
   ```yaml
   # pubspec.yaml
   version: 1.0.1+2  # Increment both
   ```

2. **Build new AAB:**
   ```bash
   flutter build appbundle --release
   ```

3. **Upload to Play Console:**
   - Go to **"Production"** → **"Create new release"**
   - Upload new AAB
   - Add release notes
   - Submit

---

## 💰 Pricing Information

### One-Time Costs

- **Google Play Console registration:** $25 USD (one-time, lifetime)
- **No monthly fees**
- **No per-app fees**

### Ongoing Costs

- **Google Play Console:** Free (after initial $25)
- **App hosting:** Free (Google hosts your app)
- **Updates:** Free (unlimited updates)

---

## 🆘 Troubleshooting

### Account Creation Issues

**Problem:** Payment fails
- **Solution:** Check card details, try different card, contact Google support

**Problem:** Phone verification fails
- **Solution:** Try different phone number, check SMS delivery

**Problem:** Account not approved
- **Solution:** Wait 24-48 hours, check email for updates

### App Submission Issues

**Problem:** App rejected
- **Solution:** Check email for rejection reasons, fix issues, resubmit

**Problem:** Missing required information
- **Solution:** Complete all required sections (marked with *)

**Problem:** Content rating pending
- **Solution:** Wait 1-2 days for rating to complete

---

## 📞 Support

### Google Play Console Support

- **Help Center:** https://support.google.com/googleplay/android-developer
- **Community:** https://support.google.com/googleplay/android-developer/community
- **Contact:** Through Play Console → Help → Contact us

---

## ✅ Quick Checklist

**Before Launch:**

- [ ] Google Play Console account created ($25 paid)
- [ ] App bundle (AAB) built
- [ ] App icon (512x512px) ready
- [ ] Feature graphic (1024x500px) ready
- [ ] Screenshots (at least 2) ready
- [ ] App description written
- [ ] Privacy policy URL ready
- [ ] Content rating completed
- [ ] App tested on real device
- [ ] All required sections completed

**Ready to Launch!** 🚀

---

## 📋 Next Steps After Account Creation

1. **Build your app bundle** (see `GOOGLE_PLAY_STORE_GUIDE.md`)
2. **Prepare store assets** (icons, screenshots)
3. **Write privacy policy**
4. **Upload app and submit for review**

---

**Good luck with your launch! 🎉**

