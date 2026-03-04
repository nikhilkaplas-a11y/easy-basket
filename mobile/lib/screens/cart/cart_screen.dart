import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/theme.dart';
import '../../utils/responsive.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final hasAddress = orderProvider.addresses.isNotEmpty;

    if (cartProvider.items.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.lightGrey,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.white,
          iconTheme: const IconThemeData(color: AppTheme.black),
          title: const Text(
            'My Cart',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'RoundedSans',
              color: AppTheme.black,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.black),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.15),
                      AppTheme.primaryGreen.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 100,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                  fontFamily: 'RoundedSans',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add items to your cart to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.grey,
                  fontFamily: 'RoundedSans',
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.shopping_bag_rounded, size: 22),
                label: const Text(
                  'Start Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'RoundedSans',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.black),
        title: Text(
          'My Cart (${cartProvider.itemCount} ${cartProvider.itemCount == 1 ? 'item' : 'items'})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'RoundedSans',
            color: AppTheme.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // Cart Items List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh cart if needed
              },
              color: AppTheme.primaryGreen,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cartProvider.items.length,
                itemBuilder: (context, index) {
                  final item = cartProvider.items[index];
                  return _buildCartItem(context, item, cartProvider, currencyFormat);
                },
              ),
            ),
          ),
          // Bottom Checkout Section - Fixed with SafeArea
          _buildCheckoutSection(
            context,
            cartProvider,
            authProvider,
            hasAddress,
            currencyFormat,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    dynamic item,
    CartProvider cartProvider,
    NumberFormat currencyFormat,
  ) {
    final responsive = Responsive(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.product.imageUrl!,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 90,
                        height: 90,
                        color: AppTheme.lightGrey,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 90,
                        height: 90,
                        color: AppTheme.lightGrey,
                        child: Icon(
                          Icons.image,
                          color: AppTheme.grey,
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: AppTheme.lightGrey,
                      child: Icon(
                        Icons.image,
                        color: AppTheme.grey,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'RoundedSans',
                      color: AppTheme.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Show variant label if present
                  if (item.variant != null) ...[
                    Text(
                      item.variant!.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.grey,
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    currencyFormat.format(item.variant?.price ?? item.product.price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.variant != null 
                        ? 'Per ${item.variant!.unit}'
                        : (item.product.unit != null ? 'Per ${item.product.unit}' : ''),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quantity Selector (Blinkit-style)
                  _buildQuantitySelector(context, item, cartProvider),
                ],
              ),
            ),
            // Remove Button
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.withOpacity(0.7),
                size: 22,
              ),
              onPressed: () {
                _showRemoveDialog(context, item, cartProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(
    BuildContext context,
    dynamic item,
    CartProvider cartProvider,
  ) {
    final quantity = item.quantity;
    final maxStock = item.variant?.stock ?? item.product.stock;
    final canIncrement = quantity < maxStock && (item.variant?.isAvailable ?? item.product.isAvailable);
    final buttonSize = 28.0;

    return Container(
      width: 110,
      height: 32,
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
                await cartProvider.updateQuantity(
                  item.product.id, 
                  quantity - 1,
                  variantId: item.variant?.id,
                );
              } else {
                await cartProvider.removeItem(
                  item.product.id,
                  variantId: item.variant?.id,
                );
              }
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              margin: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          // Quantity display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Increment button
          GestureDetector(
            onTap: canIncrement
                ? () async {
                    await cartProvider.updateQuantity(
                      item.product.id, 
                      quantity + 1,
                      variantId: item.variant?.id,
                    );
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
                size: 16,
                color: canIncrement ? AppTheme.primaryGreen : AppTheme.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, dynamic item, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Remove Item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'RoundedSans',
          ),
        ),
        content: Text(
          'Remove ${item.product.name}${item.variant != null ? " (${item.variant!.label})" : ""} from cart?',
          style: const TextStyle(
            fontFamily: 'RoundedSans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.grey,
                fontFamily: 'RoundedSans',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.removeItem(item.product.id, variantId: item.variant?.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.product.name} removed from cart'),
                  backgroundColor: AppTheme.primaryGreen,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Remove',
              style: TextStyle(
                fontFamily: 'RoundedSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(
    BuildContext context,
    CartProvider cartProvider,
    AuthProvider authProvider,
    bool hasAddress,
    NumberFormat currencyFormat,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Breakdown
              _buildPriceRow('Subtotal', cartProvider.totalAmount, currencyFormat, false),
              const SizedBox(height: 8),
              _buildPriceRow('Delivery Fee', 0, currencyFormat, false, isFree: true),
              const Divider(height: 24),
              _buildPriceRow('Total', cartProvider.totalAmount, currencyFormat, true),
              const SizedBox(height: 20),
              // Address Warning
              if (!hasAddress && authProvider.isAuthenticated)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        color: Colors.orange.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery address required',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                                fontFamily: 'RoundedSans',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add address to proceed with checkout',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade600,
                                fontFamily: 'RoundedSans',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!authProvider.isAuthenticated) {
                      context.go('/login');
                    } else if (!hasAddress) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.location_off, color: Colors.white),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Please add a delivery address first'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      context.push('/address/add');
                    } else {
                      context.push('/addresses');
                    }
                  },
                  icon: Icon(
                    !authProvider.isAuthenticated
                        ? Icons.login_rounded
                        : !hasAddress
                            ? Icons.location_on_rounded
                            : Icons.shopping_cart_checkout_rounded,
                    size: 22,
                  ),
                  label: Text(
                    !authProvider.isAuthenticated
                        ? 'Login to Checkout'
                        : !hasAddress
                            ? 'Add Address to Checkout'
                            : 'Proceed to Checkout',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (!hasAddress && authProvider.isAuthenticated)
                        ? Colors.grey
                        : AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    NumberFormat currencyFormat,
    bool isTotal, {
    bool isFree = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: AppTheme.black,
            fontFamily: 'RoundedSans',
          ),
        ),
        Text(
          isFree ? 'FREE' : currencyFormat.format(amount),
          style: TextStyle(
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.primaryGreen : AppTheme.black,
            fontFamily: 'RoundedSans',
          ),
        ),
      ],
    );
  }
}
