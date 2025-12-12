# Push Notifications Setup for Admin Dashboard

## Problem
Currently, when a customer places an order:
- ✅ Backend sends FCM notification to admin
- ❌ Flutter app doesn't receive notifications (Firebase commented out)
- ❌ Admin only knows about orders if app is open and auto-refresh happens

## Solution: Implement Firebase Cloud Messaging (FCM)

### How It Works

1. **App Closed/Terminated**: 
   - System shows push notification
   - Admin taps notification → App opens → Navigates to orders page

2. **App in Background**:
   - System shows push notification
   - Admin taps notification → App comes to foreground → Navigates to orders page

3. **App in Foreground**:
   - In-app notification (SnackBar/Toast)
   - Auto-refresh dashboard/orders
   - Navigate to orders if notification tapped

### Implementation Steps

1. **Enable Firebase packages** in `pubspec.yaml`
2. **Initialize Firebase** in `main.dart`
3. **Request notification permissions**
4. **Get FCM token** and send to backend on login
5. **Handle notifications** in all app states
6. **Update FCM token** when it refreshes

### Notification Flow

```
Customer Places Order
    ↓
Backend Creates Order
    ↓
Backend Sends FCM to Admin
    ↓
Admin Device Receives Notification:
    - If app closed: System notification
    - If app background: System notification  
    - If app foreground: In-app notification
    ↓
Admin Taps Notification
    ↓
App Opens/Navigates to Orders Page
    ↓
Auto-refresh Orders List
```

