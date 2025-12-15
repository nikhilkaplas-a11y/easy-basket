# Product Variants Management Guide

## 📱 How to Add Variants in Admin Portal

### Method 1: From Product List Screen

1. **Navigate to Admin Products**
   - Go to Admin Dashboard → Products

2. **Click the Variant Icon** (📦 orange icon)
   - Located next to Edit and Delete buttons on each product card
   - Opens the Variant Management Dialog

3. **Add Variants**
   - Click "Add Variant" button
   - Fill in the form:
     - **Label**: Display name (e.g., "250g", "1 kg", "2 kg")
     - **Quantity**: Numeric value (e.g., 0.25 for 250g, 1 for 1kg)
     - **Unit**: Select unit (g, kg, piece, etc.)
     - **Price**: Price for this variant
     - **Stock**: Available stock
     - **Min/Max Quantity**: Optional limits
     - **Display Order**: Sort order (lower = first)
     - **Set as Default**: Mark as default selection

4. **Save**
   - Click "Create" to save the variant
   - Repeat for all variants (250g, 500g, 1kg, 2kg, 5kg)

### Method 2: From Product Edit Screen

1. **Edit a Product**
   - Click Edit (✏️) on any product
   - Scroll down to "Product Variants" section

2. **Click "Manage Variants"**
   - Opens the Variant Management Dialog
   - Follow steps 3-4 from Method 1

## 📋 Example: Creating Variants for Pulses

### For "Toor Dal" Product:

1. Click variant icon (📦) on the product card
2. Add these variants:

**Variant 1: 250g**
- Label: `250g`
- Quantity: `0.25`
- Unit: `kg`
- Price: `50.00`
- Stock: `100`
- Display Order: `1`

**Variant 2: 1/2 kg**
- Label: `1/2 kg`
- Quantity: `0.5`
- Unit: `kg`
- Price: `95.00`
- Stock: `80`
- Display Order: `2`

**Variant 3: 1 kg** (Default)
- Label: `1 kg`
- Quantity: `1.0`
- Unit: `kg`
- Price: `180.00`
- Stock: `50`
- Display Order: `3`
- ✅ Set as Default: `Yes`

**Variant 4: 2 kg**
- Label: `2 kg`
- Quantity: `2.0`
- Unit: `kg`
- Price: `350.00`
- Stock: `30`
- Display Order: `4`

**Variant 5: 5 kg**
- Label: `5 kg`
- Quantity: `5.0`
- Unit: `kg`
- Price: `850.00`
- Stock: `20`
- Display Order: `5`

## ✏️ Editing Variants

1. Open Variant Management Dialog
2. Click Edit (✏️) icon on any variant
3. Modify fields as needed
4. Click "Update"

## 🗑️ Deleting Variants

1. Open Variant Management Dialog
2. Click Delete (🗑️) icon on any variant
3. Confirm deletion

## 💡 Tips

- **Display Order**: Use 1, 2, 3, 4, 5 to show variants in ascending order
- **Default Variant**: Only one variant can be default. Setting a new default automatically unsets the previous one.
- **Stock Management**: Track stock separately for each variant
- **Pricing**: Set different prices for bulk discounts (e.g., 5kg cheaper per kg)

## 🔄 After Creating Variants

1. **Update Product Settings** (Optional)
   - Edit the product
   - Set `hasVariants = true` (if not auto-set)
   - Set `baseUnit = 'kg'` (or appropriate unit)
   - Set `minQuantity = 0.25` and `maxQuantity = 5.0` (for pulses)

2. **Verify**
   - Check that variants appear in the list
   - Test product detail page (customer view) to see variant selector

## 🎯 Best Practices

- **Consistent Units**: Use the same base unit (kg) for all variants of a product
- **Clear Labels**: Use customer-friendly labels (250g, not 0.25kg)
- **Logical Ordering**: Sort by quantity (smallest to largest)
- **Stock Tracking**: Keep stock updated per variant
- **Default Selection**: Set the most popular variant as default

## ❓ Troubleshooting

**Variants not showing?**
- Check that product has `hasVariants = true`
- Verify variants exist in database
- Refresh the product list

**Can't create variant?**
- Ensure product exists first
- Check all required fields are filled
- Verify price and quantity are positive numbers

**Default not working?**
- Only one variant can be default at a time
- Check that `isDefault = true` is set correctly

