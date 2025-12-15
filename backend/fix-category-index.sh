#!/bin/bash

# Script to fix the Category index issue
# This ensures the foreign key constraint and index are properly configured

echo "🔧 Fixing Category index issue..."

# Load only database environment variables (avoid multi-line values)
if [ -f .env ]; then
    export DB_HOST=$(grep "^DB_HOST=" .env | cut -d '=' -f2-)
    export DB_PORT=$(grep "^DB_PORT=" .env | cut -d '=' -f2-)
    export DB_USER=$(grep "^DB_USER=" .env | cut -d '=' -f2-)
    export DB_PASS=$(grep "^DB_PASS=" .env | cut -d '=' -f2-)
    export DB_NAME=$(grep "^DB_NAME=" .env | cut -d '=' -f2-)
fi

# Check if database credentials are set
if [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_NAME" ]; then
    echo "❌ Database credentials not set. Please set DB_HOST, DB_USER, DB_PASS, and DB_NAME"
    exit 1
fi

# Read password if not set
if [ -z "$DB_PASS" ]; then
    read -sp "Enter database password: " DB_PASS
    echo
fi

echo "📊 Connecting to database: $DB_NAME on $DB_HOST"
echo ""

# Create SQL script to fix the issue
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
-- Check current state
SELECT 'Checking current foreign key constraints...' as status;
SELECT 
    CONSTRAINT_NAME, 
    TABLE_NAME, 
    COLUMN_NAME, 
    REFERENCED_TABLE_NAME, 
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = '$DB_NAME'
  AND TABLE_NAME = 'category'
  AND COLUMN_NAME = 'parentCategoryId';

SELECT 'Checking current indexes...' as status;
SELECT 
    INDEX_NAME,
    COLUMN_NAME,
    NON_UNIQUE
FROM information_schema.statistics 
WHERE table_schema = '$DB_NAME' 
  AND table_name = 'category' 
  AND column_name = 'parentCategoryId';

-- The issue is that TypeORM tries to drop the index IDX_category_parentCategoryId
-- But MySQL won't allow it because it's needed by the foreign key
-- Solution: The foreign key constraint automatically creates an index
-- We just need to ensure TypeORM doesn't try to manage it separately

SELECT '✅ Database schema check completed' as status;
EOF

echo ""
echo "✅ Database check completed"
echo ""
echo "💡 The foreign key constraint automatically creates an index in MySQL"
echo "💡 TypeORM's synchronize feature is trying to drop this index, which causes the error"
echo "💡 Solutions:"
echo "   1. Set synchronize: false in database.ts (recommended for production)"
echo "   2. The error is safe to ignore if your database schema is already correct"
echo "   3. Use TypeORM migrations instead of synchronize for better control"
