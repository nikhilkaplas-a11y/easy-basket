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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Assign Delivery Agent',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        if (adminProvider.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Error: ${adminProvider.error}',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const Text(
                          'You can accept the order without assignment. Delivery agents can accept it later from available orders.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.grey),
                        ),
                      ],
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: adminProvider.deliveryAgents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.skip_next,
                                color: AppTheme.primaryGreen,
                                size: 22,
                              ),
                              title: const Text(
                                'Skip Assignment',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              subtitle: const Text(
                                'Delivery agents can accept later',
                                style: TextStyle(fontSize: 11),
                              ),
                              onTap: () => Navigator.pop(context, null),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          );
                        }
                        final agent = adminProvider.deliveryAgents[index - 1];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200, width: 1),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
                              child: Icon(Icons.person, color: AppTheme.primaryGreen, size: 20),
                            ),
                            title: Text(
                              agent.name ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            subtitle: Text(
                              agent.phoneNumber ?? '',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () => Navigator.pop(context, agent.id),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, -1),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _StatusChip(
                    label: 'All',
                    icon: Icons.list,
                    isSelected: _selectedStatus == 'all',
                    onTap: () {
                      setState(() => _selectedStatus = 'all');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: 'Pending',
                    icon: Icons.schedule,
                    isSelected: _selectedStatus == 'pending',
                    onTap: () {
                      setState(() => _selectedStatus = 'pending');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: 'Accepted',
                    icon: Icons.check_circle_outline,
                    isSelected: _selectedStatus == 'accepted',
                    onTap: () {
                      setState(() => _selectedStatus = 'accepted');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: 'Out for Delivery',
                    icon: Icons.local_shipping,
                    isSelected: _selectedStatus == 'out_for_delivery',
                    onTap: () {
                      setState(() => _selectedStatus = 'out_for_delivery');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: 'Delivered',
                    icon: Icons.check_circle,
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
                                fontWeight: FontWeight.w500,
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
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppTheme.white : AppTheme.grey,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryGreen,
      checkmarkColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.white : AppTheme.black,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
        width: isSelected ? 0 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
    final screenWidth = MediaQuery.of(context).size.width;
   
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(0),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        leading: null,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID Circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(order.status).withOpacity(0.2),
                          _getStatusColor(order.status).withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '#${order.id}',
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Order #${order.id}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 4),

      Text(
        (order.user.name != null &&
                order.user.name.toString().trim().isNotEmpty)
            ? order.user.name
            : order.user.phoneNumber,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.grey,
          fontWeight: FontWeight.w500,
        ),
      ),

      const SizedBox(height: 6),

      Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            order.paymentMethod == 'upi'
                ? Icons.check_circle
                : Icons.payment,
            size: 14,
            color: order.paymentMethod == 'upi'
                ? Colors.green.shade600
                : Colors.orange.shade600,
          ),
          Text(
            order.paymentMethod == 'upi' ? 'PAID' : 'COD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: order.paymentMethod == 'upi'
                  ? Colors.green.shade600
                  : Colors.orange.shade600,
            ),
          ),
          Text(
            currencyFormat.format(order.totalAmount),
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
      
    ],
  ),
),

const SizedBox(width: 6),

ConstrainedBox(
  constraints: const BoxConstraints(
    maxWidth: 90,
  ),
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: _getStatusColor(order.status).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: _getStatusColor(order.status).withOpacity(0.3),
        width: 1.5,
      ),
    ),
    child: Text(
      order.statusText,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _getStatusColor(order.status),
      ),
    ),
  ),
),
                ],
              ),
            ],
          ),
        ),
        subtitle: const SizedBox.shrink(),
        trailing: const SizedBox(width: 8),
        children: [
          Container(
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Delivery Agent Section
                      if (order.deliveryBoy != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_pin,
                                  size: 18,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery Agent',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      order.deliveryBoy.name ??
                                          order.deliveryBoy.phoneNumber,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                          ],
                        ),
                      // Order Items
                      Text(
                        'Order Items',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...order.items.map((item) {
                        final hasVariant = item.variant != null;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hasVariant
                                ? AppTheme.primaryGreen.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasVariant
                                  ? AppTheme.primaryGreen.withOpacity(0.2)
                                  : Colors.grey.shade200,
                              width: 1,
                            ),
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
                                        fontSize: 13,
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
                                            item.displayLabel ??
                                                item.variant!.label,
                                            style: TextStyle(
                                              fontSize: 11,
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
                                        fontSize: 11,
                                        color: AppTheme.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      // Delivery Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.deliveryAddress.fullAddress,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status Update Buttons
                      if (order.status != 'delivered' &&
                          order.status != 'cancelled')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (order.status == 'pending')
                                    _StatusButton(
                                      icon: Icons.check,
                                      label: 'Accept',
                                      color: Colors.blue,
                                      onPressed: () =>
                                          onStatusUpdate(order.id, 'accepted'),
                                    ),
                                  if (order.status == 'accepted')
                                    _StatusButton(
                                      icon: Icons.local_dining,
                                      label: 'Preparing',
                                      color: Colors.orange,
                                      onPressed: () =>
                                          onStatusUpdate(order.id, 'preparing'),
                                    ),
                                  if (order.status == 'preparing')
                                    _StatusButton(
                                      icon: Icons.local_shipping,
                                      label: 'Out for Delivery',
                                      color: Colors.purple,
                                      onPressed: () => onStatusUpdate(
                                          order.id, 'out_for_delivery'),
                                    ),
                                  if (order.status == 'out_for_delivery')
                                    _StatusButton(
                                      icon: Icons.check_circle,
                                      label: 'Delivered',
                                      color: Colors.green,
                                      onPressed: () =>
                                          onStatusUpdate(order.id, 'delivered'),
                                    ),
                                  _StatusButton(
                                    icon: Icons.close,
                                    label: 'Cancel',
                                    color: Colors.red,
                                    isOutlined: true,
                                    onPressed: () =>
                                        onStatusUpdate(order.id, 'cancelled'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
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

class _StatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _StatusButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

