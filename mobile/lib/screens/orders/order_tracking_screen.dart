import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import '../../utils/navigation_utils.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  bool _hasFetched = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrder();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _fetchOrder() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    if (authProvider.accessToken != null) {
      orderProvider.fetchOrderById(widget.orderId, authProvider.accessToken!);
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final order = orderProvider.orders.where((o) => o.id == widget.orderId).firstOrNull;
      if (order != null && (order.status == 'delivered' || order.status == 'cancelled')) {
        _pollingTimer?.cancel();
        return;
      }
      _fetchOrder();
    });
  }

  void _fetchOrderIfNeeded() => _fetchOrder();

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final order = orderProvider.orders.where((o) => o.id == widget.orderId).firstOrNull;

    if (order == null && !_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOrderIfNeeded());
    }

    if (order == null) {
      return popScopeWithRoleHubFallback(
        context,
        Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: _buildLoadingAppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen)),
                const SizedBox(height: 16),
                Text(
                  orderProvider.isLoading ? 'Loading order details...' : 'Order not found',
                  style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return popScopeWithRoleHubFallback(
      context,
      Scaffold(
        backgroundColor: const Color(0xFFF4F8F3),
        appBar: _buildAppBar(order),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            children: [
              _buildStatusHeader(order),
              const SizedBox(height: 14),
              _buildOrderTimeline(order),
              const SizedBox(height: 14),
              _buildOrderItems(order, currencyFormat),
              const SizedBox(height: 14),
              _buildDeliveryAddress(order),
              const SizedBox(height: 14),
              _buildPaymentSummary(order, currencyFormat),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════

  PreferredSizeWidget _buildLoadingAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF4F8F3),
      title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.black87)),
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87), onPressed: () => popOrRoleHub(context)),
    );
  }

  PreferredSizeWidget _buildAppBar(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF4F8F3),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => popOrRoleHub(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 20),
          ),
        ),
      ),
      title: Row(
        children: [
          Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              order.statusText,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STATUS HEADER
  // ═══════════════════════════════════════

  Widget _buildStatusHeader(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.1), statusColor.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: statusColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Icon(statusIcon, size: 40, color: statusColor),
          ),
          const SizedBox(height: 14),
          Text(
            order.statusText,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            _getStatusDescription(order.status),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // ORDER TIMELINE
  // ═══════════════════════════════════════

  Widget _buildOrderTimeline(OrderModel order) {
    final statuses = [
      {'key': 'pending', 'label': 'Order Placed', 'icon': Icons.shopping_cart_rounded},
      {'key': 'accepted', 'label': 'Order Accepted', 'icon': Icons.check_circle_outline_rounded},
      {'key': 'preparing', 'label': 'Preparing', 'icon': Icons.restaurant_rounded},
      {'key': 'out_for_delivery', 'label': 'Out for Delivery', 'icon': Icons.delivery_dining_rounded},
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.check_circle_rounded},
    ];

    final currentStatusIndex = statuses.indexWhere((s) => s['key'] == order.status);
    final isCancelled = order.status == 'cancelled';

    return _premiumCard(
      child: isCancelled
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.cancel_rounded, color: Colors.red, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Cancelled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red)),
                      SizedBox(height: 2),
                      Text('This order has been cancelled', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(Icons.timeline_rounded, 'Order Progress'),
                const SizedBox(height: 16),
                ...statuses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final status = entry.value;
                  final isCompleted = index <= currentStatusIndex;
                  final isCurrent = index == currentStatusIndex;
                  final isLast = index == statuses.length - 1;

                  return Column(
                    children: [
                      Row(
                        children: [
                          // Timeline dot/icon
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? (isCurrent ? _getStatusColor(order.status) : AppTheme.primaryGreen)
                                  : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isCurrent
                                  ? [BoxShadow(color: _getStatusColor(order.status).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))]
                                  : null,
                            ),
                            child: Icon(status['icon'] as IconData, color: isCompleted ? Colors.white : Colors.grey[400], size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              status['label'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCompleted ? Colors.black87 : Colors.grey[400],
                              ),
                            ),
                          ),
                          if (isCompleted && !isCurrent)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded, color: AppTheme.primaryGreen, size: 14),
                            ),
                        ],
                      ),
                      if (!isLast)
                        Container(
                          margin: const EdgeInsets.only(left: 18, top: 2, bottom: 2),
                          width: 2,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isCompleted ? AppTheme.primaryGreen.withValues(alpha: 0.3) : const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════
  // ORDER ITEMS
  // ═══════════════════════════════════════

  Widget _buildOrderItems(OrderModel order, NumberFormat currencyFormat) {
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.shopping_bag_rounded, 'Order Items', trailing: '${order.items.length} items'),
          const SizedBox(height: 14),
          ...order.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Product image
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: item.product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.product.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: const Color(0xFFF5F5F5), child: const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen)))),
                                errorWidget: (_, __, ___) => Container(color: const Color(0xFFF5F5F5), child: Icon(Icons.image_rounded, color: Colors.grey[300])),
                              )
                            : Container(color: const Color(0xFFF5F5F5), child: Icon(Icons.image_rounded, color: Colors.grey[300])),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.variant != null || item.displayLabel != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.displayLabel ?? item.variant?.label ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Quantity chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'x${item.quantity}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                                ),
                              ),
                              if (item.unit != null || (item.variant == null && item.product.unit != null)) ...[
                                const SizedBox(width: 8),
                                Text(
                                  item.unit ?? item.product.unit ?? '',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
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
                        if (item.quantity > 1)
                          Text(
                            currencyFormat.format(item.price),
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(item.total),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
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

  // ═══════════════════════════════════════
  // DELIVERY ADDRESS
  // ═══════════════════════════════════════

  Widget _buildDeliveryAddress(OrderModel order) {
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.location_on_rounded, 'Delivery Address'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen.withValues(alpha: 0.04), AppTheme.primaryGreen.withValues(alpha: 0.01)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_rounded, color: AppTheme.primaryGreen, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.deliveryAddress.tag != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.deliveryAddress.tag!.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen, letterSpacing: 0.5),
                          ),
                        ),
                      Text(
                        order.deliveryAddress.fullAddress,
                        style: TextStyle(fontSize: 13, height: 1.6, color: Colors.grey[700]),
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

  // ═══════════════════════════════════════
  // PAYMENT SUMMARY
  // ═══════════════════════════════════════

  Widget _buildPaymentSummary(OrderModel order, NumberFormat currencyFormat) {
    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.receipt_long_rounded, 'Order Summary'),
          const SizedBox(height: 14),
          _summaryRow('Order ID', '#${order.id}'),
          _summaryRow('Order Date', formatISTDefault(order.createdAt)),
          _summaryRow('Payment', order.paymentMethod?.toUpperCase() ?? 'N/A',
            trailing: _paymentChip(order),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          const SizedBox(height: 14),
          // Total amount — highlighted
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryGreen.withValues(alpha: 0.06), AppTheme.primaryGreen.withValues(alpha: 0.02)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                Text(
                  currencyFormat.format(order.totalAmount),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // REUSABLE HELPERS
  // ═══════════════════════════════════════

  /// Premium card wrapper
  Widget _premiumCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: child,
    );
  }

  /// Section title with icon
  Widget _sectionTitle(IconData icon, String title, {String? trailing}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87)),
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400])),
        ],
      ],
    );
  }

  /// Summary row
  Widget _summaryRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500])),
          trailing ?? Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }

  /// Payment status chip
  Widget _paymentChip(OrderModel order) {
    final isCash = order.paymentMethod?.toLowerCase() == 'cash';
    final isPaid = order.isPaid;
    final text = isCash ? 'Cash on Delivery' : (isPaid ? 'Paid' : 'Pending');
    final color = isCash ? Colors.orange : (isPaid ? AppTheme.primaryGreen : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ═══════════════════════════════════════
  // STATUS HELPERS
  // ═══════════════════════════════════════

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending': return 'Your order has been placed and is being processed';
      case 'accepted': return 'Your order has been accepted and will be prepared soon';
      case 'preparing': return 'Your order is being prepared with care';
      case 'out_for_delivery': return 'Your order is on the way to you';
      case 'delivered': return 'Your order has been delivered successfully';
      case 'cancelled': return 'Your order has been cancelled';
      default: return 'Order status update';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFFF9800);
      case 'accepted': return const Color(0xFF2196F3);
      case 'preparing': return const Color(0xFF1565C0);
      case 'out_for_delivery': return const Color(0xFF7B1FA2);
      case 'delivered': return AppTheme.primaryGreen;
      case 'cancelled': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.pending_rounded;
      case 'accepted': return Icons.check_circle_outline_rounded;
      case 'preparing': return Icons.restaurant_rounded;
      case 'out_for_delivery': return Icons.delivery_dining_rounded;
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.info_rounded;
    }
  }
}
