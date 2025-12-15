# Subcategories Implementation Guide

## Overview
This implementation adds hierarchical subcategories support to the EasyBucket application, similar to Blinkit's category structure. Users can now navigate through parent categories (e.g., "Oil and Ghee") to see subcategories (e.g., "Cooking Oil", "Ghee", "Mustard Oil") before viewing products.

## Database Changes

### Migration Script
Run the migration script to add subcategory support:
```bash
mysql -u root -p easy_basket < backend/src/scripts/migrate-subcategories-compatible.sql
```

### Schema Changes
- Added `parentCategoryId` column to `category` table (nullable, foreign key to `category.id`)
- Added `displayOrder` column for sorting categories
- Removed unique constraint on `name` (allows same names under different parents)
- Added composite unique constraint on `(name, parentCategoryId)` to prevent duplicates under same parent

## Backend Changes

### Entity Updates
- `Category` entity now supports parent-child relationships
- Added `parentCategory`, `subcategories`, and `displayOrder` fields
- Added helper methods: `isParentCategory`, `isLeafCategory`

### API Endpoints

#### Get Categories (with parent filter)
```
GET /api/categories?parentId={id}
```
- Returns top-level categories if `parentId` is not provided
- Returns subcategories if `parentId` is provided

#### Get Subcategories
```
GET /api/categories/:id/subcategories
```
- Returns all subcategories for a given parent category

#### Create Category (with parent support)
```
POST /api/admin/categories
Body: {
  name: string,
  description?: string,
  imageUrl?: string,
  parentCategoryId?: number,
  displayOrder?: number
}
```

#### Update Category (with parent support)
```
PUT /api/admin/categories/:id
Body: {
  name?: string,
  description?: string,
  imageUrl?: string,
  isActive?: boolean,
  parentCategoryId?: number | null,
  displayOrder?: number
}
```

## Frontend Changes

### Models
- `CategoryModel` now includes:
  - `parentCategoryId`
  - `parentCategory`
  - `subcategories`
  - `displayOrder`
  - Helper properties: `hasSubcategories`, `isTopLevel`, `isSubcategory`

### New Screen
- **SubcategorySelectionScreen**: Shows subcategories in a grid layout when user taps a parent category
  - Includes "View All Products" option to see all products in parent category
  - Navigates to product list when subcategory is selected

### Navigation Flow
1. User taps category on home/categories screen
2. If category has subcategories → Navigate to subcategory selection screen
3. If category has no subcategories → Navigate directly to products
4. User selects subcategory → Navigate to products in that subcategory

### Admin Portal
- **Add/Edit Category Screen**: Now includes parent category dropdown
  - Select parent category to create subcategory
  - Leave empty for top-level category
  - Prevents circular references (category cannot be its own parent)

## Usage Examples

### Creating a Parent Category
1. Go to Admin Portal → Categories → Add Category
2. Enter name: "Oil and Ghee"
3. Leave "Parent Category" as "None"
4. Save

### Creating Subcategories
1. Go to Admin Portal → Categories → Add Category
2. Enter name: "Cooking Oil"
3. Select "Parent Category": "Oil and Ghee"
4. Save
5. Repeat for other subcategories (Ghee, Mustard Oil, etc.)

### User Experience
1. User sees "Oil and Ghee" on categories screen
2. Taps "Oil and Ghee"
3. Sees subcategories: "Cooking Oil", "Ghee", "Mustard Oil", "View All"
4. Taps "Cooking Oil"
5. Sees products in Cooking Oil subcategory

## Benefits
- ✅ Better organization for large product catalogs
- ✅ Faster navigation (fewer products per screen)
- ✅ Better discoverability
- ✅ Scales well as product count grows
- ✅ Familiar UX pattern (similar to Blinkit, BigBasket)

## Notes
- Products should be assigned to leaf categories (subcategories), not parent categories
- Parent categories can have both subcategories and products (flexible)
- Display order can be set to control category sorting
- Categories with same name can exist under different parents

