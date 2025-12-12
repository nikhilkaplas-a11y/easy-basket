# Quick High Availability Setup - PM2 Cluster Mode

## Problem
Single backend server = downtime during deployments

## Solution: PM2 Cluster Mode
Run multiple instances on the same server with automatic load balancing.

---

## Step 1: Create PM2 Ecosystem Config

Already created: `backend/ecosystem.config.js`

This will run multiple instances (one per CPU core) automatically.

---

## Step 2: Update Nginx for Load Balancing

**On your EC2 server:**

```bash
# Backup current config
sudo cp /etc/nginx/conf.d/easy-basket.conf /etc/nginx/conf.d/easy-basket.conf.backup

# Update with load balancing config
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Paste the config from `nginx-load-balancer.conf`** (or copy the file)

**Test and reload:**
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## Step 3: Deploy with PM2 Cluster

```bash
# On your EC2 server
cd ~/easy-basket/backend

# Build
npm run build

# Stop old single instance
pm2 delete easy-basket-api

# Start with cluster mode
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
# Follow the command it outputs
```

---

## Step 4: Verify

```bash
# Check status - should show multiple instances
pm2 status

# Example output:
# ┌─────┬──────────────────┬─────────┬─────────┬──────────┐
# │ id  │ name             │ mode    │ ↺       │ status   │
# ├─────┼──────────────────┼─────────┼─────────┼──────────┤
# │ 0   │ easy-basket-api  │ cluster │ 0       │ online   │
# │ 1   │ easy-basket-api  │ cluster │ 0       │ online   │
# │ 2   │ easy-basket-api  │ cluster │ 0       │ online   │
# │ 3   │ easy-basket-api  │ cluster │ 0       │ online   │
# └─────┴──────────────────┴─────────┴─────────┴──────────┘

# Test API
curl http://localhost:3000/api/health
curl http://api.easybasket.in/api/health
```

---

## Step 5: Zero-Downtime Deployment

Now you can deploy without breaking production:

```bash
cd ~/easy-basket/backend

# Pull latest code
git pull origin main

# Install dependencies (if needed)
npm install

# Build
npm run build

# Reload with zero downtime (PM2 restarts instances one by one)
pm2 reload ecosystem.config.js

# Verify
pm2 status
pm2 logs easy-basket-api --lines 20
```

**What happens:**
1. PM2 starts new instance with new code
2. Waits for it to be ready
3. Stops old instance
4. Repeats for each instance
5. **No downtime!** ✅

---

## Benefits

✅ **Zero-downtime deployments** - `pm2 reload` restarts instances one by one
✅ **Better performance** - Multiple instances handle more requests
✅ **Automatic load balancing** - PM2 distributes requests
✅ **Fault tolerance** - If one instance crashes, others keep running
✅ **No infrastructure changes** - Works on your current single server

---

## Monitoring

```bash
# View all instances
pm2 status

# View logs from all instances
pm2 logs easy-basket-api

# Monitor resources
pm2 monit

# View detailed info
pm2 show easy-basket-api
```

---

## Next Steps (When You Scale)

When you need even more availability:
1. **Add more EC2 instances** (2-3 servers)
2. **Set up Application Load Balancer (ALB)**
3. **Deploy backend to each instance**
4. **ALB distributes traffic across all servers**

See `HIGH_AVAILABILITY_SETUP.md` for detailed guide.

---

## Quick Commands Reference

```bash
# Start cluster
pm2 start ecosystem.config.js

# Reload (zero downtime)
pm2 reload ecosystem.config.js

# Restart (brief downtime)
pm2 restart ecosystem.config.js

# Stop
pm2 stop ecosystem.config.js

# Delete
pm2 delete ecosystem.config.js

# View status
pm2 status

# View logs
pm2 logs easy-basket-api
```

