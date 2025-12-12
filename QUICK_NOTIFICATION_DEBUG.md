# Quick Notification Debug Checklist

## 🔍 Immediate Checks

### 1. Check Admin Device Logs (Flutter Debug Console)

**Look for these logs when admin logs in:**
```
✅ Firebase initialized
📱 [NOTIFICATION] Initializing for user: admin
📱 [FCM] Starting initialization...
📱 [FCM] Permission status: AuthorizationStatus.authorized
✅ [FCM] Permission granted, proceeding...
📱 [FCM] Token generated: [long token]
📤 [FCM] Sending token to backend: [token]...
✅ [FCM] Token sent to backend successfully
```

**If missing:**
- Notification service not initializing → Check user is logged in
- No FCM token → Check notification permission
- Token not sent → Check auth token is available

### 2. Check Backend Logs

**When admin logs in:**
```
📱 [AUTH] Updating FCM token for user [id] ([phone])
✅ [AUTH] FCM token updated successfully
```

**When order is placed:**
```
📤 [ORDER] Sending notification to admin for order #[id]
📤 [FCM] Sending notification to role: admin
📤 [FCM] Found [X] admin users
📤 [FCM] Sending to user [id] ([phone]), token: [token]...
✅ [FCM] Notification sent successfully to user [id]
📤 [ORDER] Notification sent to [X] admin user(s)
```

### 3. Quick Database Check

**Run this SQL query:**
```sql
SELECT id, phoneNumber, role, 
       CASE WHEN fcmToken IS NOT NULL THEN 'YES' ELSE 'NO' END as has_token,
       LENGTH(fcmToken) as token_length,
       isActive
FROM user 
WHERE role = 'admin';
```

**Expected:**
- `has_token` = `YES`
- `token_length` > 100
- `isActive` = `1` (true)

### 4. Check Backend Firebase Status

**Look for in backend startup:**
```
✅ Firebase Admin initialized
```

**If you see:**
- `Firebase service account not configured` → Fix `.env`
- `Firebase initialization error` → Check JSON format

## 🚨 Most Common Issues

1. **FCM Token Not in Database**
   - Token not sent to backend
   - Check Flutter logs for "Token sent to backend"
   - Check backend logs for "FCM token updated"

2. **Backend Not Finding Admin**
   - Admin user doesn't have FCM token
   - Admin user `isActive = false`
   - Check database query above

3. **Firebase Not Initialized**
   - Backend `.env` missing `FIREBASE_SERVICE_ACCOUNT`
   - JSON format incorrect
   - Restart backend

4. **Permission Denied**
   - Device settings → Apps → Easy Basket → Notifications
   - Enable notifications
   - Restart app

## ✅ Next Steps

1. **Restart backend** to see new logs
2. **Restart admin app** on Android device
3. **Check logs** for the messages above
4. **Place test order** and watch backend logs
5. **Share logs** if issue persists

