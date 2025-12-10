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
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        width: double.infinity,
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
            Flexible(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(screenWidth < 360 ? 6.0 : 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
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
                    SizedBox(height: screenWidth < 360 ? 2 : 4),
                    // Always show price and button - don't hide details
                    SizedBox(
                      width: double.infinity,
                      child: isInCart
                          ? OutlinedButton.icon(
                              onPressed: () => context.push('/cart'),
                              icon: Icon(Icons.check, size: responsive.iconSize(12)),
                              label: Text('In Cart', style: TextStyle(fontSize: buttonFontSize)),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth < 360 ? 4 : 6,
                                  vertical: screenWidth < 360 ? 4 : 6,
                                ),
                                minimumSize: Size(0, screenWidth < 360 ? 26 : 28),
                                side: const BorderSide(color: AppTheme.primaryGreen),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: (product.isAvailable && product.stock > 0 && !isAdding)
                                  ? () async {
                                      await cartProvider.addItem(product);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${product.name} added to cart'),
                                            duration: const Duration(seconds: 1),
                                            backgroundColor: AppTheme.primaryGreen,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: screenWidth < 360 ? 4 : 6),
                                backgroundColor: AppTheme.primaryGreen,
                                minimumSize: Size(0, screenWidth < 360 ? 26 : 28),
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
                                          ? 'Add to Cart'
                                          : 'Out of Stock',
                                      style: TextStyle(fontSize: buttonFontSize),
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
}

