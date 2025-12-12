# 📱 Android Build & Testing Guide

## 🎯 Quick Start: Build APK for Testing

### Option 1: Run Directly on Emulator/Device (Recommended for Testing)

```bash
# 1. Start Android Studio and launch an emulator
# OR connect a physical Android device via USB

# 2. Check connected devices
cd mobile
flutter devices

# 3. Run the app
flutter run -d android
```

---

## 🔨 Build APK for Installation

### Step 1: Configure API URL for Android

Edit `mobile/lib/config/app_config.dart`:

```dart
class AppConfig {
  // For Android Emulator
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api';
  
  // For Physical Device (replace with your computer's IP)
  // Find IP: Mac/Linux: ifconfig | grep "inet " | grep -v 127.0.0.1
  //          Windows: ipconfig
  // static const String apiBaseUrl = 'http://192.168.1.100:3000/api';
}
```

### Step 2: Build Debug APK (For Testing)

```bash
cd mobile

# Build debug APK
flutter build apk --debug

# APK will be at: mobile/build/app/outputs/flutter-apk/app-debug.apk
```

### Step 3: Install on Device

**Option A: Using ADB (Android Debug Bridge)**
```bash
# Connect device via USB
# Enable USB Debugging on device

# Install APK
adb install build/app/outputs/flutter-apk/app-debug.apk
```

**Option B: Transfer APK to Device**
```bash
# Copy APK to device
# Install manually by tapping the APK file
```

---

## 🚀 Build Release APK (For Distribution)

### Step 1: Configure Signing (Required for Release)

1. **Generate Keystore:**
```bash
cd mobile/android
keytool -genkey -v -keystore easybasket-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias easybasket
```

2. **Create `key.properties` file:**
```bash
cd mobile/android
cat > key.properties << EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=easybasket
storeFile=easybasket-key.jks
EOF
```

3. **Update `android/app/build.gradle.kts`:**
```kotlin
// Add at the top
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing code ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ... existing code ...
        }
    }
}
```

### Step 2: Build Release APK

```bash
cd mobile

# Build release APK
flutter build apk --release

# APK will be at: mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Step 3: Build App Bundle (For Play Store)

```bash
cd mobile

# Build App Bundle (AAB)
flutter build appbundle --release

# AAB will be at: mobile/build/app/outputs/bundle/release/app-release.aab
```

---

## 🧪 Testing on Android Studio Emulator

### Step 1: Create/Launch Emulator

1. Open Android Studio
2. Go to **Tools → Device Manager**
3. Click **Create Device** (if no emulator exists)
4. Select a device (e.g., Pixel 5)
5. Select system image (e.g., API 33)
6. Click **Finish**
7. Click **▶️ Play** button to start emulator

### Step 2: Run App

```bash
cd mobile

# List available devices
flutter devices

# Run on emulator
flutter run -d android

# Or specify device ID
flutter run -d emulator-5554
```

---

## 📱 Testing on Physical Device

### Step 1: Enable Developer Options

1. Go to **Settings → About Phone**
2. Tap **Build Number** 7 times
3. Go back to **Settings → Developer Options**
4. Enable **USB Debugging**

### Step 2: Connect Device

```bash
# Connect via USB
# Verify connection
adb devices

# Should show your device
```

### Step 3: Run App

```bash
cd mobile
flutter run -d <device-id>
```

---

## 🔧 Troubleshooting

### Issue: "No devices found"

**Solution:**
```bash
# Check devices
flutter devices

# If no devices, start emulator or connect physical device
# For emulator:
emulator -avd <emulator-name>

# For physical device:
# Enable USB debugging and connect via USB
```

### Issue: "Gradle build failed"

**Solution:**
```bash
cd mobile/android
./gradlew clean

cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "API connection error"

**Solution:**
1. Make sure backend is running: `cd backend && npm run dev`
2. Check API URL in `app_config.dart`:
   - Emulator: `http://10.0.2.2:3000/api`
   - Physical device: `http://YOUR_COMPUTER_IP:3000/api`
3. Check firewall settings

### Issue: "Build failed - signing config"

**Solution:**
- For debug builds, signing is automatic
- For release builds, follow the signing setup above

---

## 📋 Complete Testing Workflow

### 1. Start Backend
```bash
cd backend
npm run dev
# Backend runs on http://localhost:3000
```

### 2. Configure API URL
Edit `mobile/lib/config/app_config.dart`:
- Emulator: `http://10.0.2.2:3000/api`
- Physical device: `http://YOUR_IP:3000/api`

### 3. Start Emulator or Connect Device
- Android Studio → Device Manager → Start Emulator
- OR connect physical device via USB

### 4. Run App
```bash
cd mobile
flutter run -d android
```

### 5. Test Features
- Login with OTP (use `1234` in dev mode)
- Browse products
- Add to cart
- Place order
- Track order

---

## 🎯 Quick Commands Reference

```bash
# Check Flutter setup
flutter doctor

# List devices
flutter devices

# Run on Android
flutter run -d android

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Install APK via ADB
adb install build/app/outputs/flutter-apk/app-debug.apk

# Check connected devices
adb devices

# View logs
flutter logs
```

---

## 📦 APK File Locations

- **Debug APK:** `mobile/build/app/outputs/flutter-apk/app-debug.apk`
- **Release APK:** `mobile/build/app/outputs/flutter-apk/app-release.apk`
- **App Bundle:** `mobile/build/app/outputs/bundle/release/app-release.aab`

---

## ✅ Pre-Launch Checklist

- [ ] Test on multiple Android versions (API 21+)
- [ ] Test on different screen sizes
- [ ] Test all features (login, cart, orders, payment)
- [ ] Test with slow network (throttle in DevTools)
- [ ] Test offline behavior
- [ ] Check app size (should be < 50MB)
- [ ] Test on physical devices
- [ ] Verify API connectivity
- [ ] Test payment flow (Razorpay)
- [ ] Check for crashes (use Firebase Crashlytics)

---

## 🚀 Next Steps After Testing

1. **Fix any bugs found during testing**
2. **Build release APK** for distribution
3. **Set up Play Store listing** (if publishing)
4. **Generate signed app bundle** for Play Store
5. **Test on multiple devices** before launch

---

**Happy Testing! 🎉**

