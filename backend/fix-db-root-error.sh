#!/bin/bash

# Fix Database Connection - Still Using 'root' Error
# Run this on your EC2 instance

echo "🔧 Fixing Database Connection Error..."

# Step 1: Check and fix path
echo ""
echo "📂 Checking directory structure..."
cd ~/easy-basket

# Check if backend/backend exists (wrong structure)
if [ -d "backend/backend" ]; then
    echo "⚠️  Found backend/backend - fixing structure..."
    cd backend/backend
    # Move files up one level
    mv * ../ 2>/dev/null || true
    mv .* ../ 2>/dev/null || true
    cd ..
    rmdir backend 2>/dev/null || true
    cd ~/easy-basket
    echo "✅ Fixed directory structure"
fi

# Step 2: Navigate to correct backend directory
cd ~/easy-basket/backend
echo "✅ Current directory: $(pwd)"

# Step 3: Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found! Creating it..."
    cat > .env << 'ENVFILE'
# Server
PORT=3000
NODE_ENV=production

# Database (RDS) - IMPORTANT: Use 'admin' not 'root'
DB_HOST=easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com
DB_PORT=3306
DB_USER=admin
DB_PASS=nikhilkaplas
DB_NAME=easybasket

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# Razorpay
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret

# CORS
CORS_ORIGIN=*
ENVFILE
    echo "✅ Created .env file"
else
    echo "✅ .env file exists"
fi

# Step 4: Check and fix .env content
echo ""
echo "🔍 Checking .env file content..."
if grep -q "DB_USER=root" .env 2>/dev/null; then
    echo "⚠️  Found DB_USER=root - fixing to admin..."
    sed -i 's/^DB_USER=root/DB_USER=admin/' .env
    echo "✅ Updated DB_USER to admin"
fi

if ! grep -q "^DB_USER=admin" .env; then
    echo "⚠️  DB_USER not set correctly - fixing..."
    sed -i '/^DB_USER=/d' .env
    echo "DB_USER=admin" >> .env
    echo "✅ Added DB_USER=admin"
fi

if ! grep -q "^DB_PASS=nikhilkaplas" .env; then
    echo "⚠️  DB_PASS not set correctly - fixing..."
    sed -i '/^DB_PASS=/d' .env
    echo "DB_PASS=nikhilkaplas" >> .env
    echo "✅ Added DB_PASS"
fi

if ! grep -q "^DB_HOST=easy-basket-db" .env; then
    echo "⚠️  DB_HOST not set correctly - fixing..."
    sed -i '/^DB_HOST=/d' .env
    echo "DB_HOST=easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com" >> .env
    echo "✅ Added DB_HOST"
fi

# Step 5: Show current .env database settings
echo ""
echo "📋 Current .env database settings:"
grep -E "^DB_" .env || echo "❌ No DB_ variables found!"

# Step 6: Rebuild TypeScript
echo ""
echo "🔨 Rebuilding TypeScript..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Check for errors above."
    exit 1
fi

# Step 7: Restart PM2
echo ""
echo "🔄 Restarting PM2..."
pm2 restart easy-basket-api

# Wait a moment
sleep 3

# Step 8: Check status
echo ""
echo "📊 PM2 Status:"
pm2 status

# Step 9: Show recent logs
echo ""
echo "📋 Recent logs (checking for 'Database connected'):"
pm2 logs easy-basket-api --lines 30 --nostream | tail -20

echo ""
echo "✅ Fix complete!"
echo ""
echo "🔍 Check logs above:"
echo "   ✅ 'Database connected' = Success!"
echo "   ❌ 'Access denied' = Check .env file again"
echo ""
echo "📋 To view live logs:"
echo "   pm2 logs easy-basket-api"

