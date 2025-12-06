# 📱 Google Play Store Launch Guide

Complete guide to launch Easy Basket on Google Play Store.

---

## 📋 Prerequisites

1. **Google Play Console Account**
   - Create account: https://play.google.com/console
   - One-time registration fee: $25 USD (one-time payment)
   - Required: Google account

2. **App Assets Ready**
   - App icon (512x512px, PNG)
   - Feature graphic (1024x500px, PNG)
   - Screenshots (at least 2, max 8)
   - App description (4000 chars max)
   - Short description (80 chars max)

3. **App Signing Key**
   - Generate signing key for release builds

---

## 🔧 Step 1: Configure App for Release

### 1.1 Update App Version

**File:** `mobile/pubspec.yaml`

```yaml
version: 1.0.0+1  # Format: version_name+build_number
```

**For Play Store:**
- `version_name`: User-visible version (e.g., "1.0.0")
- `build_number`: Internal build number (increment for each upload)

**Example:**
```yaml
version: 1.0.0+1  # First release
version: 1.0.1+2  # Bug fix release
version: 1.1.0+3  # Feature release
```

### 1.2 Update App Name & Description

**File:** `mobile/pubspec.yaml`

```yaml
name: easy_basket
description: Easy Basket - Instant Grocery Delivery App for Nurpur Bedi
```

### 1.3 Configure Android App

**File:** `mobile/android/app/build.gradle.kts`

Ensure these are set:

```kotlin
android {
    namespace = "com.example.easy_basket"
    compileSdk = 34  // Use latest SDK

    defaultConfig {
        applicationId = "com.easybasket.app"  // Your unique package name
        minSdk = 21  // Android 5.0+
        targetSdk = 34
        versionCode = 1  // Increment for each release
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

**Important:** Change `applicationId` to your unique package name (e.g., `com.easybasket.app` or `com.yourcompany.easybasket`)

### 1.4 Update AndroidManifest.xml

**File:** `mobile/android/app/src/main/AndroidManifest.xml`

Ensure permissions and app info are correct:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    
    <application
        android:label="Easy Basket"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Your activities -->
    </application>
</manifest>
```

---

## 🔐 Step 2: Generate App Signing Key

### 2.1 Create Keystore

**On Mac/Linux:**

```bash
cd ~/Projects/easyBucket/mobile/android

keytool -genkey -v -keystore easy-basket-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias easy-basket-key \
  -storepass YOUR_KEYSTORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD
```

**Important:**
- Save the keystore file securely (you'll need it for all future updates)
- Remember the passwords (store them securely)
- The keystore file should be backed up (if lost, you can't update the app)

### 2.2 Configure Signing in build.gradle.kts

**File:** `mobile/android/app/build.gradle.kts`

Add signing config:

```kotlin
android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            storeFile = file("../easy-basket-key.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "YOUR_KEYSTORE_PASSWORD"
            keyAlias = "easy-basket-key"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "YOUR_KEY_PASSWORD"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

**Security Note:** For production, use environment variables instead of hardcoding passwords:

```bash
# Add to ~/.zshrc or ~/.bashrc
export KEYSTORE_PASSWORD="your_keystore_password"
export KEY_PASSWORD="your_key_password"
```

---

## 🏗️ Step 3: Build Release App Bundle (AAB)

### 3.1 Build AAB (Recommended for Play Store)

```bash
cd ~/Projects/easyBucket/mobile

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle (AAB)
flutter build appbundle --release
```

**Output:** `mobile/build/app/outputs/bundle/release/app-release.aab`

### 3.2 Build APK (Alternative - for testing)

```bash
flutter build apk --release
```

**Output:** `mobile/build/app/outputs/flutter-apk/app-release.apk`

**Note:** Play Store prefers AAB format (smaller size, optimized delivery)

---

## 📱 Step 4: Test Release Build

### 4.1 Install on Device

```bash
# Install APK on connected device
flutter install --release

# Or manually install
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 4.2 Test Checklist

- [ ] App launches without crashes
- [ ] Login with OTP (1234) works
- [ ] All screens load correctly
- [ ] API calls work (check API URL in app_config.dart)
- [ ] Payment flow works (Razorpay)
- [ ] Location services work
- [ ] Cart persistence works
- [ ] Orders display correctly
- [ ] No console errors

---

## 🎨 Step 5: Prepare Store Assets

### 5.1 App Icon

**Requirements:**
- Size: 512x512px
- Format: PNG (32-bit)
- No transparency
- High quality

**Location:** Create `mobile/assets/store/app-icon.png`

### 5.2 Feature Graphic

**Requirements:**
- Size: 1024x500px
- Format: PNG or JPG
- Shows app name/logo

**Location:** Create `mobile/assets/store/feature-graphic.png`

### 5.3 Screenshots

**Requirements:**
- At least 2 screenshots
- Maximum 8 screenshots
- Size: 16:9 or 9:16 aspect ratio
- Minimum width: 320px
- Maximum width: 3840px

**Recommended screenshots:**
1. Home screen with categories
2. Product listing
3. Cart screen
4. Order tracking
5. Payment screen

**Location:** Create `mobile/assets/store/screenshots/`

### 5.4 App Description

**Short Description (80 chars max):**
```
Instant grocery delivery in Nurpur Bedi. Order fresh groceries in 10-20 minutes!
```

**Full Description (4000 chars max):**
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

---

## 🚀 Step 6: Create Google Play Console Account

### 6.1 Sign Up

1. Go to: https://play.google.com/console
2. Sign in with Google account
3. Pay one-time $25 registration fee
4. Complete account setup

### 6.2 Create App

1. Click **"Create app"**
2. Fill in:
   - **App name:** Easy Basket
   - **Default language:** English (India)
   - **App or game:** App
   - **Free or paid:** Free
   - **Declarations:** Accept terms

---

## 📤 Step 7: Upload App to Play Console

### 7.1 Create Production Release

1. Go to **Production** → **Create new release**
2. Upload `app-release.aab` file
3. Add **Release name:** "1.0.0 - Initial Release"
4. Add **Release notes:**
   ```
   🎉 Welcome to Easy Basket!
   
   • Instant grocery delivery in Nurpur Bedi
   • Browse products by category
   • Fast checkout with multiple payment options
   • Real-time order tracking
   • Save multiple delivery addresses
   ```

### 7.2 Complete Store Listing

1. Go to **Store presence** → **Main store listing**
2. Upload:
   - App icon (512x512px)
   - Feature graphic (1024x500px)
   - Screenshots (at least 2)
3. Fill in:
   - App name: Easy Basket
   - Short description (80 chars)
   - Full description (4000 chars)
   - App category: Shopping
   - Contact details

### 7.3 Content Rating

1. Go to **Content rating**
2. Fill questionnaire:
   - Category: Shopping
   - User-generated content: No
   - Violence, etc.: None
3. Submit for rating (takes 1-2 days)

### 7.4 Privacy Policy

**Required for Play Store!**

Create a privacy policy page and add URL in:
- **Store listing** → **Privacy Policy URL**

**Quick Privacy Policy Template:**

Create `PRIVACY_POLICY.md` or host on your website:

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

**Host it on:**
- GitHub Pages (free)
- Your website
- Privacy policy generator

### 7.5 App Access

1. Go to **App access**
2. Select: **All functionality is available without restrictions**

### 7.6 Target Audience

1. Go to **Target audience**
2. Select: **All ages**
3. Complete questionnaire

---

## ✅ Step 8: Submit for Review

### 8.1 Pre-Launch Checklist

- [ ] App bundle uploaded
- [ ] Store listing complete
- [ ] Screenshots added
- [ ] Privacy policy URL added
- [ ] Content rating complete
- [ ] App tested on real device
- [ ] API endpoints working
- [ ] No crashes or errors

### 8.2 Submit

1. Go to **Production** → **Review**
2. Click **"Start rollout to Production"**
3. Review will take 1-7 days
4. You'll receive email when approved/rejected

---

## 🔄 Step 9: Update App (Future Releases)

### 9.1 Increment Version

**File:** `mobile/pubspec.yaml`

```yaml
version: 1.0.1+2  # Increment version_name and build_number
```

**File:** `mobile/android/app/build.gradle.kts`

```kotlin
versionCode = 2  // Increment
versionName = "1.0.1"
```

### 9.2 Build & Upload

```bash
flutter build appbundle --release
```

Upload new AAB to Play Console → **Production** → **Create new release**

---

## 🛠️ Troubleshooting

### Build Errors

**Error: "Gradle build failed"**
```bash
cd mobile/android
./gradlew clean
cd ../..
flutter clean
flutter pub get
flutter build appbundle --release
```

**Error: "Signing config not found"**
- Check keystore file path in `build.gradle.kts`
- Verify passwords are correct

### Upload Errors

**Error: "Version code already used"**
- Increment `versionCode` in `build.gradle.kts`

**Error: "Package name already exists"**
- Change `applicationId` in `build.gradle.kts` to unique name

---

## 📋 Quick Command Reference

```bash
# Build release AAB
flutter build appbundle --release

# Build release APK (for testing)
flutter build apk --release

# Install on device
flutter install --release

# Check app version
cat mobile/pubspec.yaml | grep version

# Clean build
flutter clean && flutter pub get
```

---

## 🎯 Next Steps After Launch

1. **Monitor Reviews:** Respond to user feedback
2. **Analytics:** Set up Google Analytics
3. **Crash Reporting:** Add Firebase Crashlytics
4. **Updates:** Regular bug fixes and features
5. **Marketing:** Promote on social media

---

## 📞 Support

If you encounter issues:
1. Check Play Console → **Issues** tab
2. Review rejection reasons (if rejected)
3. Test on multiple devices
4. Check API endpoints are accessible

---

**Good luck with your launch! 🚀**

