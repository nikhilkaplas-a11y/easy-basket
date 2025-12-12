# Test Notifications - Step by Step Guide

## Current Status ✅
- ✅ Firebase Admin initialized
- ✅ Admin user has FCM token (User ID: 1, Phone: 8360339165)
- ✅ Test notification sent successfully

## Issue: Not receiving notifications when placing orders

### Step 1: Restart Backend Server

The backend server needs to be restarted to pick up the fixed Firebase configuration:

```bash
cd backend

# Stop current server (Ctrl+C or kill the process)
# Then restart:
npm run dev
```

**Look for this in startup logs:**
```
✅ Firebase Admin initialized
```

### Step 2: Check Backend Logs When Placing Order

When you place an order from the web app, watch the backend console for:

```
📤 [ORDER] Sending notification to admin for order #[id]
📤 [FCM] Sending notification to role: admin
📤 [FCM] Found 1 admin users
📤 [FCM] Sending to user 1 (8360339165), token: eRX25fkURQCEK7iopiFE...
✅ [FCM] Notification sent successfully. Message ID: projects/easy-basket-84b0d/messages/...
✅ [FCM] Notification sent successfully to user 1
📤 [ORDER] Notification sent to 1 admin user(s)
```

**If you see errors:**
- `⚠️ [FCM] FCM not initialized` → Backend not restarted with new config
- `Found 0 admin users` → Admin user issue
- `User has no FCM token` → Admin device hasn't sent token
- `❌ [FCM] Error sending notification` → FCM token invalid/expired

### Step 3: Verify Admin Device

On the admin Android device:

1. **Check Flutter Debug Console for:**
   ```
   📱 [FCM] Token generated: [token]
   ✅ [FCM] Token sent to backend successfully
   ```

2. **Check Notification Permission:**
   - Settings → Apps → Easy Basket → Notifications
   - Must be enabled

3. **Check App State:**
   - Notifications work in all states (foreground, background, terminated)
   - But test with app in foreground first

### Step 4: Test Full Flow

1. **Restart backend:**
   ```bash
   cd backend
   npm run dev
   ```

2. **Open admin app** on Android device (keep Flutter debug console open)

3. **Place test order** from web app (customer login)

4. **Watch backend logs** - Should see notification sending logs

5. **Check admin device** - Should receive notification

### Step 5: Debug if Still Not Working

#### Check FCM Token is Valid

Run diagnostic:
```bash
cd backend
npx ts-node src/scripts/check-notifications.ts
```

Should show:
- ✅ Firebase Admin initialized
- ✅ Admin user has FCM token
- ✅ Test notification sent successfully

#### Check Admin Device Logs

On admin device, look for:
- `📱 [FCM]` messages
- Any errors related to notifications
- Token generation/sending logs

#### Verify FCM Token in Database

```sql
SELECT id, phoneNumber, role, 
       fcmToken IS NOT NULL as has_token,
       LENGTH(fcmToken) as token_length,
       SUBSTRING(fcmToken, 1, 30) as token_preview
FROM user 
WHERE role = 'admin' AND isActive = true;
```

Expected:
- `has_token` = 1
- `token_length` > 100
- `token_preview` should start with something like `eRX25fkURQCEK7iopiFEjC:APA91bG...`

### Step 6: Common Issues

#### Issue 1: Backend Not Restarted
**Symptom:** `⚠️ [FCM] FCM not initialized` in logs
**Fix:** Restart backend server

#### Issue 2: FCM Token Expired/Invalid
**Symptom:** `❌ [FCM] Error sending notification` with error code
**Fix:** 
- Logout and login again on admin device
- Use "Refresh FCM Token" in admin dashboard menu

#### Issue 3: Notification Permission Denied
**Symptom:** No notifications received
**Fix:**
- Settings → Apps → Easy Basket → Notifications → Enable
- Restart app

#### Issue 4: App Not Receiving Notifications
**Symptom:** Backend says sent, but device doesn't receive
**Fix:**
- Check notification permission
- Check if app is running (not force-stopped)
- Try with app in foreground first
- Check device battery optimization settings

### Step 7: Manual Test

Test notification manually from backend:

```bash
cd backend
npx ts-node src/scripts/check-notifications.ts
```

This will send a test notification. If this works but real orders don't, the issue is in the order creation flow.

## Quick Checklist

- [ ] Backend restarted with new Firebase config
- [ ] Firebase Admin initialized (check logs)
- [ ] Admin user has FCM token in database
- [ ] Admin device has notification permission enabled
- [ ] Admin app is running (not force-stopped)
- [ ] Backend logs show notification being sent when order placed
- [ ] Test notification works (from diagnostic script)

## Next Steps

1. **Restart backend server** (most likely fix)
2. **Place test order** and watch logs
3. **Check admin device** for notification
4. **Share logs** if still not working

