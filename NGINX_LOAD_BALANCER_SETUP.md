# Nginx Load Balancer Setup - End to End Steps

## Current Setup
- ✅ SSL/HTTPS configured with Certbot
- ✅ HTTP to HTTPS redirect working
- ❌ Single backend instance (no load balancing)

## Goal
- ✅ Add load balancing for PM2 cluster mode
- ✅ Keep SSL/HTTPS intact
- ✅ Zero-downtime deployments
- ✅ Better performance and reliability

---

## Step 1: Backup Current Nginx Config

**On your EC2 server:**

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ec2-user@your-ec2-ip

# Backup current config
sudo cp /etc/nginx/conf.d/easy-basket.conf /etc/nginx/conf.d/easy-basket.conf.backup.$(date +%Y%m%d)

# Or if using sites-available/sites-enabled:
sudo cp /etc/nginx/sites-available/easy-basket /etc/nginx/sites-available/easy-basket.backup.$(date +%Y%m%d)

# View current config location
sudo nginx -T 2>/dev/null | grep -A 5 "server_name api.easybasket.in"
```

---

## Step 2: Update Nginx Configuration

### Option A: If using `/etc/nginx/conf.d/easy-basket.conf`

```bash
# Edit the config file
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Replace entire content with the config from `nginx-production-load-balancer.conf`**

### Option B: If using `/etc/nginx/sites-available/` or main config

```bash
# Find where your config is
sudo find /etc/nginx -name "*easy-basket*" -o -name "*api.easybasket*"

# Edit the file
sudo nano /path/to/your/config/file
```

**Replace the server blocks with the config from `nginx-production-load-balancer.conf`**

---

## Step 3: Test Nginx Configuration

```bash
# Test configuration syntax
sudo nginx -t

# Expected output:
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**If you see errors:**
- Check for typos in the config
- Verify SSL certificate paths are correct
- Check file permissions

---

## Step 4: Reload Nginx

```bash
# Reload Nginx (no downtime)
sudo systemctl reload nginx

# Or restart if reload doesn't work
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

---

## Step 5: Setup PM2 Cluster Mode

```bash
# Navigate to backend directory
cd ~/easy-basket/backend

# Build TypeScript
npm run build

# Stop old single instance (if running)
pm2 delete easy-basket-api 2>/dev/null || true

# Start with cluster mode using ecosystem.config.js
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot (if not already done)
pm2 startup
# Follow the command it outputs (usually: sudo env PATH=... pm2 startup systemd -u ec2-user --hp /home/ec2-user)
```

---

## Step 6: Verify Setup

### Check PM2 Status

```bash
pm2 status

# Should show multiple instances:
# ┌─────┬──────────────────┬─────────┬─────────┬──────────┐
# │ id  │ name             │ mode    │ ↺       │ status   │
# ├─────┼──────────────────┼─────────┼─────────┼──────────┤
# │ 0   │ easy-basket-api  │ cluster │ 0       │ online   │
# │ 1   │ easy-basket-api  │ cluster │ 0       │ online   │
# │ 2   │ easy-basket-api  │ cluster │ 0       │ online   │
# │ 3   │ easy-basket-api  │ cluster │ 0       │ online   │
# └─────┴──────────────────┴─────────┴─────────┴──────────┘
```

### Test API Endpoints

```bash
# Test localhost
curl http://localhost:3000/api/health

# Test via Nginx (HTTP - should redirect to HTTPS)
curl -I http://api.easybasket.in/api/health

# Test via Nginx (HTTPS)
curl https://api.easybasket.in/api/health

# Test from your local machine
curl https://api.easybasket.in/api/health
```

### Check Nginx Logs

```bash
# View access logs
sudo tail -f /var/log/nginx/easy-basket-access.log

# View error logs
sudo tail -f /var/log/nginx/easy-basket-error.log
```

---

## Step 7: Test Load Balancing

```bash
# Make multiple requests and check which backend instance handles them
# PM2 will automatically distribute requests

for i in {1..10}; do
  curl -s http://localhost:3000/api/health | head -1
  sleep 0.5
done

# All requests should succeed (load balancing is working)
```

---

## Step 8: Test Zero-Downtime Deployment

```bash
# Simulate a deployment
cd ~/easy-basket/backend

# Make a small change (or pull latest code)
git pull origin main

# Build
npm run build

# Reload with zero downtime
pm2 reload ecosystem.config.js

# While reloading, test API (should still work!)
# In another terminal:
while true; do
  curl -s https://api.easybasket.in/api/health && echo " ✅"
  sleep 1
done

# You should see continuous success even during reload
```

---

## Configuration Details

### Upstream Backend Servers

```nginx
upstream backend_servers {
    least_conn;  # Distribute to instance with least connections
    server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;  # Keep connections alive
}
```

**What this does:**
- `least_conn` - Better than round-robin, sends requests to least busy instance
- `max_fails=3` - Mark instance as down after 3 failed health checks
- `fail_timeout=30s` - Retry after 30 seconds if instance was marked down
- `keepalive 32` - Reuse connections for better performance

### Health Check & Failover

```nginx
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
proxy_next_upstream_tries 3;
```

**What this does:**
- If one instance fails, automatically try another
- Retry up to 3 times
- Handles errors, timeouts, and HTTP 5xx errors

---

## Troubleshooting

### Issue 1: Nginx Config Test Fails

```bash
# Check syntax
sudo nginx -t

# View detailed error
sudo nginx -T 2>&1 | grep -i error

# Common issues:
# - Missing semicolons
# - Incorrect file paths
# - SSL certificate paths wrong
```

### Issue 2: PM2 Not Starting Multiple Instances

```bash
# Check ecosystem.config.js exists
ls -la ~/easy-basket/backend/ecosystem.config.js

# Check PM2 logs
pm2 logs easy-basket-api --lines 50

# Manually check instances
pm2 status
```

### Issue 3: 502 Bad Gateway

```bash
# Check if backend is running
pm2 status

# Check backend logs
pm2 logs easy-basket-api --lines 50

# Test backend directly
curl http://localhost:3000/api/health

# Check Nginx error logs
sudo tail -50 /var/log/nginx/easy-basket-error.log
```

### Issue 4: SSL Certificate Issues

```bash
# Verify certificates exist
sudo ls -la /etc/letsencrypt/live/api.easybasket.in/

# Test SSL
openssl s_client -connect api.easybasket.in:443 -servername api.easybasket.in

# Renew if needed (Certbot)
sudo certbot renew --dry-run
```

---

## Monitoring

### Check PM2 Status

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

### Check Nginx Status

```bash
# View Nginx status
sudo systemctl status nginx

# View active connections
sudo netstat -tulpn | grep nginx

# View Nginx processes
ps aux | grep nginx
```

### Monitor Load Balancing

```bash
# Watch Nginx access logs
sudo tail -f /var/log/nginx/easy-basket-access.log

# Count requests per backend (should be distributed)
sudo tail -100 /var/log/nginx/easy-basket-access.log | grep "GET /api" | wc -l
```

---

## Quick Reference Commands

```bash
# Nginx
sudo nginx -t                    # Test config
sudo systemctl reload nginx      # Reload (no downtime)
sudo systemctl restart nginx     # Restart
sudo systemctl status nginx      # Check status

# PM2
pm2 start ecosystem.config.js    # Start cluster
pm2 reload ecosystem.config.js   # Reload (zero downtime)
pm2 restart ecosystem.config.js  # Restart
pm2 status                       # Check status
pm2 logs easy-basket-api         # View logs
pm2 monit                        # Monitor resources

# Testing
curl http://localhost:3000/api/health
curl https://api.easybasket.in/api/health
```

---

## Next Steps

1. ✅ **Test the setup** - Verify load balancing works
2. ✅ **Monitor performance** - Check if multiple instances improve response times
3. ✅ **Test zero-downtime deployment** - Deploy and verify no downtime
4. 📋 **Plan for multiple EC2 instances** - When you need even more availability

---

## Summary

✅ **Nginx updated** with load balancing
✅ **PM2 cluster mode** running multiple instances
✅ **SSL/HTTPS** preserved
✅ **Zero-downtime deployments** enabled
✅ **Better performance** and reliability

Your backend is now production-ready with high availability! 🚀

