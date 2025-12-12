# Notification Debugging Guide

## Issue: Admin not receiving notifications when customer places order

### Debugging Steps

#### 1. Check FCM Token Generation (Admin Device)

**On Android device, check debug console for:**
```
📱 Notification permission status: AuthorizationStatus.authorized
📱 FCM Token: [long token string]
✅ FCM token sent to backend
```

**If you don't see FCM token:**
- Check notification permission is granted
- Check Firebase is initialized
- Check device has internet connection

#### 2. Verify FCM Token in Database

**Check backend database:**
```sql
SELECT id, phoneNumber, role, fcmToken, isActive 
FROM user 
WHERE role = 'admin';
```

**Expected:**
- Admin user should have `fcmToken` populated
- `isActive` should be `true`

#### 3. Check Backend FCM Initialization

**Check backend logs when server starts:**
```
✅ Firebase Admin initialized
```

**If you see:**
- `Firebase service account not configured` → Check `.env` has `FIREBASE_SERVICE_ACCOUNT`
- `Firebase initialization error` → Check JSON format in `.env`

#### 4. Check Backend Notification Sending

**When order is placed, check backend logs for:**
```
Sending notification to admin...
```

**Check `sendNotificationToRole` function:**
- Should find admin users
- Should have FCM tokens
- Should send notifications

#### 5. Test Notification Flow

1. **Verify admin has FCM token in database**
2. **Place test order from customer app**
3. **Check backend logs for notification sending**
4. **Check for FCM errors in backend logs**

### Common Issues

#### Issue 1: FCM Token Not Generated
**Symptoms:** No FCM token in debug console
**Fix:**
- Ensure notification permission is granted
- Check Firebase is initialized
- Restart app

#### Issue 2: FCM Token Not Sent to Backend
**Symptoms:** FCM token in console but not in database
**Fix:**
- Check API call to `/auth/profile` succeeds
- Check backend logs for errors
- Verify token is sent after login

#### Issue 3: Backend Not Sending Notifications
**Symptoms:** Order created but no notification
**Fix:**
- Check Firebase Admin is initialized
- Check admin user has FCM token
- Check backend logs for FCM errors
- Verify `FIREBASE_SERVICE_ACCOUNT` in `.env`

#### Issue 4: Notification Permission Denied
**Symptoms:** Permission status shows denied
**Fix:**
- Go to device settings
- Enable notifications for Easy Basket app
- Restart app

### Quick Test Commands

**Check admin FCM token:**
```bash
# In backend directory
mysql -u root -p easy_basket -e "SELECT id, phoneNumber, role, fcmToken IS NOT NULL as has_token FROM user WHERE role='admin';"
```

**Check backend FCM initialization:**
```bash
# Look for this in backend logs
grep -i "firebase" backend_logs.txt
```

**Test notification from backend:**
```bash
# Use Firebase Console to send test notification to admin's FCM token
```

