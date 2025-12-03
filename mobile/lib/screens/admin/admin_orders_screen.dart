import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  final String? status;

  const AdminOrdersScreen({super.key, this.status});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedStatus = 'all';
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.status ?? 'all';
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (adminProvider.hasMore && !adminProvider.isLoadingMore) {
        final status = _selectedStatus == 'all' ? null : _selectedStatus;
        adminProvider.fetchOrders(status: status, token: authProvider.token, loadMore: true);
      }
    }
  }

  void _loadOrders() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final status = _selectedStatus == 'all' ? null : _selectedStatus;
    adminProvider.fetchOrders(status: status, token: authProvider.token);
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus, {int? deliveryBoyId}) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null) return;

    final success = await adminProvider.updateOrderStatus(
      token: authProvider.token!,
      orderId: orderId,
      status: newStatus,
      deliveryBoyId: deliveryBoyId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminProvider.error ?? 'Failed to update status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatusChip(
                    label: 'All',
                    isSelected: _selectedStatus == 'all',
                    onTap: () {
                      setState(() => _selectedStatus = 'all');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'Pending',
                    isSelected: _selectedStatus == 'pending',
                    onTap: () {
                      setState(() => _selectedStatus = 'pending');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'Accepted',
                    isSelected: _selectedStatus == 'accepted',
                    onTap: () {
                      setState(() => _selectedStatus = 'accepted');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'Out for Delivery',
                    isSelected: _selectedStatus == 'out_for_delivery',
                    onTap: () {
                      setState(() => _selectedStatus = 'out_for_delivery');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: 'Delivered',
                    isSelected: _selectedStatus == 'delivered',
                    onTap: () {
                      setState(() => _selectedStatus = 'delivered');
                      _loadOrders();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: adminProvider.isLoading && adminProvider.orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : adminProvider.orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: AppTheme.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No orders found',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: adminProvider.orders.length + (adminProvider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == adminProvider.orders.length) {
                            // Load more indicator
                            if (adminProvider.isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          final order = adminProvider.orders[index];
                          return _OrderCard(
                            order: order,
                            onStatusUpdate: _updateOrderStatus,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryGreen,
      checkmarkColor: AppTheme.white,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.white : AppTheme.black,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final Function(int orderId, String status, {int? deliveryBoyId}) onStatusUpdate;

  const _OrderCard({
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status).withOpacity(0.2),
          child: Text(
            '#${order.id}',
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Order #${order.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.user.name ?? order.user.phoneNumber}'),
            Text(
              currencyFormat.format(order.totalAmount),
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            order.statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(order.status),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${item.product.name} x ${item.quantity} = ${currencyFormat.format(item.total)}',
                      ),
                    )),
                const SizedBox(height: 16),
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress.fullAddress,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status Update Buttons
                if (order.status != 'delivered' && order.status != 'cancelled')
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (order.status == 'pending')
                        ElevatedButton(
                          onPressed: () => onStatusUpdate(order.id, 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Accept', style: TextStyle(fontSize: 12)),
                        ),
                      if (order.status == 'accepted')
                        ElevatedButton(
                          onPressed: () => onStatusUpdate(order.id, 'preparing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Preparing', style: TextStyle(fontSize: 12)),
                        ),
                      if (order.status == 'preparing')
                        ElevatedButton(
                          onPressed: () => onStatusUpdate(order.id, 'out_for_delivery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Out for Delivery', style: TextStyle(fontSize: 12)),
                        ),
                      if (order.status == 'out_for_delivery')
                        ElevatedButton(
                          onPressed: () => onStatusUpdate(order.id, 'delivered'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Delivered', style: TextStyle(fontSize: 12)),
                        ),
                      if (order.status != 'delivered')
                        OutlinedButton(
                          onPressed: () => onStatusUpdate(order.id, 'cancelled'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
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

