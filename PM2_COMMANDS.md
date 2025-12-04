# 🔄 PM2 Commands for Easy Basket Backend

Quick reference for managing your backend with PM2.

---

## 📊 Check Status

```bash
# View all PM2 processes
pm2 status

# View detailed info
pm2 show easy-basket-api

# View process list
pm2 list
```

---

## 🔄 Restart After Code Changes

### Quick Restart (Recommended)
```bash
pm2 restart easy-basket-api
```

### Reload (Zero Downtime - Better for Production)
```bash
pm2 reload easy-basket-api
```

### Full Restart Process (After Code Changes)
```bash
cd ~/easy-basket/backend

# Rebuild TypeScript
npm run build

# Restart PM2
pm2 restart easy-basket-api

# Check if it's running
pm2 status
```

---

## 📋 View Logs

```bash
# View live logs (follow mode)
pm2 logs easy-basket-api

# View last 50 lines
pm2 logs easy-basket-api --lines 50

# View last 100 lines
pm2 logs easy-basket-api --lines 100

# View logs without following
pm2 logs easy-basket-api --lines 20 --nostream

# Clear logs
pm2 flush easy-basket-api
```

---

## 🛑 Stop/Start

```bash
# Stop application
pm2 stop easy-basket-api

# Start application
pm2 start easy-basket-api

# Delete from PM2 (but keep process)
pm2 delete easy-basket-api
```

---

## 🔧 After Code Changes Workflow

```bash
# 1. Navigate to backend
cd ~/easy-basket/backend

# 2. Pull latest code (if using Git)
git pull

# 3. Install new dependencies (if any)
npm install

# 4. Rebuild TypeScript
npm run build

# 5. Restart PM2
pm2 restart easy-basket-api

# 6. Check logs for errors
pm2 logs easy-basket-api --lines 30

# 7. Verify it's running
pm2 status
```

---

## 🐛 Troubleshooting

### Application Not Starting

```bash
# Check logs for errors
pm2 logs easy-basket-api --lines 50

# Check if port is in use
sudo lsof -i :3000

# Kill process on port 3000 (if needed)
sudo kill -9 $(sudo lsof -t -i:3000)

# Restart PM2
pm2 restart easy-basket-api
```

### Application Crashed

```bash
# View error logs
pm2 logs easy-basket-api --err

# Check status
pm2 status

# Restart
pm2 restart easy-basket-api
```

### Clear All Logs

```bash
pm2 flush
```

---

## ⚙️ PM2 Configuration

### Save Current Process List
```bash
pm2 save
```

### Setup PM2 to Start on Boot
```bash
pm2 startup
# Follow the command it outputs (usually sudo command)
pm2 save
```

### Update Environment Variables

Edit `.env` file, then:
```bash
pm2 restart easy-basket-api
```

---

## 📊 Monitoring

```bash
# Real-time monitoring
pm2 monit

# View process info
pm2 describe easy-basket-api

# View memory/CPU usage
pm2 list
```

---

## 🔄 Quick Reference

| Command | Description |
|---------|-------------|
| `pm2 status` | View all processes |
| `pm2 restart easy-basket-api` | Restart application |
| `pm2 reload easy-basket-api` | Reload (zero downtime) |
| `pm2 logs easy-basket-api` | View logs |
| `pm2 stop easy-basket-api` | Stop application |
| `pm2 start easy-basket-api` | Start application |
| `pm2 delete easy-basket-api` | Remove from PM2 |

---

## ✅ After Code Changes - Quick Steps

```bash
cd ~/easy-basket/backend
npm run build
pm2 restart easy-basket-api
pm2 logs easy-basket-api --lines 20
```

---

**Your backend is now restarted! 🚀**

