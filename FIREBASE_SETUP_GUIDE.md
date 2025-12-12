# Firebase Setup Guide for Push Notifications

## ✅ What's Implemented

1. **Firebase packages enabled** in `pubspec.yaml`
2. **NotificationService created** - Handles all FCM operations
3. **Firebase initialized** in `main.dart`
4. **Notification handlers** for all app states:
   - Foreground (app open) → In-app SnackBar
   - Background (app minimized) → System notification
   - Terminated (app closed) → System notification
5. **Auto-navigation** to orders page when notification tapped
6. **Auto-refresh** admin data when notification received

## 📋 Next Steps (Required for Notifications to Work)

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: "Easy Basket"
4. Enable Google Analytics (optional)
5. Create project

### 2. Add Android App to Firebase

1. In Firebase Console → Project Settings
2. Click "Add app" → Android
3. **Package name**: `com.easybasket.app` (check `android/app/build.gradle` for actual package)
4. Download `google-services.json`
5. Place it in `mobile/android/app/`

### 3. Add iOS App to Firebase (if needed)

1. In Firebase Console → Add app → iOS
2. **Bundle ID**: Check `ios/Runner.xcodeproj` for actual bundle ID
3. Download `GoogleService-Info.plist`
4. Place it in `mobile/ios/Runner/`

### 4. Configure Backend

1. In Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Download the JSON file
4. Add to backend `.env`:
   ```env
   FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}' # Paste entire JSON
   ```

### 5. Update Android Configuration

Edit `mobile/android/app/build.gradle`:
```gradle
dependencies {
    // ... existing dependencies
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

### 6. Test Notifications

1. Run the app on a physical device (notifications don't work on emulator)
2. Login as admin
3. Place an order from customer app
4. Admin should receive notification!

## 🔔 How It Works Now

### When Customer Places Order:

1. **Backend** creates order
2. **Backend** sends FCM to all admin users
3. **Admin Device** receives notification:
   - **App Closed**: System notification → Tap opens app → Navigates to orders
   - **App Background**: System notification → Tap brings app to foreground → Navigates to orders
   - **App Open**: In-app SnackBar → Tap "View" → Navigates to orders
4. **Auto-refresh** happens when notification received

### Notification Data Structure:

```json
{
  "title": "New Order Received",
  "body": "Order #123 for ₹500",
  "data": {
    "orderId": "123",
    "type": "new_order"
  }
}
```

## 🐛 Troubleshooting

### Notifications not working?

1. **Check Firebase setup**: Ensure `google-services.json` is in correct location
2. **Check permissions**: App should request notification permission on first launch
3. **Check FCM token**: Look for "FCM Token: ..." in debug console
4. **Check backend**: Ensure `FIREBASE_SERVICE_ACCOUNT` is set in backend `.env`
5. **Physical device**: Notifications don't work on emulator, use real device

### FCM Token not sent to backend?

- Token is sent automatically when:
  - User logs in
  - Token refreshes
  - Notification service initializes

## 📱 Testing Checklist

- [ ] Firebase project created
- [ ] Android app added to Firebase
- [ ] `google-services.json` added to `mobile/android/app/`
- [ ] Backend `.env` has `FIREBASE_SERVICE_ACCOUNT`
- [ ] App requests notification permission
- [ ] FCM token appears in debug console
- [ ] Test notification from Firebase Console works
- [ ] Order placement triggers notification to admin

## 🎯 Current Status

- ✅ Code implementation complete
- ⏳ Firebase project setup required
- ⏳ Backend FCM configuration required
- ⏳ Testing on physical device required

Once Firebase is configured, admins will receive push notifications even when the app is closed!

