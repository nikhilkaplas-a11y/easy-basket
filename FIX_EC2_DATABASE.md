# 🔧 Fix Database Connection Error on EC2

## ❌ Error You're Seeing

```
Access denied for user 'root'@'172.31.21.177' (using password: YES)
```

**Problem:** Backend is trying to connect as `root` instead of `admin`, and `.env` file might be missing or incorrect.

---

## ✅ Quick Fix

### Option 1: Run Fix Script (Easiest)

On your EC2 instance:

```bash
cd ~/easy-basket/backend
bash fix-db-connection.sh
```

This script will:
- Create/update `.env` file with correct credentials
- Rebuild TypeScript
- Restart PM2
- Show logs

---

### Option 2: Manual Fix

#### Step 1: Navigate to Backend

```bash
cd ~/easy-basket/backend
```

**Note:** Make sure you're in `~/easy-basket/backend` NOT `~/easy-basket/backend/backend`

#### Step 2: Create/Update .env File

```bash
nano .env
```

**Add/Update these lines:**

```env
# Server
PORT=3000
NODE_ENV=production

# Database (RDS)
DB_HOST=easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASS=nikhilkaplas
DB_NAME=easybasket

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Razorpay (Add your production keys)
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret

# CORS
CORS_ORIGIN=*
```

**Save:** `Ctrl+X`, then `Y`, then `Enter`

#### Step 3: Verify .env File

```bash
cat .env | grep DB_
```

Should show:
```
DB_HOST=easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASS=nikhilkaplas
DB_NAME=easybasket
```

#### Step 4: Rebuild and Restart

```bash
# Rebuild TypeScript
npm run build

# Restart PM2
pm2 restart easy-basket-api

# Check logs
pm2 logs easy-basket-api --lines 20
```

---

## 🔍 Verify Database Connection

After restart, check logs:

```bash
pm2 logs easy-basket-api --lines 30
```

**Look for:**
- ✅ `Database connected` - Success!
- ❌ `Access denied` - Check credentials
- ❌ `ECONNREFUSED` - Check security group

---

## 🐛 Troubleshooting

### Error: "Access denied for user 'root'"

**Cause:** `.env` file has wrong user or doesn't exist

**Fix:**
```bash
# Check .env file
cat .env | grep DB_USER

# Should show: DB_USER=admin
# If shows: DB_USER=root or nothing, update it
```

### Error: "Cannot find module"

**Cause:** Dependencies not installed or wrong path

**Fix:**
```bash
cd ~/easy-basket/backend
npm install
npm run build
pm2 restart easy-basket-api
```

### Error: "ECONNREFUSED"

**Cause:** Security group not allowing connection from EC2

**Fix:**
1. Go to RDS → Your database → Security groups
2. Edit inbound rules
3. Add rule: MySQL/Aurora, Port 3306
4. Source: EC2 security group (not your IP)

### Wrong Path (backend/backend)

**Cause:** Cloned into wrong directory

**Fix:**
```bash
# Check current path
pwd

# Should be: /home/ec2-user/easy-basket/backend
# If you see backend/backend, fix it:

cd ~/easy-basket
ls -la
# If you see backend/backend, move files:
mv backend/backend/* backend/
rm -rf backend/backend
```

---

## ✅ Success Checklist

- [ ] `.env` file exists in `~/easy-basket/backend/`
- [ ] `DB_USER=admin` (not root)
- [ ] `DB_PASS=nikhilkaplas` (correct password)
- [ ] `DB_HOST` points to RDS endpoint
- [ ] TypeScript rebuilt (`npm run build`)
- [ ] PM2 restarted (`pm2 restart easy-basket-api`)
- [ ] Logs show "Database connected"

---

## 📋 Quick Commands

```bash
# Navigate to backend
cd ~/easy-basket/backend

# Check .env
cat .env | grep DB_

# Update .env (if needed)
nano .env

# Rebuild
npm run build

# Restart
pm2 restart easy-basket-api

# Check logs
pm2 logs easy-basket-api --lines 20
```

---

**After fixing, your backend should connect to RDS! 🚀**

