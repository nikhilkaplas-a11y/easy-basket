import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    // For products with variants, check if any variant is in cart
    final isInCart = product.hasVariants && product.variants != null && product.variants!.isNotEmpty
        ? product.variants!.any((v) => cartProvider.contains(product.id, variantId: v.id))
        : cartProvider.contains(product.id);
    final quantity = isInCart 
        ? (product.hasVariants && product.variants != null && product.variants!.isNotEmpty
            ? product.variants!.fold<int>(0, (sum, v) => sum + cartProvider.getQuantity(product.id, variantId: v.id))
            : cartProvider.getQuantity(product.id))
        : 0;
    final isAdding = cartProvider.isAddingItem(product.id);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final responsive = Responsive(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive font sizes - no fixed height, let grid control it
    final fontSize = screenWidth < 360 ? 11.0 : screenWidth < 400 ? 12.0 : 13.0;
    final nameFontSize = screenWidth < 360 ? 12.0 : screenWidth < 400 ? 13.0 : 14.0;
    final priceFontSize = screenWidth < 360 ? 14.0 : screenWidth < 400 ? 15.0 : 16.0;
    final buttonFontSize = screenWidth < 360 ? 10.0 : screenWidth < 400 ? 11.0 : 12.0;

    // Calculate discount percentage (if originalPrice exists, otherwise use placeholder)
    final discountPercent = _calculateDiscount();
    final hasDiscount = discountPercent > 0;
    
    // Get variant count
    final variantCount = product.hasVariants && product.variants != null 
        ? product.variants!.where((v) => v.isAvailable).length 
        : 0;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        // Remove fixed height - let grid's aspect ratio control it
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Image Section with Discount Badge - Use Expanded with flex
            Expanded(
              flex: 52, // 52% of available space
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.lightGrey,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.lightGrey,
                                child: Icon(Icons.image, size: responsive.iconSize(40), color: AppTheme.grey),
                              ),
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeOutDuration: const Duration(milliseconds: 100),
                            )
                          : Container(
                              color: AppTheme.lightGrey,
                              child: Icon(Icons.image, size: responsive.iconSize(40), color: AppTheme.grey),
                            ),
                    ),
                  ),
                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C831F), // Blinkit green
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${discountPercent.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content Section - Use Expanded with flex
            Expanded(
              flex: 48, // 48% of available space
              child: ClipRect(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 360 ? 4.0 : 6.0,
                    vertical: screenWidth < 360 ? 4.0 : 6.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name - Compact
                      _buildProductName(nameFontSize, screenWidth),
                      SizedBox(height: screenWidth < 360 ? 1 : 2),
                      // Weight/Unit Display
                      if (product.unit != null || (product.hasVariants && product.variants != null && product.variants!.isNotEmpty))
                        Text(
                          _getWeightDisplay(),
                          style: TextStyle(
                            fontSize: screenWidth < 360 ? 8 : 9,
                            color: AppTheme.grey,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: screenWidth < 360 ? 2 : 3),
                      // Price and ADD Button in same row (Blinkit style) - Saves space
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price on the left - Flexible to prevent overflow
                          Expanded(
                            child: _buildPriceDisplay(product, currencyFormat, priceFontSize, hasDiscount),
                          ),
                          SizedBox(width: screenWidth < 360 ? 2 : 3),
                          // ADD Button or Quantity Selector on the right - Flexible to prevent overflow
                          Flexible(
                            child: quantity > 0
                                ? _buildQuantitySelector(context, cartProvider, quantity, responsive, screenWidth)
                                : _buildAddButton(context, cartProvider, isAdding, buttonFontSize, screenWidth, variantCount),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  // Calculate discount percentage (placeholder - can be enhanced with originalPrice field)
  int _calculateDiscount() {
    // For now, return 0. In future, if product has originalPrice field:
    // if (product.originalPrice != null && product.originalPrice! > product.price) {
    //   return ((product.originalPrice! - product.price) / product.originalPrice! * 100).round();
    // }
    return 0; // Placeholder - no discount by default
  }

  // Build product name with brand extraction
  Widget _buildProductName(double fontSize, double screenWidth) {
    final name = product.name;
    // Try to extract brand name (first part before space or common patterns)
    String displayName = name;
    String? brandName;
    
    // Simple brand extraction (can be enhanced)
    final parts = name.split(' ');
    if (parts.length > 2) {
      // Assume first 2 words might be brand
      brandName = parts.take(2).join(' ');
      displayName = parts.skip(2).join(' ');
    } else if (parts.length > 1) {
      brandName = parts.first;
      displayName = parts.skip(1).join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (brandName != null)
          Text(
            brandName,
            style: TextStyle(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w500,
              color: AppTheme.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Flexible(
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.black,
              height: 1.15, // Tighter line height
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Get weight/unit display
  String _getWeightDisplay() {
    if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
      // Show first variant's label or range
      final availableVariants = product.variants!.where((v) => v.isAvailable).toList();
      if (availableVariants.isNotEmpty) {
        final firstVariant = availableVariants.first;
        if (availableVariants.length == 1) {
          return firstVariant.label;
        } else {
          // Show range
          availableVariants.sort((a, b) => a.quantity.compareTo(b.quantity));
          return '${availableVariants.first.label} - ${availableVariants.last.label}';
        }
      }
    }
    // Fallback to product unit
    if (product.unit != null) {
      return '1 ${product.unit}';
    }
    return '';
  }

  // Build price display with original price if discounted
  Widget _buildPriceDisplay(ProductModel product, NumberFormat currencyFormat, double fontSize, bool hasDiscount) {
    if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
      // Get available variants
      final availableVariants = product.variants!.where((v) => v.isAvailable).toList();
      if (availableVariants.isNotEmpty) {
        // Sort by price to get min and max
        availableVariants.sort((a, b) => a.price.compareTo(b.price));
        final minPrice = availableVariants.first.price;
        final maxPrice = availableVariants.last.price;
        
        // If all variants have same price, show single price
        if (minPrice == maxPrice) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currencyFormat.format(minPrice),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              if (hasDiscount)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currencyFormat.format(minPrice * 1.2), // Placeholder original price
                    style: TextStyle(
                      fontSize: fontSize - 3,
                      color: AppTheme.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          );
        }
        
        // Show price range
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${currencyFormat.format(minPrice)} - ${currencyFormat.format(maxPrice)}',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        );
      }
    }
    
    // No variants - show base price
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            currencyFormat.format(product.price),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        if (hasDiscount)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              currencyFormat.format(product.price * 1.2), // Placeholder original price
              style: TextStyle(
                fontSize: fontSize - 3,
                color: AppTheme.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );
  }

  // Build ADD button with Blinkit style - Positioned on the side (bottom-right)
  Widget _buildAddButton(
    BuildContext context,
    CartProvider cartProvider,
    bool isAdding,
    double buttonFontSize,
    double screenWidth,
    int variantCount,
  ) {
    final isAvailable = product.isAvailable && 
        ((product.hasVariants && product.variants != null && product.variants!.any((v) => v.isAvailable && v.stock > 0)) ||
         (!product.hasVariants && product.stock > 0));
    
    // Calculate button width based on content - Compact for small cards
    final buttonWidth = variantCount > 1 
        ? (screenWidth < 360 ? 46.0 : 50.0)
        : (screenWidth < 360 ? 40.0 : 46.0);
    final buttonHeight = screenWidth < 360 ? 20.0 : 24.0;
    
    return Container(
      width: buttonWidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        color: isAvailable && !isAdding ? AppTheme.primaryGreen : AppTheme.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isAvailable && !isAdding)
              ? () async {
                  // For products with variants, navigate to detail page to select variant
                  // For products without variants, add directly to cart
                  if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
                    context.push('/product/${product.id}');
                  } else {
                    await cartProvider.addItem(product);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: isAdding
                ? SizedBox(
                    height: screenWidth < 360 ? 12 : 14,
                    width: screenWidth < 360 ? 12 : 14,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : variantCount > 1
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ADD',
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 9 : 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 0),
                          Text(
                            '$variantCount options',
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 7 : 8,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                              height: 1.0,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        (product.hasVariants && product.variants != null && product.variants!.any((v) => v.isAvailable && v.stock > 0)) ||
                        (!product.hasVariants && product.isAvailable && product.stock > 0)
                            ? 'ADD'
                            : 'Out of Stock',
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  // Blinkit-style quantity selector - Positioned on the side, Compact to prevent overflow
  Widget _buildQuantitySelector(
    BuildContext context,
    CartProvider cartProvider,
    int quantity,
    Responsive responsive,
    double screenWidth,
  ) {
    final buttonSize = screenWidth < 360 ? 15.0 : 17.0;
    final iconSize = screenWidth < 360 ? 10.0 : 11.0;
    final fontSize = screenWidth < 360 ? 9.0 : 10.0;
    // For products with variants, we can't increment from card - need to go to detail page
    final canIncrement = !product.hasVariants && quantity < product.stock && product.isAvailable;
    final canDecrement = quantity > 0;
    
    return Container(
      height: screenWidth < 360 ? 20 : 24,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          GestureDetector(
            onTap: () async {
              // For products with variants, navigate to detail page
              if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
                context.push('/product/${product.id}');
                return;
              }
              
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
              margin: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
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
          // Quantity display - Compact padding
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 4 : 5),
            constraints: BoxConstraints(minWidth: 16),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Increment button
          GestureDetector(
            onTap: canIncrement
                ? () async {
                    // For products with variants, navigate to detail page
                    if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
                      context.push('/product/${product.id}');
                      return;
                    }
                    await cartProvider.updateQuantity(product.id, quantity + 1);
                  }
                : (product.hasVariants && product.variants != null && product.variants!.isNotEmpty)
                    ? () => context.push('/product/${product.id}')
                    : null,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              margin: const EdgeInsets.all(1.5),
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
      ),
    );
  }
}
