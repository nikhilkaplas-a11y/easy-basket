#!/bin/bash

# Script to remove unused/temporary markdown files
# Keeping only essential documentation

cd /Users/nikhil/Projects/easyBucket

# Files to KEEP (essential documentation)
KEEP_FILES=(
  "AWS_DEPLOYMENT_GUIDE.md"
  "FIREBASE_SETUP_GUIDE.md"
  "PM2_COMMANDS.md"
  "GOOGLE_PLAY_STORE_GUIDE.md"
  "PRODUCT_IMAGES_GUIDE.md"
  "HOW_TO_USE_ADMIN.md"
  "JWT_AUTHENTICATION_EXPLAINED.md"
  "REFRESH_TOKEN_EXPLAINED.md"
  "RAZORPAY_SETUP.md"
  "GOOGLE_MAPS_SETUP.md"
  "DELIVERY_APP_FEATURES.md"
  "SERVICE_AREA_FEATURE.md"
  "ADMIN_ORDER_NOTIFICATION_BEHAVIOR.md"
)

# Patterns to REMOVE (temporary/debug files)
REMOVE_PATTERNS=(
  "FIX_*.md"
  "DEBUG_*.md"
  "CHECK_*.md"
  "TEST_*.md"
  "COMPLETE_*.md"
  "FINAL_*.md"
  "NEXT_STEPS*.md"
  "TROUBLESHOOT_*.md"
  "NOTIFICATION_*.md"
  "FCM_*.md"
  "RESTART_*.md"
  "REMOVE_*.md"
  "FIX_GITHUB_*.md"
  "QUICK_*.md"
  "CONNECT_*.md"
  "DIAGNOSE_*.md"
  "GET_*.md"
  "INSTALL_*.md"
  "PUSH_*.md"
  "RECREATE_*.md"
  "RESET_*.md"
  "REORGANIZE_*.md"
  "REMAINING_*.md"
  "ROLE_*.md"
  "RUN_*.md"
  "SETUP_*.md"
  "SIMPLE_*.md"
  "START_*.md"
  "VERIFY_*.md"
  "ADDRESS_*.md"
  "ADMIN_API_*.md"
  "ADMIN_DASHBOARD_*.md"
  "ANDROID_*.md"
  "API_KEY_*.md"
  "AWS_SNS_*.md"
  "DOMAIN_*.md"
  "EC2_*.md"
  "GITHUB_*.md"
  "LOCATION_*.md"
  "NGINX_*.md"
  "RAZORPAY_INTEGRATION_*.md"
  "RAZORPAY_TIMELINE.md"
  "REFRESH_TOKEN_API.md"
  "RESPONSIVE_*.md"
  "DELIVERY_AGENT_*.md"
)

echo "🧹 Cleaning up unused markdown files..."
echo ""

# Create backup directory
BACKUP_DIR=".md_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Count files to remove
REMOVE_COUNT=0
KEEP_COUNT=0

# Process all .md files in root
for file in *.md; do
  if [ ! -f "$file" ]; then
    continue
  fi
  
  # Check if file should be kept
  KEEP_THIS=false
  for keep_file in "${KEEP_FILES[@]}"; do
    if [ "$file" == "$keep_file" ]; then
      KEEP_THIS=true
      break
    fi
  done
  
  if [ "$KEEP_THIS" == true ]; then
    echo "✅ KEEP: $file"
    ((KEEP_COUNT++))
    continue
  fi
  
  # Check if file matches remove patterns
  REMOVE_THIS=false
  for pattern in "${REMOVE_PATTERNS[@]}"; do
    if [[ "$file" == $pattern ]]; then
      REMOVE_THIS=true
      break
    fi
  done
  
  if [ "$REMOVE_THIS" == true ]; then
    echo "🗑️  REMOVE: $file"
    mv "$file" "$BACKUP_DIR/"
    ((REMOVE_COUNT++))
  else
    echo "❓ UNKNOWN: $file (keeping for safety)"
    ((KEEP_COUNT++))
  fi
done

echo ""
echo "📊 Summary:"
echo "   Kept: $KEEP_COUNT files"
echo "   Removed: $REMOVE_COUNT files"
echo "   Backup: $BACKUP_DIR/"
echo ""
echo "✅ Cleanup complete!"
echo "   If you need any removed files, check: $BACKUP_DIR/"

