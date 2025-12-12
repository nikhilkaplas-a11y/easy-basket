# Debugging Auth Login Endpoint

## ✅ Backend Status
The backend endpoint `/api/auth/login` is **working correctly**:
- Returns HTTP 200
- Response: `{"message": "OTP sent successfully. Use 1234 for testing."}`
- CORS is enabled

## 🔍 Frontend Issues to Check

### 1. API URL Configuration
Check `mobile/lib/config/app_config.dart`:
- **Web**: `http://localhost:3000/api` ✅ (currently set)
- **Android Emulator**: Should be `http://10.0.2.2:3000/api`
- **Physical Device**: Should be `http://YOUR_MAC_IP:3000/api`

### 2. Common Errors

#### Error: "Cannot connect to server"
**Cause**: Wrong API URL or backend not running
**Fix**: 
- Check backend is running: `curl http://localhost:3000/api/health`
- Update `AppConfig.apiBaseUrl` for your platform

#### Error: "Network error: Connection refused"
**Cause**: Backend not accessible from frontend
**Fix**:
- Web: Use `http://localhost:3000/api`
- Android Emulator: Use `http://10.0.2.2:3000/api`
- Physical Device: Use your Mac's IP address

#### Error: "CORS error" (in browser console)
**Cause**: CORS not configured (but it should be)
**Fix**: Backend already has `app.use(cors())` - should work

### 3. Testing Steps

1. **Test Backend Directly**:
   ```bash
   curl -X POST http://localhost:3000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber":"9999999999"}'
   ```
   Should return: `{"message": "OTP sent successfully. Use 1234 for testing."}`

2. **Check Frontend Console**:
   - Open browser DevTools (F12)
   - Go to Network tab
   - Try to send OTP
   - Check the request URL and response

3. **Check Flutter Logs**:
   - Look for `✅ OTP sent successfully` or `❌ Error sending OTP`
   - Check the error message

### 4. Quick Fixes

#### If testing on Web:
- Make sure backend is running on `localhost:3000`
- Use `http://localhost:3000/api` in `AppConfig`

#### If testing on Android Emulator:
- Change `AppConfig.apiBaseUrl` to `http://10.0.2.2:3000/api`
- Restart the app

#### If testing on Physical Device:
- Find your Mac's IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
- Change `AppConfig.apiBaseUrl` to `http://YOUR_IP:3000/api`
- Make sure Mac and phone are on same WiFi
- Restart the app

### 5. Debug Information

The improved error handling now shows:
- More specific error messages
- Connection issues are clearly identified
- Debug logs in console (when `kDebugMode` is true)

## 📝 Next Steps

1. Check the error message shown in the app
2. Verify the API URL matches your platform
3. Check backend is running and accessible
4. Check browser/Flutter console for detailed errors

