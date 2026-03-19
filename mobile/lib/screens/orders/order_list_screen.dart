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

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() async {
    if (_hasLoaded) return;
    
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      _hasLoaded = true;
      if (kDebugMode) {
        print('🔄 Loading orders...');
      }
      // Pass callback to get updated token if refresh happens
      await orderProvider.fetchOrders(
        authProvider.token!,
        getUpdatedToken: () {
          final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
          return updatedAuth.token;
        },
      );
    }
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

  Widget _buildOrderList(OrderProvider orderProvider, NumberFormat currencyFormat) {
    final orders = orderProvider.orders;
    
    if (orders.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.token != null) {
          await orderProvider.fetchOrders(authProvider.token!);
        }
      },
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index < orders.length - 1 ? 16 : 0),
            child: _buildOrderCard(order, currencyFormat),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.white, // Clean white background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.black),
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: orderProvider.isLoading && orderProvider.orders.isEmpty
          ? _buildLoadingState()
          : orderProvider.error != null && orderProvider.orders.isEmpty
              ? _buildErrorState(orderProvider)
              : _buildOrderList(orderProvider, currencyFormat),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your orders...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OrderProvider orderProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              orderProvider.error ?? 'Failed to load orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _hasLoaded = false);
                _loadOrders();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        if (authProvider.token != null) {
          await orderProvider.fetchOrders(authProvider.token!);
        }
      },
      color: AppTheme.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
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
                  Icons.shopping_bag_outlined,
                  size: 100,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'No orders yet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start shopping to see your orders here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.grey.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.shopping_cart_rounded, size: 22),
                label: const Text(
                  'Start Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, NumberFormat currencyFormat) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/order/${order.id}'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Order ID and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppTheme.grey.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  formatISTDefault(order.createdAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.grey.withOpacity(0.8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge - positioned to avoid overlap
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                order.statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Product Preview with enhanced design
                if (order.items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Product Images
                        Expanded(
                          child: SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: order.items.length > 3 ? 3 : order.items.length,
                              itemBuilder: (context, index) {
                                final item = order.items[index];
                                return Container(
                                  margin: EdgeInsets.only(
                                    right: index < (order.items.length > 3 ? 2 : order.items.length - 1) ? 10 : 0,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: item.product.imageUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: item.product.imageUrl!,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                color: AppTheme.lightGrey,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                color: AppTheme.lightGrey,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.image_outlined,
                                                color: AppTheme.grey.withOpacity(0.5),
                                                size: 28,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color: AppTheme.lightGrey,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: AppTheme.grey.withOpacity(0.5),
                                              size: 28,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (order.items.length > 3)
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+${order.items.length - 3}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Divider with gradient effect
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.lightGrey,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Footer with Payment and Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Payment and Items Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                order.paymentMethod?.toLowerCase() == 'cash'
                                    ? Icons.money_rounded
                                    : Icons.payment_rounded,
                                size: 14,
                                color: AppTheme.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getPaymentStatusText(order),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    // Total Amount with enhanced styling
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.grey.withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(order.totalAmount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // View Details Button with enhanced design
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/order/${order.id}'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'View Order Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

