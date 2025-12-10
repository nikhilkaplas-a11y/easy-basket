import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
        appBar: AppBar(
          title: const Text('Cart'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 100, color: AppTheme.grey),
              SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.grey,
                  fontFamily: 'RoundedSans',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartProvider.items.length,
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: item.product.imageUrl != null
                        ? Image.network(
                            item.product.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image),
                          )
                        : const Icon(Icons.image),
                    title: Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                    subtitle: Text(
                      currencyFormat.format(item.product.price),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (item.quantity > 1) {
                              cartProvider.updateQuantity(
                                  item.product.id, item.quantity - 1);
                            } else {
                              cartProvider.removeItem(item.product.id);
                            }
                          },
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: item.quantity < item.product.stock
                              ? () {
                                  cartProvider.updateQuantity(
                                      item.product.id, item.quantity + 1);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(Responsive(context).spacing(16)),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: Responsive(context).fontSize(20),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                    Flexible(
                      child: Text(
                        currencyFormat.format(cartProvider.totalAmount),
                        style: TextStyle(
                          fontSize: Responsive(context).fontSize(24),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          fontFamily: 'RoundedSans',
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive(context).spacing(16)),
                // Show warning if no address
                if (!hasAddress && authProvider.isAuthenticated)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_off,
                          color: Colors.orange.shade700,
                          size: 24,
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
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please add a delivery address to proceed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!authProvider.isAuthenticated) {
                        context.go('/login');
                      } else if (!hasAddress) {
                        // Show message and navigate to add address
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!hasAddress && authProvider.isAuthenticated)
                          ? Colors.grey
                          : AppTheme.primaryGreen,
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive(context).spacing(16),
                      ),
                    ),
                    child: Text(
                      !authProvider.isAuthenticated
                          ? 'Login to Checkout'
                          : !hasAddress
                              ? 'Add Address to Checkout'
                              : 'Proceed to Checkout',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

