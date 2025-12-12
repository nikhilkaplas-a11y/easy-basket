# Restart Backend with PM2 (Production)

## Quick Commands

### Check PM2 Status
```bash
pm2 list
```

### Restart Backend (Recommended)
```bash
# Restart the backend process (graceful restart)
pm2 restart easy-basket-api

# Or if using a different name, check with:
pm2 list
```

### Alternative: Reload (Zero Downtime)
```bash
# Reload with zero downtime (better for production)
pm2 reload easy-basket-api
```

### Full Restart (Stop + Start)
```bash
# Stop the process
pm2 stop easy-basket-api

# Start the process
pm2 start easy-basket-api
```

## Verify Firebase Initialization

After restarting, check the logs to verify Firebase is initialized:

```bash
# View logs
pm2 logs easy-basket-api --lines 50

# Look for:
# ✅ Firebase Admin initialized
```

## If Process Name is Different

If your PM2 process has a different name:

```bash
# List all PM2 processes
pm2 list

# Restart by ID
pm2 restart 0

# Or restart by name (whatever name you see in the list)
pm2 restart <process-name>
```

## Common PM2 Process Names

Based on your setup, it might be:
- `easy-basket-api`
- `backend`
- `easy-basket-backend`
- Or check with `pm2 list`

## Complete Restart Flow

```bash
# 1. Check current status
pm2 list

# 2. Restart backend
pm2 restart easy-basket-api

# 3. Check logs for Firebase initialization
pm2 logs easy-basket-api --lines 20

# 4. Verify it's running
pm2 status
```

## After Restart

1. **Check logs** for `✅ Firebase Admin initialized`
2. **Test notification** by placing an order
3. **Watch logs** for notification sending:
   ```
   📤 [ORDER] Sending notification to admin for order #[id]
   ✅ [FCM] Notification sent successfully
   ```

## Troubleshooting

### If restart doesn't work:
```bash
# Stop completely
pm2 stop easy-basket-api

# Delete from PM2
pm2 delete easy-basket-api

# Start fresh (adjust path and command as needed)
cd /path/to/backend
pm2 start npm --name "easy-basket-api" -- run start

# Or if using compiled version:
pm2 start dist/index.js --name "easy-basket-api"
```

### Check if .env file is being loaded:
```bash
# View environment variables
pm2 show easy-basket-api

# Check if FIREBASE_SERVICE_ACCOUNT is in the env
```

