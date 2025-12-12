# Firebase Setup Checklist

## ✅ Completed

1. **Firebase Project Created** ✅
   - Project ID: `easy-basket-84b0d`
   - Project Number: `265992505200`

2. **Android App Added to Firebase** ✅
   - Package name: `com.easybasket.app`
   - `google-services.json` present in `mobile/android/app/`

3. **Backend Firebase Service Account** ✅
   - Service account JSON file exists on Desktop
   - `FIREBASE_SERVICE_ACCOUNT` found in backend `.env`

4. **Flutter Packages** ✅
   - `firebase_core` and `firebase_messaging` added to `pubspec.yaml`
   - Packages installed

5. **Code Implementation** ✅
   - `NotificationService` created
   - Firebase initialized in `main.dart`
   - Notification handlers implemented

## ⚠️ Pending Setup

### 1. Android Build Configuration (REQUIRED)

The Android build files need Google Services plugin:

**File: `mobile/android/build.gradle.kts`**
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**File: `mobile/android/app/build.gradle.kts`**
Add at the top (after other plugins):
```kotlin
plugins {
    // ... existing plugins
    id("com.google.gms.google-services")
}
```

### 2. Verify Backend .env Format

The `FIREBASE_SERVICE_ACCOUNT` in backend `.env` should be:
```env
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"easy-basket-84b0d",...}'
```

The entire JSON should be on one line as a string.

### 3. Test Notification Service

After setup, test:
1. Run app on physical device (notifications don't work on emulator)
2. Login as admin
3. Check debug console for "FCM Token: ..."
4. Place order from customer app
5. Admin should receive notification

## 🔍 Verification Steps

1. **Check Android Build Files**
   - [ ] Google Services plugin in `build.gradle.kts`
   - [ ] Google Services plugin applied in `app/build.gradle.kts`

2. **Check Backend**
   - [ ] `FIREBASE_SERVICE_ACCOUNT` in `.env` (entire JSON as string)
   - [ ] Backend logs show "Firebase Admin initialized"

3. **Test App**
   - [ ] App requests notification permission
   - [ ] FCM token appears in debug console
   - [ ] Token sent to backend (check user.fcmToken in database)

## 🚀 Next Steps

1. Add Google Services plugin to Android build files
2. Verify backend .env format
3. Restart backend server
4. Test on physical device

