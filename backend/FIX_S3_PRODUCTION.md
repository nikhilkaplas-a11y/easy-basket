# Fix S3 Configuration in Production

## Problem
AWS S3 credentials are configured in `.env` file but PM2 isn't loading them.

## Quick Fix

### Option 1: Update PM2 Config (Recommended)

The `ecosystem.config.js` has been updated to load `.env` variables. On your production server:

```bash
cd ~/easy-basket/backend

# Rebuild the backend
npm run build

# Restart PM2 with updated config
pm2 delete easy-basket-api
pm2 start ecosystem.config.js
pm2 save
```

### Option 2: Add Env Vars Directly to PM2

If Option 1 doesn't work, add env vars directly to PM2:

```bash
cd ~/easy-basket/backend

# Stop current PM2 process
pm2 delete easy-basket-api

# Start with env vars from .env file
pm2 start dist/index.js --name easy-basket-api \
  --env production \
  --update-env \
  --instances max \
  --exec-mode cluster

# Or manually specify env vars:
pm2 start dist/index.js --name easy-basket-api \
  --update-env \
  --instances max \
  --exec-mode cluster \
  --env AWS_ACCESS_KEY_ID="your_key" \
  --env AWS_SECRET_ACCESS_KEY="your_secret" \
  --env AWS_S3_BUCKET_NAME="your-bucket" \
  --env AWS_REGION="ap-south-1"

pm2 save
```

### Option 3: Use PM2 Ecosystem with Env File

Edit `ecosystem.config.js` and add:

```javascript
require('dotenv').config({ path: './.env' });

module.exports = {
  apps: [{
    name: 'easy-basket-api',
    script: 'dist/index.js',
    // ... rest of config
    env_file: './.env', // Explicitly specify .env file
    // ... rest
  }]
};
```

Then restart:
```bash
pm2 delete easy-basket-api
pm2 start ecosystem.config.js
pm2 save
```

## Verify It's Working

After restarting, check the logs:

```bash
pm2 logs easy-basket-api --lines 50
```

You should see:
```
✅ AWS S3 credentials configured
📦 S3 Bucket: your-bucket-name
🌍 S3 Region: eu-north-1
✅ AWS S3 client initialized
```

If you still see "⚠️ AWS S3 not configured", check:

1. **Verify .env file exists and has correct values:**
   ```bash
   cd ~/easy-basket/backend
   cat .env | grep AWS
   ```

2. **Check .env file location:**
   - Should be in `~/easy-basket/backend/.env`
   - PM2 runs from `backend` directory

3. **Verify file permissions:**
   ```bash
   ls -la ~/easy-basket/backend/.env
   ```

4. **Test loading .env manually:**
   ```bash
   cd ~/easy-basket/backend
   node -e "require('dotenv').config(); console.log('AWS_ACCESS_KEY_ID:', process.env.AWS_ACCESS_KEY_ID ? 'Set' : 'Missing');"
   ```

## Alternative: Use System Environment Variables

If .env file isn't working, set system environment variables:

```bash
# Add to ~/.bashrc or ~/.profile
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
export AWS_S3_BUCKET_NAME="your-bucket"
export AWS_REGION="eu-north-1"

# Reload
source ~/.bashrc

# Restart PM2
pm2 restart easy-basket-api
```

## Debugging

The updated code now shows which env vars are missing:

```bash
pm2 logs easy-basket-api
```

Look for:
```
🔍 Checking AWS S3 configuration...
   AWS_ACCESS_KEY_ID: ✅ Set / ❌ Missing
   AWS_SECRET_ACCESS_KEY: ✅ Set / ❌ Missing
   AWS_S3_BUCKET_NAME: ✅ Set (bucket-name) / ❌ Missing
```

This will help identify which variable is missing.

