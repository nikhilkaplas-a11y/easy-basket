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
              flex: 55, // 55% of available space (reduced from 60% to give more space to content)
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
            // Content Section - Use Expanded with flex (increased to ensure product name is visible)
            Expanded(
              flex: 45, // 45% of available space (increased from 40% to ensure product name visibility)
              child: ClipRect(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 360 ? 4.0 : 5.0,
                    vertical: screenWidth < 360 ? 3.0 : 4.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product Name - Must be visible with proper ellipsis (Blinkit style)
                      Expanded(
                        flex: 2, // Give more space to product name
                        child: _buildProductName(nameFontSize, screenWidth),
                      ),
                      SizedBox(height: screenWidth < 360 ? 0.5 : 1),
                      // Weight/Unit Display - Optional, can be removed if space is tight
                      if (product.unit != null || (product.hasVariants && product.variants != null && product.variants!.isNotEmpty))
                        Flexible(
                          child: Text(
                            _getWeightDisplay(),
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 7.5 : 8.5,
                              color: AppTheme.grey,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(height: screenWidth < 360 ? 1 : 2),
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

  // Build product name - Consistent dark color (Blinkit style) with proper ellipsis
  Widget _buildProductName(double fontSize, double screenWidth) {
    final name = product.name;

    return Text(
      name,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppTheme.black,
        height: 1.1, // Tighter line height for better fit
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      softWrap: true, // Enable text wrapping
    );
  }

  // Get weight/unit display
  String _getWeightDisplay() {
    if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
      final availableVariants = product.variants!.where((v) => v.isAvailable).toList();
      if (availableVariants.isNotEmpty) {
        availableVariants.sort((a, b) {
          final priceComp = a.price.compareTo(b.price);
          if (priceComp != 0) return priceComp;
          return a.quantity.compareTo(b.quantity);
        });
        return availableVariants.first.label;
      }
    }
    // No variants: try to infer quantity from product name "(...)" or minQuantity
    final name = product.name;
    final bracketMatch = RegExp(r'\(([^)]+)\)$').firstMatch(name);
    if (bracketMatch != null) {
      final content = bracketMatch.group(1)!.trim();
      if (content.isNotEmpty) return content;
    }
    if (product.minQuantity != null && product.unit != null) {
      final q = product.minQuantity!;
      final qStr = q % 1 == 0 ? q.toInt().toString() : q.toString();
      return '$qStr ${product.unit}';
    }
    if (product.unit != null) return '1 ${product.unit}';
    return '';
  }

  // Build price display with original price if discounted
  Widget _buildPriceDisplay(ProductModel product, NumberFormat currencyFormat, double fontSize, bool hasDiscount) {
    if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
      // Get available variants
      final availableVariants = product.variants!.where((v) => v.isAvailable).toList();
      if (availableVariants.isNotEmpty) {
        // Sort by price to get min
        availableVariants.sort((a, b) => a.price.compareTo(b.price));
        final minPrice = availableVariants.first.price;
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
                  currencyFormat.format(minPrice * 1.2),
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
    
    // Make ADD button larger to reduce empty space
    final buttonWidth = variantCount > 1 
        ? (screenWidth < 360 ? 68.0 : 78.0)
        : (screenWidth < 360 ? 64.0 : 74.0);
    final buttonHeight = screenWidth < 360 ? 30.0 : 34.0;
    
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
                  if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
                    final availableVariants = product.variants!
                        .where((v) => v.isAvailable && v.stock > 0)
                        .toList();
                    if (availableVariants.length == 1) {
                      await cartProvider.addItem(product, variant: availableVariants.first);
                    } else {
                      await _showVariantBottomSheet(context);
                    }
                  } else {
                    await cartProvider.addItem(product);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(6),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: isAdding
            ? SizedBox(
                height: screenWidth < 360 ? 14 : 16,
                width: screenWidth < 360 ? 14 : 16,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : variantCount > 1
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: screenWidth < 360 ? 11 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$variantCount options',
                          style: TextStyle(
                            fontSize: screenWidth < 360 ? 8.5 : 9.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    (product.hasVariants && product.variants != null && product.variants!.any((v) => v.isAvailable && v.stock > 0)) ||
                    (!product.hasVariants && product.isAvailable && product.stock > 0)
                        ? 'ADD'
                        : 'Out of Stock',
                    style: TextStyle(
                      fontSize: screenWidth < 360 ? 12 : 13,
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
    final variantCount = product.hasVariants && product.variants != null
        ? product.variants!.where((v) => v.isAvailable).length
        : 0;
    final buttonSize = screenWidth < 360 ? 15.0 : 17.0;
    final iconSize = screenWidth < 360 ? 10.0 : 11.0;
    final fontSize = screenWidth < 360 ? 9.0 : 10.0;
    // For products with variants, we can't increment from card - need to go to detail page
    final canIncrement = (!product.hasVariants && quantity < product.stock && product.isAvailable) ||
        (product.hasVariants && variantCount == 1);
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
              if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
                if (variantCount > 1) {
                  await _showVariantBottomSheet(context);
                  return;
                }
                // Single variant: update directly
                final v = product.variants!.firstWhere((vv) => vv.isAvailable, orElse: () => product.variants!.first);
                if (quantity > 1) {
                  await cartProvider.updateQuantity(product.id, quantity - 1, variantId: v.id);
                } else {
                  await cartProvider.removeItem(product.id, variantId: v.id);
                }
              } else {
                if (quantity > 1) {
                  await cartProvider.updateQuantity(product.id, quantity - 1);
                } else {
                  // Remove item when quantity becomes 0
                  await cartProvider.removeItem(product.id);
                }
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
                    if (product.hasVariants && product.variants != null && product.variants!.isNotEmpty) {
                      if (variantCount > 1) {
                        await _showVariantBottomSheet(context);
                        return;
                      }
                      // Single variant: update directly
                      final v = product.variants!.firstWhere((vv) => vv.isAvailable, orElse: () => product.variants!.first);
                      await cartProvider.updateQuantity(product.id, quantity + 1, variantId: v.id);
                    } else {
                      await cartProvider.updateQuantity(product.id, quantity + 1);
                    }
                  }
                : (product.hasVariants && product.variants != null && product.variants!.isNotEmpty)
                    ? () async => _showVariantBottomSheet(context)
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

  Future<void> _showVariantBottomSheet(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final variants = (product.variants ?? [])
        .where((v) => v.isAvailable)
        .toList()
      ..sort((a, b) {
        final priceComp = a.price.compareTo(b.price);
        if (priceComp != 0) return priceComp;
        return a.displayOrder.compareTo(b.displayOrder);
      });

    if (variants.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final titleStyle = TextStyle(
          fontSize: screenWidth < 360 ? 14 : 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.black,
        );
        final labelStyle = TextStyle(
          fontSize: screenWidth < 360 ? 12 : 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.black,
        );
        final priceStyle = TextStyle(
          fontSize: screenWidth < 360 ? 13 : 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.black,
        );
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: titleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (context, index) {
                      final v = variants[index];
                      final available = v.stock > 0 && v.isAvailable;
                      return Consumer<CartProvider>(
                        builder: (context, cp, _) {
                          final qty = cp.getQuantity(product.id, variantId: v.id);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.lightGrey),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    v.label,
                                    style: labelStyle,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Text(
                                    currencyFormat.format(v.price),
                                    style: priceStyle,
                                  ),
                                ),
                                if (qty > 0 && available)
                                  Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            if (qty > 1) {
                                              await cp.updateQuantity(product.id, qty - 1, variantId: v.id);
                                            } else {
                                              await cp.removeItem(product.id, variantId: v.id);
                                            }
                                          },
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            margin: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.remove, size: 14, color: AppTheme.primaryGreen),
                                          ),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 20),
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: const DefaultTextStyle(
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            child: Text(''),
                                          ),
                                        ),
                                        Container(
                                          constraints: const BoxConstraints(minWidth: 20),
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            qty.toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            if (qty < v.stock) {
                                              await cp.updateQuantity(product.id, qty + 1, variantId: v.id);
                                            }
                                          },
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            margin: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.add, size: 14, color: AppTheme.primaryGreen),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: available
                                          ? () async {
                                              await cp.addItem(product, variant: v);
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: available ? AppTheme.primaryGreen : AppTheme.grey.withOpacity(0.3),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        textStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth < 360 ? 12 : 13,
                                        ),
                                      ),
                                      child: Text(available ? 'ADD' : 'Out of Stock'),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: variants.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
