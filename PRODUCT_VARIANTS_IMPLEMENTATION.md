# Product Variants Implementation Guide

## 🎯 Overview

This guide explains how to implement and use the product variants system for flexible quantity/weight selection (e.g., pulses: 250g, 500g, 1kg, 2kg, 5kg).

## 📋 Prerequisites

- Backend running with TypeORM
- Database access (MySQL)
- Admin access to create variants

## 🚀 Quick Start

### 1. Database Migration

Run the migration script to add variant support:

```bash
# Option 1: Using MySQL CLI
mysql -u root -p easy_basket < backend/src/scripts/migrate-product-variants.sql

# Option 2: Using TypeORM (if synchronize is enabled in development)
# The entities will auto-create the tables
```

### 2. Backend Setup

The backend is already configured with:
- ✅ `ProductVariant` entity
- ✅ Updated `Product` entity (with `hasVariants`, `baseUnit`, `minQuantity`, `maxQuantity`)
- ✅ Updated `OrderItem` entity (with `variantId`, `unit`, `displayLabel`)
- ✅ Variant controllers and routes
- ✅ Product controllers updated to include variants

### 3. API Endpoints

#### Get Variants for a Product (Public)
```http
GET /api/products/:productId/variants
```

Response:
```json
{
  "variants": [
    {
      "id": 1,
      "quantity": 0.25,
      "unit": "kg",
      "label": "250g",
      "price": 50.00,
      "stock": 100,
      "isAvailable": true,
      "displayOrder": 1,
      "isDefault": false
    }
  ]
}
```

#### Create Variant (Admin)
```http
POST /api/admin/products/:productId/variants
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "quantity": 0.25,
  "unit": "kg",
  "label": "250g",
  "price": 50.00,
  "stock": 100,
  "isAvailable": true,
  "minQuantity": 0.25,
  "maxQuantity": 5.0,
  "displayOrder": 1,
  "isDefault": false
}
```

#### Update Variant (Admin)
```http
PUT /api/admin/variants/:id
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "price": 55.00,
  "stock": 120
}
```

#### Delete Variant (Admin)
```http
DELETE /api/admin/variants/:id
Authorization: Bearer <admin_token>
```

### 4. Product Response (Includes Variants)

When fetching a product, variants are automatically included:

```http
GET /api/products/:id
```

Response:
```json
{
  "id": 1,
  "name": "Toor Dal (Pigeon Peas)",
  "hasVariants": true,
  "baseUnit": "kg",
  "minQuantity": 0.25,
  "maxQuantity": 5.0,
  "variants": [
    {
      "id": 1,
      "quantity": 0.25,
      "unit": "kg",
      "label": "250g",
      "price": 50.00,
      "stock": 100,
      "isAvailable": true,
      "displayOrder": 1,
      "isDefault": false
    },
    {
      "id": 3,
      "quantity": 1.0,
      "unit": "kg",
      "label": "1 kg",
      "price": 180.00,
      "stock": 50,
      "isAvailable": true,
      "displayOrder": 3,
      "isDefault": true
    }
  ]
}
```

## 📝 Example: Creating Variants for Pulses

### Step 1: Create/Select a Product

First, ensure you have a product (e.g., "Toor Dal") in the database.

### Step 2: Create Variants

Use the admin API to create variants:

```bash
# Get admin token first
TOKEN="your_admin_token"
PRODUCT_ID=1

# Create 250g variant
curl -X POST http://localhost:3000/api/admin/products/$PRODUCT_ID/variants \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 0.25,
    "unit": "kg",
    "label": "250g",
    "price": 50.00,
    "stock": 100,
    "displayOrder": 1
  }'

# Create 1/2 kg variant
curl -X POST http://localhost:3000/api/admin/products/$PRODUCT_ID/variants \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 0.5,
    "unit": "kg",
    "label": "1/2 kg",
    "price": 95.00,
    "stock": 80,
    "displayOrder": 2
  }'

# Create 1kg variant (default)
curl -X POST http://localhost:3000/api/admin/products/$PRODUCT_ID/variants \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 1.0,
    "unit": "kg",
    "label": "1 kg",
    "price": 180.00,
    "stock": 50,
    "displayOrder": 3,
    "isDefault": true
  }'

# Create 2kg variant
curl -X POST http://localhost:3000/api/admin/products/$PRODUCT_ID/variants \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 2.0,
    "unit": "kg",
    "label": "2 kg",
    "price": 350.00,
    "stock": 30,
    "displayOrder": 4
  }'

# Create 5kg variant
curl -X POST http://localhost:3000/api/admin/products/$PRODUCT_ID/variants \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 5.0,
    "unit": "kg",
    "label": "5 kg",
    "price": 850.00,
    "stock": 20,
    "displayOrder": 5
  }'
```

### Step 3: Update Product

Update the product to indicate it has variants:

```bash
curl -X PUT http://localhost:3000/api/admin/products/$PRODUCT_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "hasVariants": true,
    "baseUnit": "kg",
    "minQuantity": 0.25,
    "maxQuantity": 5.0
  }'
```

## 🛒 Cart & Order Integration

### Adding to Cart with Variant

When a customer selects a variant and adds to cart:

```javascript
{
  productId: 1,
  variantId: 3,  // 1kg variant
  quantity: 2,   // 2 units of 1kg = 2kg total
  unit: "kg",
  price: 180.00, // Price per unit
  total: 360.00, // 2 × 180
  displayLabel: "2 × 1 kg"
}
```

### OrderItem Structure

When creating an order, include variant information:

```json
{
  "productId": 1,
  "variantId": 3,
  "quantity": 2,
  "unit": "kg",
  "price": 180.00,
  "total": 360.00,
  "displayLabel": "2 × 1 kg"
}
```

## 🎨 Frontend Implementation (Next Steps)

### 1. Update Product Model

Add variant support to `ProductModel`:

```dart
class ProductModel {
  // ... existing fields
  final bool hasVariants;
  final String? baseUnit;
  final double? minQuantity;
  final double? maxQuantity;
  final List<ProductVariantModel>? variants;
}
```

### 2. Create Variant Model

```dart
class ProductVariantModel {
  final int id;
  final double quantity;
  final String unit;
  final String label;
  final double price;
  final int stock;
  final bool isAvailable;
  final bool isDefault;
}
```

### 3. Create Variant Selector Widget

```dart
class VariantSelector extends StatelessWidget {
  final List<ProductVariantModel> variants;
  final ProductVariantModel? selectedVariant;
  final Function(ProductVariantModel) onVariantSelected;
  final int quantity;
  final Function(int) onQuantityChanged;

  // UI with variant chips and quantity selector
}
```

### 4. Update Product Detail Screen

- Show variant selector if `product.hasVariants == true`
- Show quantity selector (1, 2, 3, etc.)
- Calculate total: `quantity × selectedVariant.price`
- Display: `"$quantity × ${selectedVariant.label}"`

## ✅ Testing Checklist

- [ ] Database migration successful
- [ ] Can create variants via API
- [ ] Product includes variants in response
- [ ] Variants sorted by displayOrder
- [ ] Default variant works correctly
- [ ] Stock validation per variant
- [ ] Cart handles variants correctly
- [ ] Orders store variant information
- [ ] Admin can manage variants

## 🔍 Troubleshooting

### Variants not showing in product response
- Check `hasVariants` is set to `true` on product
- Verify variants exist for the product
- Check relations are loaded: `relations: ['variants']`

### Variant creation fails
- Verify product exists
- Check required fields (quantity, unit, label, price)
- Ensure unit matches product baseUnit (if set)

### Stock issues
- Variant stock is separate from product stock
- Check `variant.stock` not `product.stock`
- Update variant stock when orders are placed

## 📚 Additional Resources

- See `PRODUCT_VARIANTS_DESIGN.md` for detailed design
- See `backend/src/entities/ProductVariant.ts` for entity definition
- See `backend/src/controllers/variant.controller.ts` for API logic

