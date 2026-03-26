import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.accessToken == null) {
      setState(() {
        _error = 'Authentication required';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First try to find in existing orders
      final existingOrder = adminProvider.orders.firstWhere(
        (o) => o.id == widget.orderId,
        orElse: () => throw Exception('Not in list'),
      );
      
      setState(() {
        _order = existingOrder;
        _isLoading = false;
      });
    } catch (e) {
      // If not in list, fetch from API
      try {
        final response = await adminProvider.apiService.get(
          '/admin/orders/${widget.orderId}',
          token: authProvider.accessToken!,
        );
        
        if (response == null) {
          throw Exception('Failed to fetch order');
        }
        final order = OrderModel.fromJson(response as Map<String, dynamic>);
        
        // Add to provider's list if not already there
        if (!adminProvider.orders.any((o) => o.id == order.id)) {
          adminProvider.orders.insert(0, order);
        }
        
        setState(() {
          _order = order;
          _isLoading = false;
        });
      } catch (apiError) {
        setState(() {
          _error = 'Failed to load order: ${apiError.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    if (_isLoading) {
      return popScopeWithRoleHubFallback(
        context,
        Scaffold(
          appBar: AppBar(
            title: Text('Order #${widget.orderId}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrRoleHub(context),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null || _order == null) {
      return popScopeWithRoleHubFallback(
        context,
        Scaffold(
          appBar: AppBar(
            title: Text('Order #${widget.orderId}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => popOrRoleHub(context),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.grey),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Order not found',
                  style: TextStyle(color: AppTheme.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadOrder,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final order = _order!;

    return popScopeWithRoleHubFallback(
      context,
      Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrRoleHub(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadOrder();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            _buildStatusCard(context, order, currencyFormat, dateFormat),
            
            // Customer Information
            _buildCustomerCard(order),
            
            // Order Items with Variants
            _buildOrderItemsCard(order, currencyFormat),
            
            // Delivery Address
            _buildAddressCard(order),
            
            // Payment Information
            _buildPaymentCard(order, currencyFormat),
            
            // Action Buttons
            if (order.status != 'delivered' && order.status != 'cancelled')
              _buildActionButtons(context, order, adminProvider, authProvider),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatusCard(BuildContext context, OrderModel order, NumberFormat currencyFormat, DateFormat dateFormat) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(order.status).withOpacity(0.1),
            _getStatusColor(order.status).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(order.status).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(order.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusText.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              if (order.paymentMethod != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: order.isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        order.isPaid ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: order.isPaid ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.isPaid ? 'Paid' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: order.isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.user.name ?? 'Guest User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                          order.user.phoneNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (order.deliveryBoy != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Agent',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryBoy!.name ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (order.deliveryBoy!.phoneNumber != null)
                          Text(
                            order.deliveryBoy!.phoneNumber!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(OrderModel order, NumberFormat currencyFormat) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Items (${order.items.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildOrderItemTile(item, currencyFormat, index + 1);
            }),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(order.totalAmount),
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
    );
  }

  Widget _buildOrderItemTile(OrderItemModel item, NumberFormat currencyFormat, int index) {
    final hasVariant = item.variant != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: hasVariant
            ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.lightGrey,
                      child: const Icon(Icons.image, size: 30),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: AppTheme.lightGrey,
                    child: const Icon(Icons.image, size: 30),
                  ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Variant Information
                if (hasVariant) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.displayLabel ?? item.variant!.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.grey,
                      ),
                    ),
                    if (item.unit != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${item.unit}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currencyFormat.format(item.price)} × ${item.quantity}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.grey,
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              order.deliveryAddress.fullAddress,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (order.deliveryAddress.landmark != null) ...[
              const SizedBox(height: 8),
              Text(
                'Landmark: ${order.deliveryAddress.landmark}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(OrderModel order, NumberFormat currencyFormat) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grey,
                  ),
                ),
                Text(
                  order.paymentMethod?.toUpperCase() ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (order.paymentId != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment ID',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grey,
                    ),
                  ),
                  Text(
                    order.paymentId!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: order.isPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    OrderModel order,
    AdminProvider adminProvider,
    AuthProvider authProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (order.status == 'pending')
            ElevatedButton.icon(
              onPressed: () => _updateStatus(context, order.id, 'accepted', adminProvider, authProvider),
              icon: const Icon(Icons.check_circle),
              label: const Text('Accept Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          if (order.status == 'accepted') ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _updateStatus(context, order.id, 'preparing', adminProvider, authProvider),
              icon: const Icon(Icons.restaurant),
              label: const Text('Start Preparing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          if (order.status == 'preparing') ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _updateStatus(context, order.id, 'out_for_delivery', adminProvider, authProvider),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Out for Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          if (order.status == 'out_for_delivery') ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _updateStatus(context, order.id, 'delivered', adminProvider, authProvider),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          if (order.status != 'delivered') ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _updateStatus(context, order.id, 'cancelled', adminProvider, authProvider),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    int orderId,
    String status,
    AdminProvider adminProvider,
    AuthProvider authProvider,
  ) async {
    if (authProvider.accessToken == null) return;

    final success = await adminProvider.updateOrderStatus(
      token: authProvider.accessToken!,
      orderId: orderId,
      status: status,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${status.replaceAll('_', ' ')}'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh the order in detail view
      await _loadOrder();
      
      // Also refresh the orders list in background
      adminProvider.fetchOrders(token: authProvider.accessToken);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminProvider.error ?? 'Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.primaryGreen;
    }
  }
}

