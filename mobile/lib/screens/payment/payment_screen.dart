import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/razorpay_service.dart';
import '../../utils/theme.dart';
import 'payment_status_screen.dart';
import 'package:intl/intl.dart';

// Conditional import for Razorpay types
import 'package:razorpay_flutter/razorpay_flutter.dart' if (dart.library.html) '../../services/razorpay_web_stub.dart';

class PaymentScreen extends StatefulWidget {
  final int? addressId;

  const PaymentScreen({super.key, this.addressId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  String _selectedPaymentMethod = 'razorpay';
  final _notesController = TextEditingController();
  bool _isProcessingPayment = false;
  DateTime? _paymentStartTime;
  int? _currentOrderId; // Store the order ID we're processing

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Set up Razorpay callbacks (only for mobile)
    if (!kIsWeb) {
      RazorpayService.onSuccess = _handlePaymentSuccess;
      RazorpayService.onError = _handlePaymentError;
      RazorpayService.onExternalWallet = _handleExternalWallet;
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app comes back to foreground after payment
    if (state == AppLifecycleState.resumed && _isProcessingPayment) {
      // Check if we've been processing for more than 5 seconds
      if (_paymentStartTime != null) {
        final duration = DateTime.now().difference(_paymentStartTime!);
        if (duration.inSeconds > 5) {
          // App returned but callback didn't fire - check orders
          _checkPaymentStatus();
        }
      }
    }
  }
  
  Future<void> _checkPaymentStatus() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    if (authProvider.token == null) return;
    
    try {
      // Refresh orders to see if payment went through
      await orderProvider.fetchOrders(authProvider.token!);
      
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _paymentStartTime = null;
        });
        
        // Navigate to payment status page (pending - check orders)
        if (mounted) {
          context.go('/payment/status', extra: {
            'status': PaymentStatus.pending,
            'message': 'Please check your orders to confirm payment status.',
            'orderId': null,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _paymentStartTime = null;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notesController.dispose();
    // Reset loading state before disposing
    if (_isProcessingPayment) {
      _isProcessingPayment = false;
    }
    _currentOrderId = null; // Clear stored order ID
    RazorpayService.clear();
    // Clear callbacks to prevent memory leaks
    RazorpayService.onSuccess = null;
    RazorpayService.onError = null;
    RazorpayService.onExternalWallet = null;
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    
    // Immediately reset loading state
    if (mounted) {
      setState(() => _isProcessingPayment = false);
    }
    
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Show processing message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifying payment...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

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

    // Get order ID from stored state (we stored it when opening Razorpay)
    int? orderId = _currentOrderId;

    if (orderId == null) {
      // If order ID is not in state, try to extract from Razorpay orderId
      // Razorpay order ID format might be "ORDER_123" (our format) or "order_ABC123" (Razorpay format)
      final orderIdStr = response.orderId;
      if (orderIdStr != null && orderIdStr.isNotEmpty) {
        if (orderIdStr.contains('_')) {
          final parts = orderIdStr.split('_');
          // Check if it's our format "ORDER_123"
          if (parts.length >= 2 && parts[0].toUpperCase() == 'ORDER') {
            orderId = int.tryParse(parts.last);
          }
        } else {
          // Try parsing as direct number
          orderId = int.tryParse(orderIdStr);
        }
      }
    }

    if (orderId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to identify order. Please check your orders.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        // Instead of going back, go to orders page
        context.go('/orders');
      }
      return;
    }

    final paymentId = response.paymentId ?? '';
      final signature = response.signature ?? '';
      final razorpayOrderId = response.orderId ?? ''; // This is Razorpay's order ID

      if (paymentId.isEmpty || signature.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid payment response. Missing payment details.'),
              backgroundColor: Colors.red,
            ),
          );
          context.go('/orders'); // Go to orders instead of back
        }
        return;
      }

    try {
      // Verify payment with backend
      final verified = await RazorpayService.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        razorpayOrderId: razorpayOrderId, // Use Razorpay's order ID
        token: authProvider.token!,
      );

      if (verified) {
        // Refresh orders before navigating
        await orderProvider.fetchOrders(authProvider.token!);
        
        if (mounted) {
          // Navigate to payment status page FIRST (before clearing cart to avoid showing zero)
          context.go('/payment/status', extra: {
            'status': PaymentStatus.success,
            'message': 'Payment successful! Your order has been placed.',
            'orderId': orderId,
          });
          
          // Clear cart AFTER navigation to avoid showing zero value during redirect
          // Use post-frame callback to ensure navigation completes first
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cartProvider.clear();
          });
        }
      } else {
        if (mounted) {
          // Navigate to payment status page with failure
          context.go('/payment/status', extra: {
            'status': PaymentStatus.failed,
            'message': 'Payment verification failed. Please contact support or try again.',
            'orderId': orderId,
          });
        }
      }
    } catch (e) {
      // Ensure loading state is reset on error
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        // Navigate to payment status page with error
        context.go('/payment/status', extra: {
          'status': PaymentStatus.failed,
          'message': 'Error processing payment: ${e.toString()}',
          'orderId': _currentOrderId,
        });
      }
    } finally {
      // Always reset loading state
      if (mounted && _isProcessingPayment) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    
    setState(() => _isProcessingPayment = false);
    
    if (mounted) {
      // Navigate to payment status page with failure
      context.go('/payment/status', extra: {
        'status': PaymentStatus.failed,
        'message': 'Payment failed: ${response.message ?? 'Unknown error'}',
        'orderId': _currentOrderId,
      });
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

    final items = cartProvider.items.map((item) {
      final itemMap = <String, dynamic>{
        'productId': item.product.id,
        'quantity': item.quantity,
      };
      // Include variantId if item has a variant
      if (item.variant != null) {
        itemMap['variantId'] = item.variant!.id;
      }
      return itemMap;
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
      // For COD, show order confirmation (not payment success)
      if (mounted) {
        // Refresh orders before navigating
        await orderProvider.fetchOrders(authProvider.token!);
        
        // Navigate to order confirmation page (not payment status)
        // Use orderPlaced status to show appropriate UI
        if (mounted) {
          context.go('/payment/status', extra: {
            'status': PaymentStatus.orderPlaced, // Use orderPlaced instead of success
            'message': 'Your order has been placed successfully! Please keep cash ready for delivery.',
            'orderId': order.id,
          });
          
          // Clear cart AFTER navigation to avoid showing zero value during redirect
          // Use post-frame callback to ensure navigation completes first
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cartProvider.clear();
          });
        }
      }
    }
  }

  Future<void> _processRazorpayPayment(int orderId, double amount, String token) async {
    if (!mounted) return;
    
    setState(() {
      _isProcessingPayment = true;
      _paymentStartTime = DateTime.now();
    });

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

      // Store order ID in state for payment callback
      setState(() {
        _currentOrderId = orderId;
      });

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
          'internalOrderId': orderId.toString(), // Store in multiple places for reliability
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...cartProvider.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Text(
                                '${item.product.name} x ${item.quantity}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currencyFormat.format(item.total),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
                        ),
                      ),
                      Text(
                        currencyFormat.format(cartProvider.totalAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
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

