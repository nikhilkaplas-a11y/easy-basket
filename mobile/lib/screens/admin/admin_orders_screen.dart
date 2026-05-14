import 'dart:async';
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

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with WidgetsBindingObserver {
  String _selectedStatus = 'all';
  final _scrollController = ScrollController();
  Timer? _refreshTimer;
  bool _isScreenActive = true;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedStatus = widget.status ?? 'all';
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pause auto-refresh when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isScreenActive = false;
      _refreshTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _isScreenActive = true;
      // Refresh immediately when app comes to foreground
      _loadOrders();
      _startAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    // Cancel existing timer
    _refreshTimer?.cancel();
    
    // Start new timer - refresh every 20 seconds (more frequent for orders page)
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_isScreenActive && mounted) {
        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        if (authProvider.accessToken != null) {
          // Silent refresh - no loading indicator
          final status = _selectedStatus == 'all' ? null : _selectedStatus;
          adminProvider.fetchOrders(status: status, token: authProvider.accessToken, loadMore: false);
          _lastRefreshTime = DateTime.now();
        }
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (adminProvider.hasMore && !adminProvider.isLoadingMore) {
        final status = _selectedStatus == 'all' ? null : _selectedStatus;
        adminProvider.fetchOrders(status: status, token: authProvider.accessToken, loadMore: true);
      }
    }
  }

  void _loadOrders() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final status = _selectedStatus == 'all' ? null : _selectedStatus;
    adminProvider.fetchOrders(status: status, token: authProvider.accessToken);
    _lastRefreshTime = DateTime.now();
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus, {int? deliveryBoyId}) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.accessToken == null) return;

    // If accepting or preparing AND no partner is already attached to this order,
    // show the delivery agent selection dialog. If a partner is already assigned
    // (e.g. admin assigned at "accepted" stage and is now clicking "preparing"),
    // skip the dialog and keep the existing assignment — don't re-pass the id
    // either, otherwise the backend would re-fire an "order assigned" FCM push
    // to the rider on every status update.
    final existing = adminProvider.orders.where((o) => o.id == orderId).toList();
    final hasPartnerAttached = existing.isNotEmpty && existing.first.deliveryBoy != null;

    if ((newStatus == 'accepted' || newStatus == 'preparing') &&
        deliveryBoyId == null &&
        !hasPartnerAttached) {
      final selectedAgent = await _showDeliveryAgentDialog(adminProvider, authProvider.accessToken!);
      // If user cancelled the dialog, don't proceed
      if (selectedAgent == -1 && mounted) {
        return; // User cancelled
      }
      // If selectedAgent is null, it means "Skip assignment" (delivery agents can accept later)
      deliveryBoyId = selectedAgent == -1 ? null : selectedAgent;
    }

    final success = await adminProvider.updateOrderStatus(
      token: authProvider.accessToken!,
      orderId: orderId,
      status: newStatus,
      deliveryBoyId: deliveryBoyId,
    );

    if (success && mounted) {
      final message = deliveryBoyId != null
          ? 'Order status updated and assigned to delivery agent!'
          : 'Order status updated! Delivery agents can accept it from available orders.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminProvider.error ?? 'Failed to update status')),
      );
    }
  }

  Future<int?> _showDeliveryAgentDialog(AdminProvider adminProvider, String token) async {
    // Always fetch fresh delivery agents list
    await adminProvider.fetchDeliveryAgents(token: token);

    // Check for errors
    if (adminProvider.error != null && adminProvider.deliveryAgents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading delivery agents: ${adminProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Delivery Agent'),
        content: SizedBox(
          width: double.maxFinite,
          child: adminProvider.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : adminProvider.deliveryAgents.isEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off, size: 48, color: AppTheme.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No delivery agents available',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (adminProvider.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Error: ${adminProvider.error}',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const Text(
                          'You can accept the order without assignment. Delivery agents can accept it later from available orders.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: adminProvider.deliveryAgents.length + 1, // +1 for "Skip" option
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "Skip assignment" option
                          return ListTile(
                            leading: const Icon(Icons.skip_next, color: AppTheme.primaryGreen),
                            title: const Text('Skip Assignment'),
                            subtitle: const Text('Delivery agents can accept later'),
                            onTap: () => Navigator.pop(context, null),
                          );
                        }
                        final agent = adminProvider.deliveryAgents[index - 1];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                            child: Icon(Icons.person, color: AppTheme.primaryGreen),
                          ),
                          title: Text(agent.name ?? 'Unknown'),
                          subtitle: Text(agent.phoneNumber ?? ''),
                          onTap: () => Navigator.pop(context, agent.id),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, -1), // -1 means cancelled
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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
                          return InkWell(
                            onTap: () {
                              context.push('/admin/orders/${order.id}');
                            },
                            child: _OrderCard(
                              order: order,
                              onStatusUpdate: _updateOrderStatus,
                            ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
            if (order.deliveryBoy != null)
              Text(
                'Delivery: ${order.deliveryBoy.name ?? order.deliveryBoy.phoneNumber}',
                style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen),
              ),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...order.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final hasVariant = item.variant != null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasVariant 
                          ? AppTheme.primaryGreen.withOpacity(0.05)
                          : AppTheme.lightGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: hasVariant
                          ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (hasVariant) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      size: 12,
                                      color: AppTheme.primaryGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.displayLabel ?? item.variant!.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Qty: ${item.quantity}${item.unit != null ? " • ${item.unit}" : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(item.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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

