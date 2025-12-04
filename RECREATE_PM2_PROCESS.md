# 🔄 Recreate PM2 Process: easy-basket-api

Step-by-step guide to recreate the PM2 process after deletion.

---

## 📋 Prerequisites

Make sure you're on EC2 and in the backend directory:

```bash
cd ~/easy-basket/backend
```

---

## 🔧 Step 1: Build the Backend

```bash
# Make sure you're in the backend directory
cd ~/easy-basket/backend

# Install dependencies (if needed)
npm install

# Build TypeScript to JavaScript
npm run build
```

**Wait for:** `Build completed successfully` or similar message

---

## 🚀 Step 2: Start with PM2

```bash
# Start the backend with PM2
pm2 start dist/index.js --name easy-basket-api

# Save PM2 configuration (so it persists after reboot)
pm2 save
```

---

## ✅ Step 3: Verify It's Running

```bash
# Check PM2 status
pm2 status

# Should show:
# ┌─────┬──────────────────┬─────────┬─────────┬──────────┬─────────┐
# │ id  │ name             │ status  │ restart │ uptime   │ memory  │
# ├─────┼──────────────────┼─────────┼─────────┼──────────┼─────────┤
# │ 0   │ easy-basket-api  │ online  │ 0       │ 5s       │ 45.2mb  │
# └─────┴──────────────────┴─────────┴─────────┴──────────┴─────────┘

# Check logs
pm2 logs easy-basket-api --lines 30
```

**Should see:**
- `Database connected`
- `Server is running on port 3000`

---

## 🧪 Step 4: Test the Backend

```bash
# Test root endpoint
curl http://localhost:3000/

# Should show: "Easy Basket Backend is running"

# Test health endpoint
curl http://localhost:3000/api/health

# Should show JSON:
# {
#   "status": "ok",
#   "message": "Easy Basket Backend is running",
#   "timestamp": "..."
# }
```

---

## 🔧 Step 5: Configure PM2 for Auto-Restart

```bash
# Enable PM2 to start on system boot
pm2 startup

# This will show a command like:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user

# Copy and run that command (it will be different for your system)
# Then save the current PM2 list
pm2 save
```

---

## 📋 Complete Command Sequence

```bash
# All commands in one go:
cd ~/easy-basket/backend && \
npm install && \
npm run build && \
pm2 start dist/index.js --name easy-basket-api && \
pm2 save && \
pm2 logs easy-basket-api --lines 20
```

---

## 🎯 Advanced: PM2 with Environment Variables

If you need to pass environment variables:

```bash
# Option 1: Use .env file (recommended)
# Make sure .env file exists in backend directory
cd ~/easy-basket/backend
pm2 start dist/index.js --name easy-basket-api --env production

# Option 2: Pass env variables directly
pm2 start dist/index.js --name easy-basket-api \
  --env NODE_ENV=production \
  --env PORT=3000
```

---

## 🔍 Troubleshooting

### Issue 1: "Cannot find module"

**Error:** `Error: Cannot find module 'express'`

**Fix:**
```bash
cd ~/easy-basket/backend
npm install
npm run build
pm2 restart easy-basket-api
```

### Issue 2: "Port 3000 already in use"

**Error:** `EADDRINUSE: address already in use :::3000`

**Fix:**
```bash
# Find what's using port 3000
sudo lsof -i :3000

# Kill the process (replace <PID> with actual process ID)
sudo kill -9 <PID>

# Or kill all node processes
pkill -f node

# Then restart PM2
pm2 restart easy-basket-api
```

### Issue 3: Database Connection Error

**Error:** `Database connection error`

**Fix:**
- Check `.env` file: `cat ~/easy-basket/backend/.env`
- Verify database credentials
- Check RDS security group allows EC2 IP
- Test connection: `mysql -h <RDS_HOST> -u <DB_USER> -p`

### Issue 4: PM2 Process Keeps Crashing

**Check logs:**
```bash
pm2 logs easy-basket-api --err --lines 50
```

**Common causes:**
- Missing environment variables
- Database connection issues
- Port conflicts
- Missing dependencies

---

## 📊 Useful PM2 Commands

```bash
# View all processes
pm2 status

# View logs
pm2 logs easy-basket-api

# View logs (last 50 lines)
pm2 logs easy-basket-api --lines 50

# Restart process
pm2 restart easy-basket-api

# Stop process
pm2 stop easy-basket-api

# Delete process
pm2 delete easy-basket-api

# Monitor (real-time)
pm2 monit

# Show process details
pm2 show easy-basket-api
```

---

## ✅ Verification Checklist

- [ ] Backend built: `npm run build` completed
- [ ] PM2 process created: `pm2 status` shows `easy-basket-api`
- [ ] Process is online: Status shows `online`
- [ ] Logs show "Database connected"
- [ ] Logs show "Server is running on port 3000"
- [ ] Root endpoint works: `curl http://localhost:3000/`
- [ ] Health endpoint works: `curl http://localhost:3000/api/health`
- [ ] PM2 saved: `pm2 save` completed

---

## 🎯 Quick Start Command

```bash
cd ~/easy-basket/backend && npm run build && pm2 start dist/index.js --name easy-basket-api && pm2 save && pm2 logs easy-basket-api
```

This will:
1. Build the backend
2. Start with PM2
3. Save PM2 config
4. Show logs

---

**Your PM2 process will be recreated and running! 🚀**

