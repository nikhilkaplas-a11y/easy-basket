# Testing Auth Verify Endpoint

## Quick Test Commands

### 1. Test Backend Directly (should work)
```bash
curl -X POST http://localhost:3000/api/auth/verify \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"9999999999","otp":"1234"}'
```

### 2. Check Backend Logs
The backend should show detailed error logs if something fails.

### 3. Common Issues

#### Issue: CORS Error
- **Symptom**: Browser console shows CORS error
- **Fix**: Backend already has `cors()` middleware, but check if it's working

#### Issue: Network Error
- **Symptom**: "Network error" in Flutter
- **Fix**: Check `AppConfig.apiBaseUrl` matches your backend URL
  - Web: `http://localhost:3000/api`
  - Android Emulator: `http://10.0.2.2:3000/api`
  - Physical Device: `http://YOUR_MAC_IP:3000/api`

#### Issue: 500 Internal Server Error
- **Symptom**: Backend returns 500 error
- **Fix**: Check backend logs for database connection or entity issues
- **Common causes**:
  - Database not connected
  - RefreshToken table doesn't exist
  - Missing environment variables

### 4. Frontend Debugging

Check browser console (web) or Flutter logs for:
- Network request URL
- Response status code
- Response body
- Error messages

### 5. Backend Debugging

Check backend terminal for:
- Database connection status
- Error stack traces
- Request/response logs

