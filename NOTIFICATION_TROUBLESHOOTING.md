# Notification Troubleshooting - Step by Step

## Current Issue: Admin not receiving notifications

### Step 1: Check Admin Device Logs

**On Android device, open Flutter debug console and look for:**

```
✅ Firebase initialized
📱 [FCM] Starting initialization...
📱 [FCM] Permission status: AuthorizationStatus.authorized
✅ [FCM] Permission granted, proceeding...
📱 [FCM] Token generated: [long token]
📤 [FCM] Sending token to backend: [token]...
✅ [FCM] Token sent to backend successfully
```

**If you don't see these logs:**
- Notification service might not be initializing
- Check if user is logged in
- Check Firebase initialization

### Step 2: Check Backend Logs

**When admin logs in, look for:**
```
📱 [AUTH] Updating FCM token for user [id] ([phone])
✅ [AUTH] FCM token updated successfully
```

**When order is placed, look for:**
```
📤 [ORDER] Sending notification to admin for order #[id]
📤 [FCM] Sending notification to role: admin
📤 [FCM] Found [X] admin users
📤 [FCM] Sending to user [id] ([phone]), token: [token]...
✅ [FCM] Notification sent successfully to user [id]
📤 [ORDER] Notification sent to [X] admin user(s)
```

### Step 3: Verify Database

**Check if admin has FCM token:**
```sql
SELECT id, phoneNumber, role, 
       CASE WHEN fcmToken IS NOT NULL THEN 'YES' ELSE 'NO' END as has_token,
       LENGTH(fcmToken) as token_length
FROM user 
WHERE role = 'admin' AND isActive = true;
```

**Expected:**
- `has_token` should be `YES`
- `token_length` should be > 100

### Step 4: Check Backend Firebase Initialization

**Look for in backend startup logs:**
```
✅ Firebase Admin initialized
```

**If you see:**
- `Firebase service account not configured` → Check `.env` file
- `Firebase initialization error` → Check JSON format

### Step 5: Test Notification Manually

**From Firebase Console:**
1. Go to Firebase Console → Cloud Messaging
2. Send test message
3. Use admin's FCM token from database
4. Check if notification arrives

## Common Issues & Fixes

### Issue 1: FCM Token Not Generated
**Symptoms:** No `📱 [FCM] Token generated` in logs
**Fix:**
- Check notification permission is granted
- Restart app
- Check Firebase is initialized

### Issue 2: Token Not Sent to Backend
**Symptoms:** Token generated but not in database
**Fix:**
- Check API call to `/auth/profile` succeeds
- Check backend logs for errors
- Verify auth token is valid

### Issue 3: Backend Not Finding Admin Users
**Symptoms:** `Found 0 admin users` in logs
**Fix:**
- Verify admin user exists in database
- Check `role = 'admin'` and `isActive = true`
- Verify user has FCM token

### Issue 4: FCM Not Initialized
**Symptoms:** `FCM not initialized` in backend logs
**Fix:**
- Check `FIREBASE_SERVICE_ACCOUNT` in `.env`
- Verify JSON format is correct
- Restart backend server

### Issue 5: Notification Permission Denied
**Symptoms:** `Permission not granted` in logs
**Fix:**
- Go to device Settings → Apps → Easy Basket → Notifications
- Enable notifications
- Restart app

## Quick Diagnostic Commands

**Check admin FCM token in database:**
```bash
# Replace with your database credentials
mysql -u root -p -e "USE easy_basket; SELECT id, phoneNumber, role, fcmToken IS NOT NULL as has_token FROM user WHERE role='admin';"
```

**Check backend FCM initialization:**
```bash
# Look for this in backend logs
grep -i "firebase" backend_logs.txt
```

**Test FCM token manually:**
```bash
# Use curl to test FCM API (replace with actual token)
curl -X POST https://fcm.googleapis.com/v1/projects/easy-basket-84b0d/messages:send \
  -H "Authorization: Bearer [ACCESS_TOKEN]" \
  -H "Content-Type: application/json" \
  -d '{"message":{"token":"[FCM_TOKEN]","notification":{"title":"Test","body":"Test message"}}}'
```

