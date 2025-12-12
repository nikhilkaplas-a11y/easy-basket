# FCM Token Fix Summary

## Problem
Admin user's FCM token was empty in the database, preventing push notifications from being received.

## Root Cause
The notification service was only initialized in the `main.dart` builder callback, which runs once when the app starts. If:
1. User logs in fresh (notification service not initialized yet)
2. User was already logged in from previous session (service might not have initialized properly)
3. Notification permission was denied initially

Then the FCM token would never be generated or sent to the backend.

## Solution Implemented

### 1. **Initialize After Login** (`login_screen.dart`)
- Added notification service initialization immediately after successful login
- Ensures FCM token is generated right when user authenticates

### 2. **Token Retry Mechanism** (`notification_service_mobile.dart`)
- Added `ensureTokenSent()` method to manually trigger token generation and sending
- Handles cases where token exists but wasn't sent to backend
- Retries automatically if auth token wasn't available initially

### 3. **Prevent Multiple Initializations**
- Added `_isInitialized` flag to prevent duplicate initializations
- Still allows updating context/providers if service already initialized

### 4. **Auth Provider Integration** (`auth_provider.dart`)
- After successful login, automatically calls `ensureTokenSent()` to guarantee token is sent
- Small delay to ensure notification service has proper context

### 5. **Manual Refresh Option** (`admin_dashboard_screen.dart`)
- Added "Refresh FCM Token" menu item in admin dashboard
- Allows manual refresh if token is missing or needs updating

## How to Test

### Step 1: Logout and Login Again
1. Logout from admin app
2. Login again with admin credentials
3. Check Flutter debug console for:
   ```
   📱 [LOGIN] Initializing notification service after login...
   📱 [FCM] Starting initialization...
   📱 [FCM] Token generated: [token]
   📤 [FCM] Sending token to backend...
   ✅ [FCM] Token sent to backend successfully
   ```

### Step 2: Check Backend Logs
When admin logs in, you should see:
```
📱 [AUTH] Updating FCM token for user [id] ([phone])
✅ [AUTH] FCM token updated successfully
```

### Step 3: Verify Database
```sql
SELECT id, phoneNumber, role, 
       fcmToken IS NOT NULL as has_token,
       LENGTH(fcmToken) as token_length
FROM user 
WHERE role = 'admin' AND isActive = true;
```

Expected: `has_token = 1`, `token_length > 100`

### Step 4: Test Notification
1. Place an order from customer app
2. Check backend logs for notification sending
3. Admin device should receive notification

### Step 5: Manual Refresh (if needed)
1. Go to Admin Dashboard
2. Click menu (three dots)
3. Select "Refresh FCM Token"
4. Check for success message

## Debugging

If token is still empty:

1. **Check Notification Permission**
   - Device Settings → Apps → Easy Basket → Notifications
   - Must be enabled

2. **Check Flutter Logs**
   - Look for `📱 [FCM]` messages
   - Check for errors

3. **Check Backend Logs**
   - Look for `📱 [AUTH]` messages
   - Check for FCM token update

4. **Manual Refresh**
   - Use "Refresh FCM Token" option in admin menu

5. **Restart App**
   - Sometimes restart helps if service didn't initialize properly

## Files Changed

- `mobile/lib/screens/auth/login_screen.dart` - Initialize after login
- `mobile/lib/services/notification_service_mobile.dart` - Added `ensureTokenSent()` and initialization guard
- `mobile/lib/providers/auth_provider.dart` - Auto-trigger token send after login
- `mobile/lib/screens/admin/admin_dashboard_screen.dart` - Manual refresh option

