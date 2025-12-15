# Product Variants System - Design Document

## 📋 Executive Summary

This document outlines the design for a flexible product variant system that allows customers to select different quantities/weights for products (e.g., pulses: 250g, 500g, 1kg, 2kg, 5kg).

## 🎯 Business Requirements

### Use Cases
1. **Pulses Category**: Customers can select from:
   - 250g (minimum)
   - 500g (1/2 kg)
   - 1kg
   - 2kg
   - 5kg (maximum)

2. **Other Products**: Can have variants or use base product pricing
   - Products without variants: Use base price/stock
   - Products with variants: Show variant selector

3. **Pricing Flexibility**:
   - Bulk discounts (e.g., 5kg cheaper per kg than 1kg)
   - Different pricing per variant
   - Promotional pricing per variant

## 🗄️ Database Design

### Entity: ProductVariant

```typescript
{
  id: number
  productId: number (FK to Product)
  quantity: decimal (0.25, 0.5, 1, 2, 5) - in base unit
  unit: string ('g', 'kg', 'piece')
  label: string ('250g', '1/2 kg', '1 kg', '2 kg', '5 kg')
  price: decimal (variant-specific price)
  stock: number (variant-specific stock)
  isAvailable: boolean
  minQuantity: decimal | null (0.25 for pulses)
  maxQuantity: decimal | null (5 for pulses)
  displayOrder: number (sort order)
  isDefault: boolean (default selection)
}
```

### Updated Entity: Product

```typescript
{
  // ... existing fields
  hasVariants: boolean (true if product has variants)
  baseUnit: string ('kg' for pulses)
  minQuantity: decimal | null (product-level min)
  maxQuantity: decimal | null (product-level max)
  variants: ProductVariant[] (one-to-many)
}
```

### Updated Entity: OrderItem

```typescript
{
  // ... existing fields
  variantId: number | null (FK to ProductVariant)
  quantity: decimal (number of variant units)
  unit: string ('kg', 'g', etc.)
  displayLabel: string ('2 × 1 kg', '250g')
}
```

## 📊 Example Data Structure

### Product: "Toor Dal (Pigeon Peas)"

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
      "displayOrder": 1,
      "isDefault": false
    },
    {
      "id": 2,
      "quantity": 0.5,
      "unit": "kg",
      "label": "1/2 kg",
      "price": 95.00,
      "stock": 80,
      "displayOrder": 2,
      "isDefault": false
    },
    {
      "id": 3,
      "quantity": 1.0,
      "unit": "kg",
      "label": "1 kg",
      "price": 180.00,
      "stock": 50,
      "displayOrder": 3,
      "isDefault": true
    },
    {
      "id": 4,
      "quantity": 2.0,
      "unit": "kg",
      "label": "2 kg",
      "price": 350.00,
      "stock": 30,
      "displayOrder": 4,
      "isDefault": false
    },
    {
      "id": 5,
      "quantity": 5.0,
      "unit": "kg",
      "label": "5 kg",
      "price": 850.00,
      "stock": 20,
      "displayOrder": 5,
      "isDefault": false
    }
  ]
}
```

## 🔄 Business Logic

### Variant Selection Rules

1. **Minimum Quantity**: 250g (0.25kg) for pulses
2. **Maximum Quantity**: 5kg per variant
3. **Stock Check**: Check variant stock, not product stock
4. **Pricing**: Use variant price if exists, else product base price
5. **Display**: Show all available variants sorted by displayOrder

### Cart Logic

- When adding to cart with variant:
  - Store `variantId` in cart item
  - Store `quantity` (number of variant units)
  - Calculate total: `quantity × variant.price`
  - Display: `quantity × variant.label` (e.g., "2 × 1 kg")

### Order Processing

- OrderItem stores:
  - `productId`: Reference to product
  - `variantId`: Reference to variant (if applicable)
  - `quantity`: Number of variant units
  - `unit`: Unit of measurement
  - `price`: Price per unit at time of order
  - `displayLabel`: Human-readable label

## 🎨 UI/UX Design

### Product Detail Screen

```
┌─────────────────────────────┐
│  [Product Image]            │
│                             │
│  Toor Dal (Pigeon Peas)    │
│  ₹180                      │
│                             │
│  Select Quantity:           │
│  ┌─────┐ ┌─────┐ ┌─────┐   │
│  │250g │ │1/2kg│ │ 1kg │   │
│  │₹50  │ │₹95  │ │₹180 │   │
│  └─────┘ └─────┘ └─────┘   │
│  ┌─────┐ ┌─────┐           │
│  │ 2kg │ │ 5kg │           │
│  │₹350 │ │₹850 │           │
│  └─────┘ └─────┘           │
│                             │
│  [Selected: 1 kg × 2]      │
│  Total: ₹360               │
│                             │
│  [Add to Cart]             │
└─────────────────────────────┘
```

### Cart Display

```
┌─────────────────────────────┐
│  Toor Dal                   │
│  2 × 1 kg                   │
│  ₹360                       │
│  [Quantity Selector]         │
└─────────────────────────────┘
```

## 🔧 Implementation Plan

### Phase 1: Backend (Database & API)
1. ✅ Create ProductVariant entity
2. ✅ Update Product entity
3. ✅ Update OrderItem entity
4. Create variant controllers
5. Create variant services
6. Add variant routes
7. Update product controllers to include variants

### Phase 2: Admin Panel
1. Add variant management UI
2. Create/Edit/Delete variants
3. Bulk variant creation
4. Variant stock management

### Phase 3: Customer App
1. Update ProductModel to include variants
2. Create variant selector widget
3. Update product detail screen
4. Update cart to handle variants
5. Update order processing

## 📝 API Endpoints

### Variant Management (Admin)

```
GET    /api/admin/products/:id/variants     - Get all variants for product
POST   /api/admin/products/:id/variants   - Create variant
PUT    /api/admin/variants/:id             - Update variant
DELETE /api/admin/variants/:id             - Delete variant
```

### Product with Variants (Customer)

```
GET /api/products/:id
Response includes:
{
  "id": 1,
  "name": "Toor Dal",
  "hasVariants": true,
  "variants": [...]
}
```

## 🧮 Calculation Examples

### Example 1: Customer selects 2 units of 1kg variant
- Variant: 1kg @ ₹180
- Quantity: 2
- Total: 2 × ₹180 = ₹360
- Display: "2 × 1 kg"

### Example 2: Customer selects 1 unit of 5kg variant
- Variant: 5kg @ ₹850
- Quantity: 1
- Total: 1 × ₹850 = ₹850
- Display: "1 × 5 kg"

### Example 3: Bulk discount calculation
- 1kg: ₹180/kg
- 5kg: ₹850 (₹170/kg) - 5.5% discount

## ✅ Benefits

1. **Flexibility**: Support any quantity/weight combination
2. **Pricing**: Different prices per variant (bulk discounts)
3. **Stock Management**: Track stock per variant
4. **Scalability**: Easy to add new variants
5. **User Experience**: Clear quantity selection
6. **Business Logic**: Enforce min/max limits per product type

## 🔒 Constraints & Validation

1. **Minimum Quantity**: Enforced at product and variant level
2. **Maximum Quantity**: Enforced at product and variant level
3. **Stock Validation**: Check variant stock before allowing purchase
4. **Unit Consistency**: All variants of a product use same base unit
5. **Price Validation**: Variant price must be positive

## 📈 Future Enhancements

1. **Custom Quantities**: Allow customers to enter custom quantity (within min/max)
2. **Bulk Pricing Tiers**: Automatic discounts based on quantity
3. **Variant Images**: Different images for different variants
4. **Variant Descriptions**: Additional info per variant
5. **Promotional Variants**: Special pricing for specific variants

