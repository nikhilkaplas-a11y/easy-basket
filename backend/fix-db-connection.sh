#!/bin/bash

# Fix Database Connection on EC2
# Run this on your EC2 instance

echo "🔧 Fixing Database Connection..."

# Navigate to correct directory
cd ~/easy-basket/backend

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found! Creating it..."
    cat > .env << 'ENVFILE'
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
ENVFILE
    echo "✅ Created .env file"
else
    echo "✅ .env file exists"
fi

# Check .env content
echo ""
echo "📋 Current .env database settings:"
grep -E "^DB_" .env || echo "❌ DB_ variables not found in .env"

# Update .env with correct values
echo ""
echo "🔧 Updating .env with correct database credentials..."

# Use sed to update or add DB variables
sed -i 's|^DB_HOST=.*|DB_HOST=easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com|' .env 2>/dev/null || \
    echo "DB_HOST=easy-basket-db.c9guq6egarb5.eu-north-1.rds.amazonaws.com" >> .env

sed -i 's|^DB_PORT=.*|DB_PORT=3306|' .env 2>/dev/null || \
    echo "DB_PORT=3306" >> .env

sed -i 's|^DB_USER=.*|DB_USER=admin|' .env 2>/dev/null || \
    echo "DB_USER=admin" >> .env

sed -i 's|^DB_PASS=.*|DB_PASS=nikhilkaplas|' .env 2>/dev/null || \
    echo "DB_PASS=nikhilkaplas" >> .env

sed -i 's|^DB_NAME=.*|DB_NAME=easybasket|' .env 2>/dev/null || \
    echo "DB_NAME=easybasket" >> .env

echo "✅ Updated .env file"

# Rebuild TypeScript
echo ""
echo "🔨 Rebuilding TypeScript..."
npm run build

# Restart PM2
echo ""
echo "🔄 Restarting PM2..."
pm2 restart easy-basket-api

# Wait a moment
sleep 2

# Check status
echo ""
echo "📊 PM2 Status:"
pm2 status

# Show recent logs
echo ""
echo "📋 Recent logs (last 20 lines):"
pm2 logs easy-basket-api --lines 20 --nostream

echo ""
echo "✅ Done! Check logs above for any errors."
echo "   If you see 'Database connected', you're good! ✅"

