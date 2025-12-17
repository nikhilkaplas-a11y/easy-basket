#!/bin/bash

# Quick script to add AWS_S3_BUCKET_NAME to .env file
# Run this on your production server

echo "🔧 Adding AWS_S3_BUCKET_NAME to .env file..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found in current directory"
    echo "💡 Make sure you're in the backend directory: cd ~/easy-basket/backend"
    exit 1
fi

# Check if AWS_S3_BUCKET_NAME already exists
if grep -q "AWS_S3_BUCKET_NAME" .env; then
    echo "⚠️  AWS_S3_BUCKET_NAME already exists in .env"
    echo "📝 Current value:"
    grep "AWS_S3_BUCKET_NAME" .env
    echo ""
    read -p "Do you want to update it? (y/n): " update
    if [ "$update" != "y" ]; then
        echo "✅ Keeping existing value"
        exit 0
    fi
    # Remove old line
    sed -i '/^AWS_S3_BUCKET_NAME=/d' .env
fi

# Prompt for bucket name
echo "📦 Enter your S3 bucket name:"
read -p "Bucket name: " bucket_name

if [ -z "$bucket_name" ]; then
    echo "❌ Bucket name cannot be empty"
    exit 1
fi

# Add to .env file
echo "" >> .env
echo "# AWS S3 Bucket Name" >> .env
echo "AWS_S3_BUCKET_NAME=$bucket_name" >> .env

echo "✅ Added AWS_S3_BUCKET_NAME=$bucket_name to .env"
echo ""
echo "🔄 Now restart PM2:"
echo "   pm2 restart easy-basket-api"
echo ""
echo "📋 Verify it's set:"
echo "   pm2 logs easy-basket-api --lines 20"

