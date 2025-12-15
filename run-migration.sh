#!/bin/bash

# Migration Script Runner for Subcategories
# This script will run the database migration to add subcategory support

echo "🚀 Running Subcategories Migration..."
echo ""

# Default values (update if needed)
DB_USER="root"
DB_NAME="easy_basket"
MIGRATION_FILE="backend/src/scripts/migrate-subcategories-compatible.sql"

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Error: Migration file not found at $MIGRATION_FILE"
    exit 1
fi

echo "📄 Migration file: $MIGRATION_FILE"
echo "🗄️  Database: $DB_NAME"
echo "👤 User: $DB_USER"
echo ""
echo "Please enter your MySQL password when prompted:"
echo ""

# Run the migration
mysql -u "$DB_USER" -p "$DB_NAME" < "$MIGRATION_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration completed successfully!"
    echo ""
    echo "You can now:"
    echo "  1. Create parent categories in the admin portal"
    echo "  2. Create subcategories under parent categories"
    echo "  3. Test the subcategory navigation in the app"
else
    echo ""
    echo "❌ Migration failed. Please check the error messages above."
    exit 1
fi

