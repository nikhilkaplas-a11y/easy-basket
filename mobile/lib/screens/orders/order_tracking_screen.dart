import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../utils/navigation_utils.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  bool _hasFetched = false;
  Timer? _pollingTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrder();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
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
      final orderProvider =
          Provider.of<OrderProvider>(context, listen: false);
      final order = orderProvider.orders
          .where((o) => o.id == widget.orderId)
          .firstOrNull;
      if (order != null &&
          (order.status == 'delivered' || order.status == 'cancelled')) {
        _pollingTimer?.cancel();
        return;
      }
      _fetchOrder();
    });
  }

  // ═══════════════════════════════════════
  // STATUS HELPERS
  // ═══════════════════════════════════════

  static const _statusOrder = [
    'pending',
    'accepted',
    'preparing',
    'out_for_delivery',
    'delivered',
  ];

  int _statusIndex(String status) {
    final i = _statusOrder.indexOf(status);
    return i == -1 ? 0 : i;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Confirmed';
      case 'preparing':
        return 'Packing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _statusSubtext(String status) {
    switch (status) {
      case 'pending':
        return 'Your order is being processed';
      case 'accepted':
        return 'Your order has been confirmed';
      case 'preparing':
        return 'Your order is being packed';
      case 'out_for_delivery':
        return 'Your order is on the way!';
      case 'delivered':
        return 'Your order has been delivered!';
      case 'cancelled':
        return 'This order was cancelled';
      default:
        return '';
    }
  }

  String _etaText(String status) {
    switch (status) {
      case 'pending':
        return 'Estimated delivery in 25 mins';
      case 'accepted':
        return 'Estimated delivery in 20 mins';
      case 'preparing':
        return 'Estimated delivery in 15 mins';
      case 'out_for_delivery':
        return 'Arriving in 10 mins';
      default:
        return '';
    }
  }

  String _timeRange() {
    final now = DateTime.now();
    final start = now.add(const Duration(minutes: 10));
    final end = now.add(const Duration(minutes: 20));
    final fmt = DateFormat('h:mm a');
    return '${fmt.format(start)} - ${fmt.format(end)}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
        return const Color(0xFF2196F3);
      case 'preparing':
        return const Color(0xFF1565C0);
      case 'out_for_delivery':
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final fmt = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 0);
    final order =
        orderProvider.orders.where((o) => o.id == widget.orderId).firstOrNull;

    if (order == null && !_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOrder());
    }

    if (order == null) {
      return popScopeWithRoleHubFallback(
        context,
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF2E7D32),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => popOrRoleHub(context),
            ),
            title: const Text('Track Order',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF2E7D32))),
                const SizedBox(height: 16),
                Text(
                  orderProvider.isLoading
                      ? 'Loading order details...'
                      : 'Order not found',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isCancelled = order.status == 'cancelled';
    final isOutForDelivery = order.status == 'out_for_delivery';

    return popScopeWithRoleHubFallback(
      context,
      Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            // ── GREEN HEADER ──
            _buildGreenHeader(order),

            // ── SCROLLABLE BODY ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    // Status + ETA
                    _buildStatusSection(order),
                    const SizedBox(height: 16),

                    // Horizontal Progress Tracker
                    if (!isCancelled) _buildProgressTracker(order),
                    if (!isCancelled) const SizedBox(height: 16),

                    // Delivery Partner Card (only when out for delivery)
                    if (isOutForDelivery) _buildDriverCard(order),
                    if (isOutForDelivery) const SizedBox(height: 16),

                    // Order Details
                    _buildOrderDetails(order, fmt),
                    const SizedBox(height: 16),

                    // Live Map (only when out for delivery)
                    if (isOutForDelivery) _buildMapSection(),
                    if (isOutForDelivery) const SizedBox(height: 16),

                    // Delivery Address
                    _buildAddressCard(order),
                    const SizedBox(height: 16),

                    // Payment Info
                    _buildPaymentCard(order, fmt),
                    const SizedBox(height: 20),

                    // Need Help button
                    _buildNeedHelpButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // GREEN BRANDED HEADER
  // ═══════════════════════════════════════

  Widget _buildGreenHeader(OrderModel order) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
      ),
      child: Column(
        children: [
          // App bar row
          SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => popOrRoleHub(context),
                ),
                const Expanded(
                  child: Text(
                    'Track Your Order',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // balance the back button
              ],
            ),
          ),
          // Order ID
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Order #EB${order.id.toString().padLeft(6, '0')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STATUS SECTION
  // ═══════════════════════════════════════

  Widget _buildStatusSection(OrderModel order) {
    final color = _statusColor(order.status);
    final isActive = order.status != 'delivered' && order.status != 'cancelled';

    return _card(
      child: Column(
        children: [
          // Status label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(
                          alpha: 0.4 + _pulseController.value * 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Text(
                _statusLabel(order.status),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _statusSubtext(order.status),
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Text(
              _etaText(order.status),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            Text(
              _timeRange(),
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // HORIZONTAL PROGRESS TRACKER
  // ═══════════════════════════════════════

  Widget _buildProgressTracker(OrderModel order) {
    final steps = [
      {'key': 'pending', 'label': 'Order\nPlaced', 'icon': Icons.receipt_long_rounded},
      {'key': 'preparing', 'label': 'Out for\nDelivery', 'icon': Icons.local_shipping_rounded},
      {'key': 'out_for_delivery', 'label': 'Arriving\nSoon', 'icon': Icons.delivery_dining_rounded},
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.home_rounded},
    ];

    final currentIdx = _statusIndex(order.status);

    return _card(
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final leftStep = steps[i ~/ 2];
            final leftPos = _statusOrder.indexOf(leftStep['key'] as String);
            final isDone = currentIdx > leftPos;
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final step = steps[i ~/ 2];
          final stepPos = _statusOrder.indexOf(step['key'] as String);
          final isDone = currentIdx >= stepPos;
          final isCurrent = currentIdx == stepPos ||
              (step['key'] == 'preparing' && order.status == 'accepted');

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                  border: isCurrent && !isDone
                      ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  step['icon'] as IconData,
                  color: isDone ? Colors.white : Colors.grey[400],
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step['label'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isDone
                      ? const Color(0xFF2E7D32)
                      : Colors.grey[400],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CANCELLED BANNER
  // ═══════════════════════════════════════

  // ═══════════════════════════════════════
  // DRIVER CARD
  // ═══════════════════════════════════════

  Widget _buildDriverCard(OrderModel order) {
    final name = order.deliveryBoy?.name ?? 'Delivery Partner';

    return _accentCard(
      title: 'Driver is on the way!',
      titleColor: const Color(0xFF2E7D32),
      child: Row(
        children: [
          // Dummy avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_rounded,
                color: Color(0xFF2E7D32), size: 36),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your Delivery Partner',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  'Est. Arrival: ${DateFormat('h:mm a').format(DateTime.now().add(const Duration(minutes: 10)))}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomChild: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.phone_rounded, size: 18),
          label: const Text('Contact Driver',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ORDER DETAILS
  // ═══════════════════════════════════════

  Widget _buildOrderDetails(OrderModel order, NumberFormat fmt) {
    final subtotal =
        order.items.fold<double>(0, (sum, item) => sum + item.total);
    final deliveryFee = order.totalAmount - subtotal;

    return _accentCard(
      title: 'Order Details',
      child: Column(
        children: [
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product.name}${item.displayLabel != null ? ' - ${item.displayLabel}' : (item.variant != null ? ' - ${item.variant!.label}' : '')}',
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x${item.quantity}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      fmt.format(item.total),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                  ],
                ),
              )),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF0F0F0)),
          _row('Subtotal', fmt.format(subtotal)),
          const SizedBox(height: 4),
          _row(
              'Delivery Fee',
              deliveryFee > 0 ? fmt.format(deliveryFee) : 'FREE',
              valueColor:
                  deliveryFee > 0 ? Colors.black87 : const Color(0xFF2E7D32)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                Text(
                  fmt.format(order.totalAmount),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }

  // ═══════════════════════════════════════
  // LIVE MAP SECTION
  // ═══════════════════════════════════════

  Widget _buildMapSection() {
    return _accentCard(
      title: 'Live Order Tracking',
      child: Column(
        children: [
          // Map
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Map background
                  CustomPaint(
                    size: const Size(double.infinity, 180),
                    painter: _LiveMapPainter(
                      riderProgress: _pulseController.value * 0.6 + 0.2,
                    ),
                  ),
                  // Live badge
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('LIVE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E7D32),
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Subtext
          Text(
            'Rider is heading to your location!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // DELIVERY ADDRESS CARD
  // ═══════════════════════════════════════

  Widget _buildAddressCard(OrderModel order) {
    return _accentCard(
      title: 'Delivering To',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded,
              color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.deliveryAddress.tag != null)
                  Text(
                    order.deliveryAddress.tag!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                if (order.deliveryAddress.tag != null)
                  const SizedBox(height: 3),
                Text(
                  order.deliveryAddress.fullAddress,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    order.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // PAYMENT INFO CARD
  // ═══════════════════════════════════════

  Widget _buildPaymentCard(OrderModel order, NumberFormat fmt) {
    final isCash = order.paymentMethod?.toLowerCase() == 'cash';
    final isPaid = order.isPaid;
    final payLabel =
        isCash ? 'Cash on Delivery' : (isPaid ? 'Paid Online' : 'Pending');
    final payColor =
        isCash ? Colors.orange : (isPaid ? const Color(0xFF2E7D32) : Colors.orange);

    return _accentCard(
      title: 'Payment',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.paymentMethod?.toUpperCase() ?? 'N/A',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: payColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(payLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: payColor)),
              ),
            ],
          ),
          Text(
            fmt.format(order.totalAmount),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // NEED HELP BUTTON
  // ═══════════════════════════════════════

  Widget _buildNeedHelpButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'Need Help?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CARD BUILDERS
  // ═══════════════════════════════════════

  /// Plain white card (no accent border)
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  /// Card with green left accent border (like reference)
  Widget _accentCard({
    required String title,
    required Widget child,
    Color titleColor = Colors.black87,
    Widget? bottomChild,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFF2E7D32), width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
          if (bottomChild != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: bottomChild,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// CUSTOM MAP PAINTER
// ═══════════════════════════════════════

class _LiveMapPainter extends CustomPainter {
  final double riderProgress;

  _LiveMapPainter({required this.riderProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft map background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8F5E9),
    );

    // Subtle grid roads
    final roadPaint = Paint()
      ..color = const Color(0xFFD5E8D5)
      ..strokeWidth = 1;
    for (var i = 1; i <= 5; i++) {
      final y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    for (var i = 1; i <= 6; i++) {
      final x = size.width * (i / 7);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Main road
    final mainRoad = Path();
    mainRoad.moveTo(size.width * 0.12, size.height * 0.78);
    mainRoad.quadraticBezierTo(
        size.width * 0.35, size.height * 0.5,
        size.width * 0.55, size.height * 0.42);
    mainRoad.quadraticBezierTo(
        size.width * 0.75, size.height * 0.34,
        size.width * 0.88, size.height * 0.22);

    // Road background
    canvas.drawPath(
      mainRoad,
      Paint()
        ..color = const Color(0xFFCCDFCC)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Green route
    canvas.drawPath(
      mainRoad,
      Paint()
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Store marker
    final storePos = Offset(size.width * 0.12, size.height * 0.78);
    canvas.drawCircle(
        storePos, 12, Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.2));
    canvas.drawCircle(storePos, 8, Paint()..color = Colors.white);
    canvas.drawCircle(storePos, 5, Paint()..color = const Color(0xFF2E7D32));

    // Destination pin
    final destPos = Offset(size.width * 0.88, size.height * 0.22);
    // Pin shadow
    canvas.drawCircle(
        destPos.translate(0, 3), 7, Paint()..color = Colors.black.withValues(alpha: 0.1));
    // Pin body
    canvas.drawCircle(destPos, 10, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(destPos, 4, Paint()..color = Colors.white);

    // "Your Address" label
    final labelBg = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: destPos.translate(0, -22), width: 90, height: 22),
      const Radius.circular(4),
    );
    canvas.drawRRect(labelBg, Paint()..color = Colors.white);
    canvas.drawRRect(
      labelBg,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Rider on route
    final metrics = mainRoad.computeMetrics().first;
    final riderTangent =
        metrics.getTangentForOffset(metrics.length * riderProgress);
    if (riderTangent != null) {
      final pos = riderTangent.position;
      // Glow
      canvas.drawCircle(
          pos, 16, Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.12));
      // White bg
      canvas.drawCircle(pos, 11, Paint()..color = Colors.white);
      // Green fill
      canvas.drawCircle(pos, 8, Paint()..color = const Color(0xFF2E7D32));
      // Simple bike shape
      final bp = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos.translate(-2.5, 1), 2, bp);
      canvas.drawCircle(pos.translate(2.5, 1), 2, bp);
      canvas.drawLine(pos.translate(-2.5, 1), pos.translate(0, -2.5), bp);
      canvas.drawLine(pos.translate(0, -2.5), pos.translate(2.5, 1), bp);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveMapPainter old) =>
      old.riderProgress != riderProgress;
}
