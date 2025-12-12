# Debug Notifications - Step by Step

## Issue: Nothing happens on admin app when notifications are sent

### Step 1: Check Backend is Sending Notifications

**On your production server (where PM2 is running):**

```bash
# Check PM2 logs
pm2 logs easy-basket-api --lines 100

# Look for when you place an order:
# 📤 [ORDER] Sending notification to admin for order #[id]
# ✅ [FCM] Notification sent successfully
```

**If you don't see these logs:**
- Backend might not be restarted
- Firebase might not be initialized
- Check: `pm2 restart easy-basket-api`

### Step 2: Check Admin Device Logs

**On the admin Android device, check Flutter debug console for:**

When notification is received:
```
📱 [FCM] Foreground message received: [message-id]
📱 [FCM] Title: New Order Received
📱 [FCM] Body: Order #[id] for ₹[amount]
📱 [FCM] Data: {orderId: "[id]", type: "new_order"}
🔄 [FCM] Refreshing admin data...
✅ [FCM] Stats refresh triggered
✅ [FCM] Orders refresh triggered
```

**If you don't see these logs:**
- Notification not reaching device
- FCM token might be invalid
- Check notification permission

### Step 3: Verify FCM Token

**Check if admin device FCM token matches database:**

1. **Get token from device logs:**
   ```
   📱 [FCM] Token generated: [token]
   ```

2. **Check database:**
   ```sql
   SELECT id, phoneNumber, fcmToken 
   FROM user 
   WHERE role = 'admin' AND isActive = true;
   ```

3. **Compare tokens** - They should match

### Step 4: Test Notification Flow

**Test 1: Backend Diagnostic**
```bash
# On production server
cd /path/to/backend
npx ts-node src/scripts/check-notifications.ts
```

Should show:
- ✅ Firebase Admin initialized
- ✅ Test notification sent successfully

**Test 2: Check Device Receives Test Notification**
- If test notification works but real orders don't → Issue in order creation flow
- If test notification doesn't work → Issue with FCM setup

### Step 5: Common Issues

#### Issue 1: Context Not Available
**Symptom:** `⚠️ [FCM] Context not available` in logs
**Fix:** 
- App might be in background/terminated
- Notification will still refresh data, just won't show SnackBar
- Check if admin dashboard auto-refreshes

#### Issue 2: Notification Permission Denied
**Symptom:** No notifications received
**Fix:**
- Settings → Apps → Easy Basket → Notifications → Enable
- Restart app

#### Issue 3: FCM Token Mismatch
**Symptom:** Backend sends but device doesn't receive
**Fix:**
- Logout and login again on admin device
- Use "Refresh FCM Token" in admin dashboard menu
- Verify token in database matches device

#### Issue 4: App Force-Stopped
**Symptom:** Notifications not received
**Fix:**
- Don't force-stop the app
- Let it run in background
- Check battery optimization settings

### Step 6: Debug Checklist

- [ ] Backend restarted with PM2 (`pm2 restart easy-basket-api`)
- [ ] Firebase initialized in backend logs
- [ ] Backend sends notification when order placed (check logs)
- [ ] Admin device has notification permission enabled
- [ ] Admin device FCM token matches database
- [ ] Admin app is running (not force-stopped)
- [ ] Check Flutter debug console for notification logs
- [ ] Test notification works (from diagnostic script)

### Step 7: What Should Happen

**When order is placed:**

1. **Backend:**
   ```
   📤 [ORDER] Sending notification to admin for order #[id]
   ✅ [FCM] Notification sent successfully
   ```

2. **Admin Device (if app is open):**
   ```
   📱 [FCM] Foreground message received
   🔄 [FCM] Refreshing admin data...
   ✅ [FCM] Stats refresh triggered
   ✅ [FCM] Orders refresh triggered
   ```
   - SnackBar should appear (if context available)
   - Admin dashboard should auto-refresh

3. **Admin Device (if app is in background):**
   - System notification should appear
   - Tapping notification opens app and navigates to orders

4. **Admin Device (if app is terminated):**
   - System notification should appear
   - Tapping notification opens app and navigates to orders

### Step 8: Manual Test

1. **Open admin app** on Android device
2. **Keep Flutter debug console open**
3. **Place test order** from web app
4. **Watch both:**
   - Backend PM2 logs
   - Admin device Flutter logs
5. **Check if:**
   - Backend sends notification
   - Device receives notification
   - Admin dashboard refreshes

## Next Steps

1. **Check backend PM2 logs** when placing order
2. **Check admin device Flutter logs** for notification receipt
3. **Verify FCM token** matches between device and database
4. **Test with diagnostic script** to isolate the issue

