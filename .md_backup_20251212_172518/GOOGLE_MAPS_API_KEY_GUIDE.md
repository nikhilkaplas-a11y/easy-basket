# How to Get Google Maps API Key - Step by Step Guide

## Prerequisites
- Google Account (Gmail account)
- Credit card (Google requires billing, but gives $200 free credit/month)

## Step-by-Step Instructions

### Step 1: Go to Google Cloud Console

1. Open your browser and go to: **https://console.cloud.google.com/**
2. Sign in with your Google account

### Step 2: Create or Select a Project

1. Click on the **project dropdown** at the top (next to "Google Cloud")
2. Click **"New Project"**
3. Enter project name: `Easy Basket` (or any name you prefer)
4. Click **"Create"**
5. Wait for project creation (takes 10-20 seconds)
6. Select the newly created project from the dropdown

**OR** if you already have a project:
- Just select it from the dropdown

### Step 3: Enable Billing (Required)

⚠️ **Important**: Google Maps requires billing, but gives you **$200 free credit per month** (enough for most apps)

1. Click on the **hamburger menu** (☰) at the top left
2. Go to **"Billing"**
3. Click **"Link a billing account"** or **"Create billing account"**
4. Fill in your billing information:
   - Country/Region
   - Business name (or your name)
   - Address
   - Payment method (credit/debit card)
5. Click **"Submit and enable billing"**

**Note**: You won't be charged unless you exceed $200/month in usage, which is very unlikely for a small app.

### Step 4: Enable Maps SDK

1. Click the **hamburger menu** (☰) at the top left
2. Go to **"APIs & Services"** → **"Library"**
3. In the search box, type: **"Maps SDK for Android"**
4. Click on **"Maps SDK for Android"**
5. Click **"Enable"** button
6. Wait for it to enable (takes a few seconds)

**Repeat for iOS** (if you plan to build iOS app):
1. Search for **"Maps SDK for iOS"**
2. Click **"Enable"**

**Optional - Enable for Web** (if you want maps on web):
1. Search for **"Maps JavaScript API"**
2. Click **"Enable"**

### Step 5: Create API Key

1. Go to **"APIs & Services"** → **"Credentials"** (from the left menu)
2. Click **"+ CREATE CREDENTIALS"** button at the top
3. Select **"API key"** from the dropdown
4. A popup will show your API key - **COPY IT NOW** (you'll need it)
5. Click **"Close"** (don't click "Restrict key" yet - we'll do that later)

### Step 6: (Recommended) Restrict the API Key

This prevents others from using your key and protects you from unexpected charges.

1. In the **Credentials** page, click on your newly created API key
2. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Check only:
     - ✅ **Maps SDK for Android** (if building Android)
     - ✅ **Maps SDK for iOS** (if building iOS)
     - ✅ **Maps JavaScript API** (if using on web)
3. Under **"Application restrictions"** (optional but recommended):
   - For **Android**: Select "Android apps"
     - Click "Add an item"
     - Enter package name: `com.easybasket.app` (or your app's package name)
     - Get SHA-1 certificate fingerprint (see below)
   - For **iOS**: Select "iOS apps"
     - Enter your bundle identifier
4. Click **"Save"** at the bottom

### Step 7: Get SHA-1 Certificate Fingerprint (For Android Restriction)

**For Debug (Development):**
```bash
cd mobile/android
./gradlew signingReport
```

Look for `SHA1:` under `Variant: debug` → `Config: debug`

**OR** use keytool:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**For Release (Production):**
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```

Copy the SHA-1 value (looks like: `AA:BB:CC:DD:EE:FF:...`)

### Step 8: Add API Key to Your App

#### For Android:

1. Open: `mobile/android/app/src/main/AndroidManifest.xml`
2. Find this line:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz1234567"/>
   ```

#### For iOS (if building iOS app):

1. Open: `mobile/ios/Runner/AppDelegate.swift`
2. Add at the top:
   ```swift
   import GoogleMaps
   ```
3. In `application:didFinishLaunchingWithOptions:` method, add:
   ```swift
   GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
   ```

### Step 9: Rebuild Your App

```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

## Quick Checklist

- [ ] Created Google Cloud project
- [ ] Enabled billing (with $200 free credit)
- [ ] Enabled "Maps SDK for Android"
- [ ] Enabled "Maps SDK for iOS" (if needed)
- [ ] Created API key
- [ ] (Optional) Restricted API key
- [ ] Added API key to AndroidManifest.xml
- [ ] Rebuilt the app

## Cost Information

- **Free Tier**: $200 credit per month
- **Maps SDK for Android**: $7 per 1,000 requests (after free tier)
- **Maps SDK for iOS**: $7 per 1,000 requests (after free tier)
- **Typical Usage**: Small app uses ~1,000-5,000 requests/month = **FREE**

## Troubleshooting

### "API key not valid"
- Check you copied the full key (no spaces)
- Verify key is enabled for Maps SDK
- Check billing is enabled

### "This API key is not authorized"
- Go to Credentials → Your API key
- Check "API restrictions" includes Maps SDK
- Check "Application restrictions" matches your app

### Map not showing
- Verify API key in AndroidManifest.xml
- Check key has Maps SDK enabled
- Rebuild app after adding key
- Check device has internet connection

## Security Best Practices

1. **Always restrict your API key** to specific APIs
2. **Add application restrictions** (Android package name, iOS bundle ID)
3. **Don't commit API key to public repositories**
4. **Use different keys for development and production**
5. **Monitor usage** in Google Cloud Console

## Monitoring Usage

1. Go to **"APIs & Services"** → **"Dashboard"**
2. See API usage and costs
3. Set up **billing alerts** to get notified if usage is high

## Need Help?

- Google Cloud Support: https://cloud.google.com/support
- Maps API Documentation: https://developers.google.com/maps/documentation
- Flutter Maps Plugin: https://pub.dev/packages/google_maps_flutter

---

**Once you have the API key, add it to `AndroidManifest.xml` and rebuild the app. The map will work! 🗺️**

