# High Availability & Zero-Downtime Deployment Guide

## Problem Statement

Currently, you have a **single backend server**. When you deploy or restart:
- ❌ All production requests fail during deployment
- ❌ Users experience downtime
- ❌ Orders can't be placed
- ❌ Admin can't access dashboard

## Solution: Multiple Backend Instances

You need **at least 2 backend servers** running in parallel with a **load balancer** to:
- ✅ Handle traffic even when one server is down
- ✅ Deploy without downtime
- ✅ Scale horizontally as traffic grows
- ✅ Better fault tolerance

---

## Architecture Options

### Option 1: PM2 Cluster Mode (Easiest - Recommended for Start)

**What it does:**
- Runs multiple instances of your Node.js app on the same server
- PM2 automatically load balances between instances
- Zero-downtime restarts

**Pros:**
- ✅ Easy to set up (no infrastructure changes)
- ✅ Works with your current single server
- ✅ PM2 handles load balancing
- ✅ Zero-downtime restarts with `pm2 reload`

**Cons:**
- ❌ Still single point of failure (if server goes down)
- ❌ Limited by single server resources

**Best for:** Starting out, small to medium traffic

### Option 2: Multiple EC2 Instances + Load Balancer (Production Ready)

**What it does:**
- 2+ EC2 instances, each running your backend
- Application Load Balancer (ALB) distributes traffic
- Health checks ensure only healthy instances receive traffic

**Pros:**
- ✅ True high availability
- ✅ Can handle server failures
- ✅ Better scalability
- ✅ Geographic distribution possible

**Cons:**
- ❌ More complex setup
- ❌ Higher AWS costs
- ❌ Need to manage multiple servers

**Best for:** Production with high traffic, critical uptime requirements

### Option 3: Blue-Green Deployment (Advanced)

**What it does:**
- Two identical environments (blue = current, green = new)
- Switch traffic from blue to green after deployment
- Instant rollback if issues occur

**Pros:**
- ✅ Zero-downtime deployments
- ✅ Easy rollback
- ✅ Test new version before switching

**Cons:**
- ❌ Requires duplicate infrastructure
- ❌ More complex deployment process

**Best for:** Large-scale applications, critical deployments

---

## Recommended: PM2 Cluster Mode (Start Here)

### Step 1: Update PM2 Configuration

Create `ecosystem.config.js` in your backend directory:

```javascript
module.exports = {
  apps: [{
    name: 'easy-basket-api',
    script: 'dist/index.js',
    instances: 'max', // Use all CPU cores, or specify number like 2, 4
    exec_mode: 'cluster', // Enable cluster mode
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    // Auto-restart settings
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    // Logging
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    // Zero-downtime reload
    kill_timeout: 5000,
    wait_ready: true,
    listen_timeout: 10000
  }]
};
```

### Step 2: Update Nginx Configuration

Your Nginx already acts as a reverse proxy. Update it to handle multiple backend instances:

```nginx
upstream backend_servers {
    # PM2 cluster mode - all instances on same port
    # Nginx will load balance between them
    least_conn; # Use least connections algorithm
    
    server 127.0.0.1:3000 max_fails=3 fail_timeout=30s;
    # If you add more servers later:
    # server 127.0.0.1:3001 max_fails=3 fail_timeout=30s;
    # server 127.0.0.1:3002 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name api.easybasket.in;

    location / {
        proxy_pass http://backend_servers;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Health check
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }
}
```

### Step 3: Deploy with PM2 Cluster

```bash
# Build your TypeScript
cd ~/easy-basket/backend
npm run build

# Start with cluster mode
pm2 start ecosystem.config.js

# Or if already running, reload (zero-downtime)
pm2 reload ecosystem.config.js

# Check status
pm2 status
pm2 logs easy-basket-api
```

### Step 4: Zero-Downtime Deployment Process

```bash
# 1. Pull latest code
cd ~/easy-basket/backend
git pull origin main

# 2. Install dependencies (if needed)
npm install

# 3. Build
npm run build

# 4. Reload with zero downtime (PM2 will restart instances one by one)
pm2 reload ecosystem.config.js

# 5. Verify
pm2 status
curl http://localhost:3000/api/health
```

---

## Advanced: Multiple EC2 Instances + ALB

### Architecture

```
Internet
   ↓
Application Load Balancer (ALB)
   ↓
   ├── EC2 Instance 1 (Backend)
   ├── EC2 Instance 2 (Backend)
   └── EC2 Instance 3 (Backend - optional)
```

### Step 1: Create Application Load Balancer

1. Go to AWS Console → EC2 → Load Balancers
2. Create Application Load Balancer
3. Configure:
   - Name: `easy-basket-alb`
   - Scheme: Internet-facing
   - IP address type: IPv4
   - VPC: Your VPC
   - Availability Zones: Select 2+ AZs
   - Security Group: Allow HTTP (80) and HTTPS (443) from 0.0.0.0/0

### Step 2: Create Target Group

1. Create Target Group
2. Configure:
   - Name: `easy-basket-backend`
   - Target type: Instances
   - Protocol: HTTP
   - Port: 3000
   - Health check path: `/api/health`
   - Health check interval: 30 seconds

### Step 3: Launch Multiple EC2 Instances

1. Launch 2+ EC2 instances (same configuration as current)
2. Install Node.js, PM2, Nginx on each
3. Deploy your backend code to each instance
4. Register instances with Target Group

### Step 4: Update DNS

Point your domain to the ALB:
- `api.easybasket.in` → ALB DNS name

### Step 5: Deployment Process

```bash
# Deploy to Instance 1
ssh instance1
cd ~/easy-basket/backend
git pull && npm install && npm run build
pm2 reload easy-basket-api

# Wait for health check to pass, then deploy to Instance 2
ssh instance2
cd ~/easy-basket/backend
git pull && npm install && npm run build
pm2 reload easy-basket-api

# ALB automatically routes traffic to healthy instances
```

---

## Comparison

| Feature | PM2 Cluster (Single Server) | Multiple EC2 + ALB |
|---------|----------------------------|-------------------|
| **Setup Complexity** | Easy ⭐ | Complex ⭐⭐⭐ |
| **Cost** | Low (1 server) | Higher (2+ servers + ALB) |
| **Uptime** | Good (handles app crashes) | Excellent (handles server failures) |
| **Scalability** | Limited by server | High (add more instances) |
| **Zero-Downtime Deploy** | Yes (with `pm2 reload`) | Yes (rolling deployment) |
| **Best For** | Starting out, small-medium traffic | Production, high traffic |

---

## Recommended Approach

### Phase 1: Start with PM2 Cluster (Now)
- ✅ Quick to implement
- ✅ Zero-downtime deployments
- ✅ Better than single instance
- ✅ No additional AWS costs

### Phase 2: Move to Multiple EC2 + ALB (When Needed)
- When traffic grows significantly
- When you need true high availability
- When single server becomes a bottleneck

---

## Quick Start: PM2 Cluster Mode

1. **Create ecosystem.config.js** (see above)
2. **Update Nginx** (see above)
3. **Deploy:**
   ```bash
   pm2 delete easy-basket-api  # Remove old single instance
   pm2 start ecosystem.config.js
   ```
4. **Test:**
   ```bash
   pm2 status  # Should show multiple instances
   curl http://localhost:3000/api/health
   ```

---

## Monitoring

```bash
# Check all instances
pm2 status

# View logs from all instances
pm2 logs easy-basket-api

# Monitor resources
pm2 monit

# Check individual instance
pm2 show easy-basket-api
```

---

## Next Steps

1. **Implement PM2 Cluster Mode** (recommended first step)
2. **Test zero-downtime deployment**
3. **Monitor performance**
4. **Plan migration to multiple EC2 instances** when needed

