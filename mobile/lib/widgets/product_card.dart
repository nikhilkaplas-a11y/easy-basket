import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../utils/theme.dart';
import '../utils/responsive.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.contains(product.id);
    final quantity = isInCart ? cartProvider.getQuantity(product.id) : 0;
    final isAdding = cartProvider.isAddingItem(product.id);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final responsive = Responsive(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive height based on screen size
    final cardHeight = screenWidth < 360 ? 200.0 : screenWidth < 400 ? 220.0 : 240.0;
    final fontSize = responsive.fontSize(13);
    final priceFontSize = responsive.fontSize(15);
    final buttonFontSize = responsive.fontSize(10);

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section - Fixed height
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: cardHeight * 0.55, // 55% of card height for image
                width: double.infinity,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.lightGrey,
                          child: Icon(Icons.image, size: responsive.iconSize(40)),
                        ),
                      )
                    : Container(
                        color: AppTheme.lightGrey,
                        child: Icon(Icons.image, size: responsive.iconSize(40)),
                      ),
              ),
            ),
            // Content Section - Fixed height with proper spacing
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(screenWidth < 360 ? 6.0 : 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section: Name and Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name - Fixed height to ensure visibility
                        SizedBox(
                          height: screenWidth < 360 ? 32 : 36,
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: screenWidth < 360 ? 2 : 4),
                        Text(
                          currencyFormat.format(product.price),
                          style: TextStyle(
                            fontSize: priceFontSize,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    // Bottom section: Quantity Selector (Blinkit Style) or Add Button
                    SizedBox(
                      width: double.infinity,
                      child: quantity > 0
                          ? _buildQuantitySelector(context, cartProvider, quantity, responsive, screenWidth)
                          : ElevatedButton(
                              onPressed: (product.isAvailable && product.stock > 0 && !isAdding)
                                  ? () async {
                                      await cartProvider.addItem(product);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: screenWidth < 360 ? 4 : 6),
                                backgroundColor: AppTheme.primaryGreen,
                                minimumSize: Size(0, screenWidth < 360 ? 26 : 28),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isAdding
                                  ? SizedBox(
                                      height: screenWidth < 360 ? 14 : 16,
                                      width: screenWidth < 360 ? 14 : 16,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      product.isAvailable && product.stock > 0
                                          ? 'Add'
                                          : 'Out of Stock',
                                      style: TextStyle(
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Blinkit-style quantity selector
  Widget _buildQuantitySelector(
    BuildContext context,
    CartProvider cartProvider,
    int quantity,
    Responsive responsive,
    double screenWidth,
  ) {
    final buttonSize = screenWidth < 360 ? 24.0 : 28.0;
    final iconSize = screenWidth < 360 ? 14.0 : 16.0;
    final fontSize = screenWidth < 360 ? 13.0 : 14.0;
    final canIncrement = quantity < product.stock && product.isAvailable;
    final canDecrement = quantity > 0; // Allow decrementing to 0 (removes item)

    return Container(
      height: screenWidth < 360 ? 28 : 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrement button
          GestureDetector(
            onTap: () async {
              if (quantity > 1) {
                await cartProvider.updateQuantity(product.id, quantity - 1);
              } else {
                // Remove item when quantity becomes 0
                await cartProvider.removeItem(product.id);
              }
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove,
                size: iconSize,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          // Quantity display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Increment button
          GestureDetector(
            onTap: canIncrement
                ? () async {
                    await cartProvider.updateQuantity(product.id, quantity + 1);
                  }
                : null,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: canIncrement ? Colors.white : Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: iconSize,
                color: canIncrement ? AppTheme.primaryGreen : AppTheme.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

