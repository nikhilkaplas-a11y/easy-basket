#!/bin/bash

# Fix Firebase Service Account JSON in .env file
# This script converts the multi-line JSON to a single-line string

echo "🔧 Fixing Firebase Service Account in .env file..."

cd "$(dirname "$0")"

# Check if JSON file exists
JSON_FILE="/Users/nikhil/Desktop/easy-basket-84b0d-firebase-adminsdk-fbsvc-7e496a3282.json"
if [ ! -f "$JSON_FILE" ]; then
    echo "❌ Firebase JSON file not found at: $JSON_FILE"
    exit 1
fi

# Convert JSON to single-line and escape quotes
FIREBASE_JSON=$(cat "$JSON_FILE" | jq -c . | sed 's/"/\\"/g')

# Backup .env file
if [ -f .env ]; then
    cp .env .env.backup
    echo "✅ Backed up .env to .env.backup"
fi

# Remove old FIREBASE_SERVICE_ACCOUNT line(s)
sed -i.bak '/^FIREBASE_SERVICE_ACCOUNT/d' .env

# Add new FIREBASE_SERVICE_ACCOUNT line
echo "FIREBASE_SERVICE_ACCOUNT=\"$FIREBASE_JSON\"" >> .env

echo "✅ Firebase Service Account updated in .env"
echo ""
echo "📋 Next steps:"
echo "1. Restart your backend server"
echo "2. Check logs for '✅ Firebase Admin initialized'"
echo "3. Test notifications by placing an order"

