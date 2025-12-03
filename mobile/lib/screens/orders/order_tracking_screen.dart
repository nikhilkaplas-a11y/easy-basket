import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrderIfNeeded();
    });
  }

  void _fetchOrderIfNeeded() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if order already exists in the list
    final orderExists = orderProvider.orders.any((o) => o.id == widget.orderId);
    
    if (!orderExists && authProvider.token != null) {
      if (kDebugMode) {
        print('🔄 Fetching order ${widget.orderId}...');
      }
      orderProvider.fetchOrderById(widget.orderId, authProvider.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    // Find order from list
    final order = orderProvider.orders.where((o) => o.id == widget.orderId).firstOrNull;

    // If order not found, show loading and fetch it
    if (order == null) {
      if (!_hasFetched) {
        _hasFetched = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchOrderIfNeeded();
        });
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _getStatusColor(order.status).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _getStatusIcon(order.status),
                      size: 60,
                      color: _getStatusColor(order.status),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.statusText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(order.status),
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Order Items
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'RoundedSans',
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: item.product.imageUrl != null
                        ? Image.network(
                            item.product.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image),
                          )
                        : const Icon(Icons.image),
                    title: Text(item.product.name),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text(
                      currencyFormat.format(item.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 24),
            // Delivery Address
            const Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'RoundedSans',
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  order.deliveryAddress.fullAddress,
                  style: const TextStyle(
                    fontFamily: 'RoundedSans',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Order Details
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'RoundedSans',
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Order ID', '#${order.id}'),
                    _buildDetailRow('Order Date', formatISTDefault(order.createdAt)),
                    _buildDetailRow('Payment Method', order.paymentMethod ?? 'N/A'),
                    _buildDetailRow('Payment Status', order.isPaid ? 'Paid' : 'Pending'),
                    const Divider(),
                    _buildDetailRow(
                      'Total Amount',
                      currencyFormat.format(order.totalAmount),
                      isBold: true,
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey,
              fontFamily: 'RoundedSans',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'RoundedSans',
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'preparing':
        return Colors.blue;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return AppTheme.primaryGreen;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
      case 'preparing':
        return Icons.restaurant;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

