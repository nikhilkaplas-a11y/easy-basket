# Fixing "Failed to fetch" Error on Web

## Issue
The Flutter web app shows: `Failed to fetch, uri=http://localhost:3000/api/auth/login`

## Root Causes

### 1. CORS (Cross-Origin Resource Sharing)
- Browser blocks requests from `http://localhost:XXXX` (Flutter web) to `http://localhost:3000` (backend)
- Need proper CORS headers

### 2. Backend Not Accessible
- Backend might not be running
- Port 3000 might be blocked

## Fixes Applied

### ✅ Backend CORS Configuration
Updated `backend/src/index.ts` with explicit CORS settings:
```typescript
app.use(cors({
  origin: true, // Allow all origins
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
```

### ✅ Better Error Messages
Frontend now shows clearer error messages for:
- Connection refused
- Failed to fetch
- Timeout errors

## Testing Steps

### 1. Verify Backend is Running
```bash
curl http://localhost:3000/api/health
```
Should return: `{"status":"ok",...}`

### 2. Test CORS from Browser
Open browser console and run:
```javascript
fetch('http://localhost:3000/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ phoneNumber: '9999999999' })
})
.then(r => r.json())
.then(console.log)
.catch(console.error)
```

### 3. Check Browser Console
- Open DevTools (F12)
- Go to Network tab
- Try to send OTP
- Check the request:
  - Status code
  - CORS headers
  - Error message

## Common Solutions

### Solution 1: Restart Backend
The CORS changes require backend restart:
```bash
cd backend
npm run build
# Then restart (Ctrl+C and npm run dev)
```

### Solution 2: Check Port
Make sure backend is on port 3000:
```bash
lsof -ti:3000
```

### Solution 3: Browser Cache
- Clear browser cache
- Try incognito/private mode
- Hard refresh (Ctrl+Shift+R)

### Solution 4: Use Different Port
If port 3000 is blocked, change backend port:
```bash
# In backend/.env
PORT=3001
```

Then update `AppConfig.apiBaseUrl` to match.

## Expected Behavior

After fixes:
- ✅ Backend accepts requests from any origin
- ✅ CORS headers are sent correctly
- ✅ Browser allows the request
- ✅ Login/verify endpoints work

## Debugging

If still not working:
1. Check backend terminal for errors
2. Check browser console for CORS errors
3. Check Network tab for request details
4. Verify backend is accessible: `curl http://localhost:3000/api/health`

