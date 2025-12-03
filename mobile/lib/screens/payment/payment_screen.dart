import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/razorpay_service.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

// Conditional import for Razorpay types
import 'package:razorpay_flutter/razorpay_flutter.dart' if (dart.library.html) '../../services/razorpay_web_stub.dart';

class PaymentScreen extends StatefulWidget {
  final int? addressId;

  const PaymentScreen({super.key, this.addressId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'razorpay';
  final _notesController = TextEditingController();
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    // Set up Razorpay callbacks (only for mobile)
    if (!kIsWeb) {
      RazorpayService.onSuccess = _handlePaymentSuccess;
      RazorpayService.onError = _handlePaymentError;
      RazorpayService.onExternalWallet = _handleExternalWallet;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    RazorpayService.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    
    setState(() => _isProcessingPayment = false);
    
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue.'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/login');
      }
      return;
    }

    // Extract order ID from response
    final orderIdStr = response.orderId;
    if (orderIdStr == null || orderIdStr.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid payment response. Missing order ID.'),
            backgroundColor: Colors.red,
          ),
        );
        // Pop payment screen to go back
        context.pop();
      }
      return;
    }

    // Try to extract order ID - handle both "ORDER_123" and "123" formats
    int? orderId;
    if (orderIdStr.contains('_')) {
      final parts = orderIdStr.split('_');
      final lastPart = parts.last;
      orderId = int.tryParse(lastPart);
    } else {
      orderId = int.tryParse(orderIdStr);
    }

    if (orderId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid payment response. Invalid order ID format.'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
      return;
    }

    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    if (paymentId.isEmpty || signature.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid payment response. Missing payment details.'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
      return;
    }

    try {
      // Verify payment with backend
      final verified = await RazorpayService.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        razorpayOrderId: orderIdStr,
        token: authProvider.token!,
      );

      if (verified) {
        cartProvider.clear();
        // Refresh orders before navigating
        await orderProvider.fetchOrders(authProvider.token!);
        
        if (mounted) {
          // Pop payment screen first, then navigate to orders
          context.pop();
          // Small delay to ensure navigation completes
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            context.go('/orders');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Order placed.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verification failed. Please contact support.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          // Pop payment screen even if verification failed
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        context.pop();
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    
    setState(() => _isProcessingPayment = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      // Don't pop - let user try again or go back manually
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final addressId = widget.addressId;
    if (addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address')),
      );
      return;
    }

    final items = cartProvider.items.map((item) => {
      'productId': item.product.id,
      'quantity': item.quantity,
    }).toList();

    // First create the order in our system
    final order = await orderProvider.createOrder(
      token: authProvider.token!,
      items: items,
      addressId: addressId,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (order == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orderProvider.error ?? 'Failed to create order')),
        );
      }
      return;
    }

    // Handle payment based on method
    if (_selectedPaymentMethod == 'razorpay') {
      if (kIsWeb) {
        // Web platform - show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Online payment is currently available on mobile app only. Please use Cash on Delivery or test on Android/iOS.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      await _processRazorpayPayment(order.id, cartProvider.totalAmount, authProvider.token!);
    } else if (_selectedPaymentMethod == 'cash') {
      // Cash on Delivery - order already created
      if (mounted) {
        cartProvider.clear();
        // Refresh orders before navigating
        await orderProvider.fetchOrders(authProvider.token!);
        // Small delay to ensure state is updated
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          context.go('/orders');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully! Pay on delivery.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _processRazorpayPayment(int orderId, double amount, String token) async {
    setState(() => _isProcessingPayment = true);

    try {
      // Create Razorpay order
      final razorpayOrder = await RazorpayService.createOrder(
        amount: amount,
        orderId: orderId,
        token: token,
      );

      if (razorpayOrder == null) {
        setState(() => _isProcessingPayment = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initialize payment. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Extract values with null safety
      final keyId = razorpayOrder['key'] as String?;
      final razorpayOrderId = razorpayOrder['razorpayOrderId'] as String?;

      if (keyId == null || razorpayOrderId == null) {
        setState(() => _isProcessingPayment = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid payment response. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      // Open Razorpay checkout
      RazorpayService.openCheckout(
        keyId: keyId,
        amount: amount,
        orderId: razorpayOrderId,
        name: 'Easy Basket',
        description: 'Grocery Order #$orderId',
        prefillEmail: user?.email,
        prefillContact: user?.phoneNumber,
        notes: {
          'orderId': orderId.toString(),
        },
      );
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...cartProvider.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.product.name} x ${item.quantity}'),
                            Text(currencyFormat.format(item.total)),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RoundedSans',
                        ),
                      ),
                      Text(
                        currencyFormat.format(cartProvider.totalAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          fontFamily: 'RoundedSans',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Payment Method
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'RoundedSans',
            ),
          ),
          const SizedBox(height: 16),
          RadioListTile<String>(
            title: const Text('Online Payment (Razorpay)'),
            subtitle: const Text('Cards, UPI, Wallets, Netbanking'),
            value: 'razorpay',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
          ),
          RadioListTile<String>(
            title: const Text('Cash on Delivery'),
            subtitle: const Text('Pay when you receive'),
            value: 'cash',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
          ),
          const SizedBox(height: 24),
          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Delivery Notes (Optional)',
              hintText: 'Any special instructions...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          Consumer<OrderProvider>(
            builder: (context, orderProvider, _) => ElevatedButton(
              onPressed: (orderProvider.isLoading || _isProcessingPayment) ? null : _placeOrder,
              child: (orderProvider.isLoading || _isProcessingPayment)
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _selectedPaymentMethod == 'razorpay' ? 'Pay & Place Order' : 'Place Order',
                  ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

