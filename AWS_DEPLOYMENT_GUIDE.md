# 🚀 AWS Deployment Guide for Easy Basket

Complete step-by-step guide to deploy Easy Basket backend on AWS.

---

## 📋 Prerequisites

- AWS Account (create at https://aws.amazon.com)
- AWS CLI installed (`aws --version`)
- Node.js installed locally
- MySQL client (optional, for database access)
- Domain name (optional, for custom domain)

---

## 🗄️ Step 1: Set Up RDS MySQL Database

### 1.1 Create RDS Instance

1. **Go to AWS Console** → RDS → Databases → Create database

2. **Database Configuration:**
   - **Engine:** MySQL
   - **Version:** MySQL 8.0 (or latest)
   - **Template:** Free tier (or Production based on needs)
   - **DB Instance Identifier:** `easy-basket-db`
   - **Master Username:** `admin` (or your choice)
   - **Master Password:** Create strong password (save it!)
   - **DB Instance Class:** `db.t3.micro` (free tier) or `db.t3.small` (production)
   - **Password nikhilkaplas

3. **Storage:**
   - **Storage Type:** General Purpose SSD (gp3)
   - **Allocated Storage:** 20 GB (minimum)

4. **Connectivity:**
   - **VPC:** Default VPC (or create new)
   - **Public Access:** Yes (for initial setup, can change later)
   - **VPC Security Group:** Create new or use existing
   - **Availability Zone:** Choose closest to you
   - **Database Port:** 3306

5. **Database Authentication:**
   - **Password authentication**

6. **Additional Configuration:**
   - **Initial Database Name:** `easybasket` (optional)
   - **Backup Retention:** 7 days (production)
   - **Enable Encryption:** Yes (recommended)

7. Click **Create database** (takes 5-10 minutes)

### 1.2 Configure Security Group

1. Go to **RDS** → Your database → **Connectivity & security** → **VPC security groups**

2. Click on the security group

3. **Inbound Rules** → **Edit inbound rules** → **Add rule:**
   - **Type:** MySQL/Aurora
   - **Port:** 3306
   - **Source:** Your IP address (for initial setup)
   - Or: `0.0.0.0/0` (for public access - less secure, use only for testing)

4. **Save rules**

### 1.3 Get Database Endpoint

1. Go to your RDS database
2. Copy the **Endpoint** (e.g., `easy-basket-db.xxxxx.us-east-1.rds.amazonaws.com`)
3. Save: **Endpoint**, **Port** (3306), **Username**, **Password**

---

## ☁️ Step 2: Deploy Backend to EC2

### 2.1 Create EC2 Instance

1. **Go to AWS Console** → EC2 → Instances → Launch instance

2. **Name:** `easy-basket-backend`

3. **Application and OS Images:**
   - **Amazon Linux 2023** (or Ubuntu 22.04 LTS)

4. **Instance Type:**
   - **t2.micro** (free tier) or **t3.small** (production)

5. **Key Pair:**
   - Create new key pair or use existing
   - **Name:** `easy-basket-key`
   - **Key pair type:** RSA
   - **Private key file format:** `.pem`
   - **Download** and save the `.pem` file securely

6. **Network Settings:**
   - **VPC:** Default VPC
   - **Subnet:** Any public subnet
   - **Auto-assign Public IP:** Enable
   - **Security Group:** Create new security group
     - **Name:** `easy-basket-backend-sg`
     - **Inbound Rules:**
       - **SSH (22):** Your IP
       - **HTTP (80):** 0.0.0.0/0
       - **HTTPS (443):** 0.0.0.0/0
       - **Custom TCP (3000):** 0.0.0.0/0 (for Node.js app)

7. **Configure Storage:**
   - **8 GB** (free tier) or **20 GB** (production)

8. **Launch Instance**

### 2.2 Connect to EC2 Instance

1. **Get Public IP:**
   - Go to EC2 → Instances → Select your instance
   - Copy **Public IPv4 address**

2. **Connect via SSH:**
   ```bash
   # On Mac/Linux
   chmod 400 easy-basket-key.pem
   ssh -i easy-basket-key.pem ec2-user@YOUR_PUBLIC_IP
   
   # On Windows (use Git Bash or WSL)
   ssh -i easy-basket-key.pem ec2-user@YOUR_PUBLIC_IP
   ```

3. **If using Ubuntu:**
   ```bash
   ssh -i easy-basket-key.pem ubuntu@YOUR_PUBLIC_IP
   ```

### 2.3 Install Dependencies on EC2

```bash
# Update system
sudo yum update -y  # For Amazon Linux
# OR
sudo apt update && sudo apt upgrade -y  # For Ubuntu

# Install Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs  # For Amazon Linux
# OR
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs  # For Ubuntu

# Install Git
sudo yum install -y git  # For Amazon Linux
# OR
sudo apt install -y git  # For Ubuntu

# Install PM2 (Process Manager)
sudo npm install -g pm2

# Install MySQL Client (optional, for testing)
sudo yum install -y mysql  # For Amazon Linux
# OR
sudo apt install -y mysql-client  # For Ubuntu

# Verify installations
node --version
npm --version
pm2 --version
```

### 2.4 Clone and Setup Backend

```bash
# Create app directory
mkdir -p ~/easy-basket
cd ~/easy-basket

# Clone your repository (or upload files)
# Option 1: If using Git (clone entire repo)
git clone https://github.com/nikhilkaplas-a11y/easy-basket.git .
# This creates: ~/easy-basket/backend/ and ~/easy-basket/mobile/

# Option 2: If not using Git, use SCP to upload entire project
# On your local machine:
# scp -i easy-basket-key.pem -r /Users/nikhil/Projects/easyBucket/* ec2-user@YOUR_PUBLIC_IP:~/easy-basket/

# Install dependencies
cd backend
npm install

# Build TypeScript
npm run build
```

### 2.5 Configure Environment Variables

```bash
# Create .env file
cd ~/easy-basket/backend
nano .env
```

**Add these variables:**
```env
# Server
PORT=3000
NODE_ENV=production

# Database (RDS)
DB_HOST=your-rds-endpoint.xxxxx.us-east-1.rds.amazonaws.com
DB_PORT=3306
DB_USERNAME=admin
DB_PASSWORD=your-database-password
DB_NAME=easybasket

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Razorpay (Production Keys)
RAZORPAY_KEY_ID=your-production-key-id
RAZORPAY_KEY_SECRET=your-production-key-secret

# OTP (for production, use real SMS service)
OTP_SERVICE_URL=your-otp-service-url
# OR keep test mode for now
NODE_ENV=production

# CORS (Your app domain)
CORS_ORIGIN=https://your-app-domain.com,http://localhost:3000
```

**Save and exit:** `Ctrl+X`, then `Y`, then `Enter`

### 2.6 Initialize Database:wq







```bash
# Test database connection
mysql -h your-rds-endpoint.xxxxx.us-east-1.rds.amazonaws.com -u admin -p

# Create database (if not created)
CREATE DATABASE IF NOT EXISTS easybasket;
USE easybasket;
EXIT;

# Run migrations (if you have them)
# npm run migrate

# Or let TypeORM create tables (only for first time)
# Make sure synchronize: true in database.ts for initial setup
# Then change to false after tables are created
```

### 2.7 Start Application with PM2

```bash
cd ~/easy-basket/backend

# Start application
pm2 start dist/index.js --name easy-basket-api

# Or if using npm start
pm2 start npm --name easy-basket-api -- start

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
# Follow the command it outputs (usually sudo command)

# Check status
pm2 status
pm2 logs easy-basket-api
```

### 2.8 Test Application

```bash
# Test if API is running
curl http://localhost:3000/api/health
# Or
curl http://YOUR_PUBLIC_IP:3000/api/health
```

---

## 🌐 Step 3: Set Up Domain & SSL (Optional but Recommended)

### 3.1 Get Elastic IP

1. **EC2** → **Elastic IPs** → **Allocate Elastic IP address**
2. **Allocate**
3. **Actions** → **Associate Elastic IP address**
4. Select your EC2 instance
5. **Associate**

### 3.2 Configure Domain (if you have one)

1. **Route 53** → **Hosted zones** → **Create hosted zone**
2. Enter your domain name
3. Update your domain's nameservers at your registrar

### 3.3 Set Up Nginx Reverse Proxy

```bash
# Install Nginx
sudo yum install -y nginx  # For Amazon Linux
# OR
sudo apt install -y nginx  # For Ubuntu

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure Nginx
sudo nano /etc/nginx/conf.d/easy-basket.conf
```

**Add this configuration:**
```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Save and test:**
```bash
# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### 3.4 Set Up SSL with Let's Encrypt

```bash
# Install Certbot
sudo yum install -y certbot python3-certbot-nginx  # For Amazon Linux
# OR
sudo apt install -y certbot python3-certbot-nginx  # For Ubuntu

# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Follow prompts:
# - Enter email
# - Agree to terms
# - Choose redirect HTTP to HTTPS

# Test auto-renewal
sudo certbot renew --dry-run
```

---

## 🔒 Step 4: Security Hardening

### 4.1 Update Security Groups

1. **EC2 Security Group:**
   - Remove port 3000 from public access
   - Only allow 80, 443, and 22 (SSH from your IP)

2. **RDS Security Group:**
   - Only allow MySQL (3306) from EC2 security group
   - Remove public access if possible

### 4.2 Set Up Firewall (UFW for Ubuntu)

```bash
# Install UFW (if Ubuntu)
sudo apt install -y ufw

# Allow SSH, HTTP, HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### 4.3 Secure Environment Variables

```bash
# Don't commit .env to Git
# Use AWS Systems Manager Parameter Store or Secrets Manager

# Install AWS CLI (if not installed)
# Configure AWS credentials
aws configure

# Store secrets in Parameter Store
aws ssm put-parameter \
  --name "/easy-basket/db-password" \
  --value "your-password" \
  --type "SecureString"

# Retrieve in application
# Use AWS SDK to fetch parameters
```

---

## 📱 Step 5: Update Mobile App Configuration

### 5.1 Update API Base URL

**File:** `mobile/lib/config/app_config.dart`

```dart
class AppConfig {
  // Production API URL
  static const String apiBaseUrl = 'https://your-domain.com/api';
  // OR if using IP (not recommended for production)
  // static const String apiBaseUrl = 'http://YOUR_ELASTIC_IP/api';
  
  // For Android emulator (development)
  // static const String apiBaseUrl = 'http://10.0.2.2:3000/api';
  
  // For web (development)
  // static const String apiBaseUrl = 'http://localhost:3000/api';
}
```

### 5.2 Update Razorpay Keys

**File:** `backend/.env`

```env
RAZORPAY_KEY_ID=your-production-key-id
RAZORPAY_KEY_SECRET=your-production-key-secret
```

---

## 🔍 Step 6: Monitoring & Logging

### 6.1 Set Up CloudWatch Logs

```bash
# Install CloudWatch agent (optional)
# For basic monitoring, PM2 logs are sufficient

# View PM2 logs
pm2 logs easy-basket-api

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 6.2 Set Up CloudWatch Alarms

1. **CloudWatch** → **Alarms** → **Create alarm**
2. Monitor:
   - CPU utilization
   - Memory usage
   - Disk space
   - Application errors

---

## 🧪 Step 7: Testing Deployment

### 7.1 Test API Endpoints

```bash
# Health check
curl https://your-domain.com/api/health

# Test authentication
curl -X POST https://your-domain.com/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "9876543210"}'

# Test products
curl https://your-domain.com/api/products
```

### 7.2 Test from Mobile App

1. Update `app_config.dart` with production URL
2. Build and test app
3. Test all flows:
   - Login
   - Browse products
   - Add to cart
   - Place order
   - Payment

---

## 📊 Step 8: Database Backup Strategy

### 8.1 Automated Backups (RDS)

- RDS automatically creates daily backups
- Retention: 7 days (configurable)
- Manual snapshots: Create before major changes

### 8.2 Manual Backup

```bash
# Create manual snapshot
# RDS → Snapshots → Take snapshot

# Or via CLI
aws rds create-db-snapshot \
  --db-instance-identifier easy-basket-db \
  --db-snapshot-identifier easy-basket-manual-backup-$(date +%Y%m%d)
```

---

## 🚨 Troubleshooting

### Common Issues

1. **Can't connect to database:**
   - Check security group rules
   - Verify RDS endpoint
   - Check database credentials

2. **Application not starting:**
   - Check PM2 logs: `pm2 logs easy-basket-api`
   - Verify environment variables
   - Check Node.js version

3. **502 Bad Gateway:**
   - Check if app is running: `pm2 status`
   - Check Nginx error logs
   - Verify proxy configuration

4. **SSL certificate issues:**
   - Ensure domain points to server
   - Check Nginx configuration
   - Verify firewall allows 80/443

---

## 💰 Cost Estimation (Monthly)

### Free Tier (First 12 Months):
- **EC2 t2.micro:** Free (750 hours/month)
- **RDS db.t3.micro:** Free (750 hours/month)
- **Data Transfer:** 1 GB free
- **Total:** ~$0/month

### Production (After Free Tier):
- **EC2 t3.small:** ~$15/month
- **RDS db.t3.small:** ~$25/month
- **Data Transfer:** ~$5-10/month
- **Elastic IP:** Free (if attached)
- **Total:** ~$45-50/month

---

## ✅ Deployment Checklist

- [ ] RDS MySQL database created
- [ ] Security groups configured
- [ ] EC2 instance created and configured
- [ ] Backend code deployed
- [ ] Environment variables set
- [ ] Database initialized
- [ ] PM2 running application
- [ ] Nginx configured (if using)
- [ ] SSL certificate installed (if using domain)
- [ ] Mobile app updated with production URL
- [ ] All endpoints tested
- [ ] Monitoring set up
- [ ] Backups configured

---

## 🎯 Quick Commands Reference

```bash
# Connect to EC2
ssh -i key.pem ec2-user@IP

# View application logs
pm2 logs easy-basket-api

# Restart application
pm2 restart easy-basket-api

# Stop application
pm2 stop easy-basket-api

# View Nginx logs
sudo tail -f /var/log/nginx/error.log

# Test Nginx config
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Check application status
pm2 status
curl http://localhost:3000/api/health
```

---

## 📚 Additional Resources

- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [PM2 Documentation](https://pm2.keymetrics.io/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

**Your backend is now deployed on AWS! 🚀**

Next: Update mobile app with production URL and test everything!

