import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
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
    
    final orderExists = orderProvider.orders.any((o) => o.id == widget.orderId);
    
    if (!orderExists && authProvider.accessToken != null) {
      if (kDebugMode) {
        print('🔄 Fetching order ${widget.orderId}...');
      }
      orderProvider.fetchOrderById(widget.orderId, authProvider.accessToken!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context); // Listen to changes
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final order = orderProvider.orders.where((o) => o.id == widget.orderId).firstOrNull;

    // Fetch order if not found and not already fetching
    if (order == null && !_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchOrderIfNeeded();
      });
    }

    // Show loading state if order is not found and provider is loading
    if (order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
              const SizedBox(height: 16),
              Text(
                orderProvider.isLoading ? 'Loading order details...' : 'Order not found',
                style: TextStyle(
                  fontSize: 16,
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
      backgroundColor: AppTheme.white, // Changed from lightGrey.withOpacity(0.3) to white
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.black),
        title: Text(
          'Order #${order.id}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'RoundedSans',
            color: AppTheme.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        color: AppTheme.white, // Clean white background instead of grey
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16), // Add bottom padding
          child: Column(
            children: [
              // Status Header Card
              _buildStatusHeader(order),
              const SizedBox(height: 12),
              // Order Timeline
              _buildOrderTimeline(order),
              const SizedBox(height: 12),
              // Order Items
              _buildOrderItems(order, currencyFormat),
              const SizedBox(height: 12),
              // Delivery Address
              _buildDeliveryAddress(order),
              const SizedBox(height: 12),
              // Payment & Order Summary
              _buildPaymentSummary(order, currencyFormat),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.12),
            statusColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              statusIcon,
              size: 48,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            order.statusText,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: statusColor,
              fontFamily: 'RoundedSans',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(order.status),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey,
              fontFamily: 'RoundedSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(OrderModel order) {
    final statuses = [
      {'key': 'pending', 'label': 'Order Placed', 'icon': Icons.shopping_cart},
      {'key': 'accepted', 'label': 'Order Accepted', 'icon': Icons.check_circle_outline},
      {'key': 'preparing', 'label': 'Preparing', 'icon': Icons.restaurant},
      {'key': 'out_for_delivery', 'label': 'Out for Delivery', 'icon': Icons.delivery_dining},
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    final currentStatusIndex = statuses.indexWhere((s) => s['key'] == order.status);
    final isCancelled = order.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: isCancelled
          ? Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order Cancelled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: statuses.asMap().entries.map((entry) {
                final index = entry.key;
                final status = entry.value;
                final isCompleted = index <= currentStatusIndex;
                final isCurrent = index == currentStatusIndex;

                return Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? (isCurrent ? _getStatusColor(order.status) : AppTheme.primaryGreen)
                            : AppTheme.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status['icon'] as IconData,
                        color: isCompleted ? Colors.white : AppTheme.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Label
                    Expanded(
                      child: Text(
                        status['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? AppTheme.grey : AppTheme.grey.withOpacity(0.5),
                          fontFamily: 'RoundedSans',
                        ),
                      ),
                    ),
                    // Check mark for completed
                    if (isCompleted && !isCurrent)
                      Icon(
                        Icons.check,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildOrderItems(OrderModel order, NumberFormat currencyFormat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RoundedSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightGrey.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.product.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 60,
                                height: 60,
                                color: AppTheme.lightGrey,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                color: AppTheme.lightGrey,
                                child: Icon(Icons.image, color: AppTheme.grey),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: AppTheme.lightGrey,
                              child: Icon(Icons.image, color: AppTheme.grey),
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
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Show variant label if present
                          if (item.variant != null || item.displayLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.displayLabel ?? item.variant?.label ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey,
                                fontFamily: 'RoundedSans',
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Qty: ${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'RoundedSans',
                                  ),
                                ),
                              ),
                              if (item.unit != null || (item.variant == null && item.product.unit != null)) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• ${item.unit ?? item.product.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.grey,
                                    fontFamily: 'RoundedSans',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormat.format(item.price),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(item.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RoundedSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.deliveryAddress.tag != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.deliveryAddress.tag!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                  ),
                Text(
                  order.deliveryAddress.fullAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'RoundedSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(OrderModel order, NumberFormat currencyFormat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RoundedSans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Order ID', '#${order.id}'),
          const SizedBox(height: 12),
          _buildSummaryRow('Order Date', formatISTDefault(order.createdAt)),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Payment Method',
            order.paymentMethod?.toUpperCase() ?? 'N/A',
            icon: order.paymentMethod?.toLowerCase() == 'cash'
                ? Icons.money
                : Icons.payment,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Payment Status',
            _getPaymentStatusText(order),
            valueColor: _getPaymentStatusColor(order),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RoundedSans',
                ),
              ),
              Text(
                currencyFormat.format(order.totalAmount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                  fontFamily: 'RoundedSans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {IconData? icon, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.grey),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey,
                fontFamily: 'RoundedSans',
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.grey,
            fontFamily: 'RoundedSans',
          ),
        ),
      ],
    );
  }

  String _getPaymentStatusText(OrderModel order) {
    if (order.paymentMethod?.toLowerCase() == 'cash') {
      return 'Cash on Delivery';
    }
    if (order.isPaid) {
      return 'Paid';
    }
    return 'Pending';
  }

  Color _getPaymentStatusColor(OrderModel order) {
    if (order.paymentMethod?.toLowerCase() == 'cash') {
      return Colors.orange;
    }
    if (order.isPaid) {
      return AppTheme.primaryGreen;
    }
    return Colors.orange;
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Your order has been placed and is being processed';
      case 'accepted':
        return 'Your order has been accepted and will be prepared soon';
      case 'preparing':
        return 'Your order is being prepared with care';
      case 'out_for_delivery':
        return 'Your order is on the way to you';
      case 'delivered':
        return 'Your order has been delivered successfully';
      case 'cancelled':
        return 'Your order has been cancelled';
      default:
        return 'Order status update';
    }
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
        return Icons.check_circle_outline;
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
