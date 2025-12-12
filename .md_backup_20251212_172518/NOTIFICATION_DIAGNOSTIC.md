# Notification Diagnostic Steps

## Issue: Admin not receiving notifications when order is placed via web app

### Step 1: Check Backend Logs

When you place an order, check the backend console for these logs:

```
📤 [ORDER] Sending notification to admin for order #[id]
📤 [FCM] Sending notification to role: admin
📤 [FCM] Found [X] admin users
📤 [FCM] Sending to user [id] ([phone]), token: [token]...
✅ [FCM] Notification sent successfully to user [id]
📤 [ORDER] Notification sent to [X] admin user(s)
```

**If you see:**
- `⚠️ [FCM] FCM not initialized` → Firebase not configured
- `Found 0 admin users` → No admin users in database
- `User [id] has no FCM token` → Admin device hasn't sent FCM token
- `❌ [FCM] Error sending notification` → FCM token invalid or expired

### Step 2: Check Admin FCM Token in Database

Run this SQL query:
```sql
SELECT id, phoneNumber, role, 
       CASE WHEN fcmToken IS NOT NULL THEN 'YES' ELSE 'NO' END as has_token,
       LENGTH(fcmToken) as token_length,
       isActive
FROM user 
WHERE role = 'admin' AND isActive = true;
```

**Expected:**
- `has_token` = `YES`
- `token_length` > 100
- `isActive` = `1`

### Step 3: Verify Firebase Initialization

Check backend startup logs for:
```
✅ Firebase Admin initialized
```

**If you see:**
- `Firebase service account not configured` → Check `.env` file
- `Firebase initialization error` → Check JSON format in `.env`

### Step 4: Test Notification Manually

Run the diagnostic script:
```bash
cd backend
npx ts-node src/scripts/check-notifications.ts
```

This will:
1. Check if Firebase is initialized
2. List all admin users and their FCM token status
3. Send a test notification

### Step 5: Check Admin Device

On the admin Android device:

1. **Check Flutter logs for:**
   ```
   📱 [FCM] Token generated: [token]
   ✅ [FCM] Token sent to backend successfully
   ```

2. **Verify notification permission:**
   - Settings → Apps → Easy Basket → Notifications
   - Must be enabled

3. **Check if app is running:**
   - Notifications work when app is in foreground, background, or terminated
   - But check if app is completely closed

### Step 6: Common Issues & Fixes

#### Issue 1: FCM Token Not in Database
**Fix:**
- Logout and login again on admin device
- Use "Refresh FCM Token" in admin dashboard menu
- Check Flutter logs to confirm token is sent

#### Issue 2: Firebase Not Initialized
**Fix:**
- Check `FIREBASE_SERVICE_ACCOUNT` in backend `.env`
- Verify JSON format is correct (no extra quotes, valid JSON)
- Restart backend server

#### Issue 3: Invalid FCM Token
**Fix:**
- FCM tokens can expire or become invalid
- Logout and login again to get new token
- Use "Refresh FCM Token" option

#### Issue 4: Notification Permission Denied
**Fix:**
- Go to device Settings → Apps → Easy Basket → Notifications
- Enable notifications
- Restart app

### Step 7: Debug Commands

**Check backend is running:**
```bash
curl http://localhost:3000/api/health
```

**Check admin users:**
```bash
# Connect to database and run SQL query above
```

**Test notification manually:**
```bash
cd backend
npx ts-node src/scripts/check-notifications.ts
```

### Step 8: Real-time Debugging

1. **Open backend terminal** - Watch for logs when order is placed
2. **Open Flutter debug console** on admin device - Watch for notification receipt
3. **Place test order** from web app
4. **Check both logs simultaneously** to see where the flow breaks

## Expected Flow

1. ✅ Order placed via web app
2. ✅ Backend receives order creation request
3. ✅ Backend calls `FCMService.sendNotificationToRole('admin', ...)`
4. ✅ Backend finds admin users with FCM tokens
5. ✅ Backend sends notification via Firebase
6. ✅ Firebase delivers notification to admin device
7. ✅ Admin device receives and displays notification

## Next Steps

1. Run the diagnostic script
2. Check backend logs when placing order
3. Verify admin has FCM token in database
4. Check Firebase initialization
5. Test notification manually

