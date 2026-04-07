import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/navigation_utils.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  bool _hasFetched = false;
  Timer? _pollingTimer;
  late AnimationController _pulseController;
  late AnimationController _riderController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _riderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrder();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    _riderController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final currencyFormat =
        NumberFormat.currency(symbol: '\u20B9', decimalDigits: 0);
    final order = orderProvider.orders
        .where((o) => o.id == widget.orderId)
        .firstOrNull;

    if (order == null && !_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fetchOrder());
    }

    if (order == null) {
      return popScopeWithRoleHubFallback(
        context,
        Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildLoadingAppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen)),
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

    return popScopeWithRoleHubFallback(
      context,
      Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(order),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatusCard(order),
                  const SizedBox(height: 14),
                  _buildHorizontalProgressTracker(order),
                  const SizedBox(height: 14),
                  if (order.status == 'out_for_delivery') ...[
                    _buildDeliveryPartnerCard(order),
                    const SizedBox(height: 14),
                    _buildLiveMapCard(order),
                    const SizedBox(height: 14),
                  ],
                  _buildOrderDetailsCard(order, currencyFormat),
                  const SizedBox(height: 14),
                  _buildDeliveryAddressCard(order),
                  const SizedBox(height: 14),
                  _buildSupportSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════

  PreferredSizeWidget _buildLoadingAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: const Text('Track Order',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Colors.black87)),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => popOrRoleHub(context)),
    );
  }

  Widget _buildSliverAppBar(OrderModel order) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 120,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => popOrRoleHub(context),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.black87, size: 20),
          ),
        ),
      ),
      title: const Text(
        'Track Order',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.black87,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#EB${order.id.toString().padLeft(6, '0')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getHelperText(order.status),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // ORDER STATUS CARD
  // ═══════════════════════════════════════

  Widget _buildStatusCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final isCancelled = order.status == 'cancelled';
    final isDelivered = order.status == 'delivered';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Icon with pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale =
                  (isCancelled || isDelivered) ? 1.0 : 1.0 + (_pulseController.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: statusColor,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                if (!isCancelled && !isDelivered) ...[
                  Text(
                    _getETAText(order.status),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getTimeRange(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ] else ...[
                  Text(
                    _getStatusDescription(order.status),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
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
  // HORIZONTAL PROGRESS TRACKER
  // ═══════════════════════════════════════

  Widget _buildHorizontalProgressTracker(OrderModel order) {
    final steps = [
      {'key': 'pending', 'label': 'Placed', 'icon': Icons.receipt_rounded},
      {'key': 'preparing', 'label': 'Packed', 'icon': Icons.inventory_2_rounded},
      {
        'key': 'out_for_delivery',
        'label': 'On the Way',
        'icon': Icons.delivery_dining_rounded
      },
      {
        'key': 'delivered',
        'label': 'Delivered',
        'icon': Icons.check_circle_rounded
      },
    ];

    final statusOrder = ['pending', 'accepted', 'preparing', 'out_for_delivery', 'delivered'];
    final currentIndex = statusOrder.indexOf(order.status);
    final isCancelled = order.status == 'cancelled';

    // Map step keys to their position in statusOrder for comparison
    int stepPosition(String key) => statusOrder.indexOf(key);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isCancelled
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cancel_rounded,
                      color: Colors.red, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Cancelled',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.red)),
                      SizedBox(height: 2),
                      Text('This order has been cancelled',
                          style:
                              TextStyle(fontSize: 12, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // Progress bar
                Row(
                  children: List.generate(steps.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      // Connector line
                      final leftStepIdx = index ~/ 2;
                      final leftStepPos =
                          stepPosition(steps[leftStepIdx]['key'] as String);
                      final isCompleted = currentIndex > leftStepPos;
                      return Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.primaryGreen
                                : const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }
                    // Step dot
                    final stepIdx = index ~/ 2;
                    final step = steps[stepIdx];
                    final stepPos =
                        stepPosition(step['key'] as String);
                    final isCompleted = currentIndex >= stepPos;
                    final isCurrent = currentIndex == stepPos ||
                        (step['key'] == 'preparing' &&
                            order.status == 'accepted');

                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.primaryGreen
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: isCompleted ? Colors.white : Colors.grey[400],
                        size: 20,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                // Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: steps.map((step) {
                    final stepPos =
                        stepPosition(step['key'] as String);
                    final isCompleted = currentIndex >= stepPos;
                    final isCurrent = currentIndex == stepPos ||
                        (step['key'] == 'preparing' &&
                            order.status == 'accepted');
                    return SizedBox(
                      width: 64,
                      child: Text(
                        step['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCompleted
                              ? Colors.black87
                              : Colors.grey[400],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════
  // DELIVERY PARTNER CARD
  // ═══════════════════════════════════════

  Widget _buildDeliveryPartnerCard(OrderModel order) {
    final partnerName = order.deliveryBoy?.name ?? 'Sami H.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your Delivery Partner',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.navigation_rounded,
                        size: 12, color: AppTheme.primaryGreen.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'Heading to your location',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionButton(Icons.phone_rounded, AppTheme.primaryGreen, () {}),
              const SizedBox(width: 10),
              _actionButton(Icons.chat_rounded, const Color(0xFF2196F3), () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ═══════════════════════════════════════
  // LIVE MAP SECTION
  // ═══════════════════════════════════════

  Widget _buildLiveMapCard(OrderModel order) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map background
            AnimatedBuilder(
              animation: _riderController,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter: _LiveMapPainter(
                    riderProgress: _riderController.value,
                  ),
                );
              },
            ),
            // Overlay info
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '1.2 km away',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\u2022',
                      style: TextStyle(color: Colors.grey[300], fontSize: 8),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Arriving in 12 mins',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Live badge
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen
                                .withValues(alpha: 0.5 + _pulseController.value * 0.5),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryGreen,
                        letterSpacing: 0.5,
                      ),
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

  // ═══════════════════════════════════════
  // ORDER DETAILS CARD
  // ═══════════════════════════════════════

  Widget _buildOrderDetailsCard(OrderModel order, NumberFormat currencyFormat) {
    // Calculate subtotal from items
    final subtotal = order.items.fold<double>(0, (sum, item) => sum + item.total);
    final deliveryFee = order.totalAmount - subtotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_rounded,
                    color: AppTheme.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Order Details',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const Spacer(),
              Text('${order.items.length} items',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 16),
          // Items
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Product image
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.product.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor: AlwaysStoppedAnimation(
                                            AppTheme.primaryGreen))),
                                errorWidget: (_, __, ___) => Icon(
                                    Icons.image_rounded,
                                    color: Colors.grey[300],
                                    size: 20),
                              )
                            : Icon(Icons.image_rounded,
                                color: Colors.grey[300], size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Item name & variant
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.displayLabel != null ||
                              item.variant != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.displayLabel ??
                                  item.variant?.label ??
                                  '',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Quantity
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Price
                    Text(
                      currencyFormat.format(item.total),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87),
                    ),
                  ],
                ),
              )),
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 1,
            color: const Color(0xFFF0F0F0),
          ),
          // Subtotal
          _priceRow('Subtotal', currencyFormat.format(subtotal)),
          const SizedBox(height: 6),
          _priceRow(
              'Delivery Fee',
              deliveryFee > 0
                  ? currencyFormat.format(deliveryFee)
                  : 'FREE'),
          const SizedBox(height: 12),
          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
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
                  currencyFormat.format(order.totalAmount),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    final isFree = value == 'FREE';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500])),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isFree ? AppTheme.primaryGreen : Colors.black87)),
      ],
    );
  }

  // ═══════════════════════════════════════
  // DELIVERY ADDRESS CARD
  // ═══════════════════════════════════════

  Widget _buildDeliveryAddressCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppTheme.primaryGreen, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Delivering To',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 14),
          // Address content
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home_rounded,
                    color: Colors.grey[400], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.deliveryAddress.tag != null) ...[
                        Text(
                          order.deliveryAddress.tag!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        order.deliveryAddress.fullAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      if (order.notes != null && order.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.notes!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
  // SUPPORT SECTION
  // ═══════════════════════════════════════

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Need help with your order?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _supportButton(
                  Icons.headset_mic_rounded,
                  'Contact Support',
                  () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _supportButton(
                  Icons.report_problem_rounded,
                  'Report Issue',
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supportButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════

  String _getHelperText(String status) {
    switch (status) {
      case 'pending':
        return 'Your order is being processed';
      case 'accepted':
        return 'Your order has been confirmed';
      case 'preparing':
        return 'Your order is being packed';
      case 'out_for_delivery':
        return 'Your order is on the way';
      case 'delivered':
        return 'Your order has been delivered';
      case 'cancelled':
        return 'Your order was cancelled';
      default:
        return 'Order status update';
    }
  }

  String _getETAText(String status) {
    switch (status) {
      case 'pending':
        return 'Estimated delivery in 25 mins';
      case 'accepted':
        return 'Estimated delivery in 20 mins';
      case 'preparing':
        return 'Estimated delivery in 15 mins';
      case 'out_for_delivery':
        return 'Arriving in 12 mins';
      default:
        return '';
    }
  }

  String _getTimeRange() {
    final now = DateTime.now();
    final start = now.add(const Duration(minutes: 10));
    final end = now.add(const Duration(minutes: 20));
    final format = DateFormat('h:mm a');
    return '${format.format(start)} - ${format.format(end)}';
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'delivered':
        return 'Your order has been delivered successfully';
      case 'cancelled':
        return 'This order has been cancelled';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
        return const Color(0xFF2196F3);
      case 'preparing':
        return const Color(0xFF1565C0);
      case 'out_for_delivery':
        return AppTheme.primaryGreen;
      case 'delivered':
        return AppTheme.primaryGreen;
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'preparing':
        return Icons.inventory_2_rounded;
      case 'out_for_delivery':
        return Icons.delivery_dining_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
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
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF0F4F0),
    );

    // Draw subtle grid roads
    final roadPaint = Paint()
      ..color = const Color(0xFFE4E8E4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    for (var i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        roadPaint,
      );
    }

    // Vertical roads
    for (var i = 1; i <= 5; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        roadPaint,
      );
    }

    // Main road (wider)
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFDDE3DD)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mainRoadPath = Path();
    mainRoadPath.moveTo(size.width * 0.15, size.height * 0.75);
    mainRoadPath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.55,
      size.height * 0.45,
    );
    mainRoadPath.quadraticBezierTo(
      size.width * 0.72,
      size.height * 0.35,
      size.width * 0.85,
      size.height * 0.25,
    );
    canvas.drawPath(mainRoadPath, mainRoadPaint);

    // Route line (green dashed)
    final routePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(mainRoadPath, routePaint);

    // Store marker
    _drawStoreMarker(canvas, Offset(size.width * 0.15, size.height * 0.75));

    // Destination marker
    _drawDestinationMarker(
        canvas, Offset(size.width * 0.85, size.height * 0.25));

    // Rider marker (animated along path)
    final metrics = mainRoadPath.computeMetrics().first;
    final riderOffset =
        metrics.getTangentForOffset(metrics.length * riderProgress);
    if (riderOffset != null) {
      _drawRiderMarker(canvas, riderOffset.position);
    }
  }

  void _drawStoreMarker(Canvas canvas, Offset center) {
    // Outer circle
    canvas.drawCircle(
      center,
      14,
      Paint()..color = const Color(0xFF4CAF50).withValues(alpha: 0.15),
    );
    // Inner circle
    canvas.drawCircle(
      center,
      9,
      Paint()..color = Colors.white,
    );
    // Store icon (simple rectangle)
    canvas.drawCircle(
      center,
      6,
      Paint()..color = const Color(0xFF4CAF50),
    );
    // Store icon detail
    final storePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 7, height: 5),
      storePaint,
    );
  }

  void _drawDestinationMarker(Canvas canvas, Offset center) {
    // Shadow
    canvas.drawCircle(
      center.translate(0, 3),
      8,
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );
    // Pin drop
    final pinPath = Path();
    pinPath.addOval(Rect.fromCircle(center: center, radius: 10));
    canvas.drawPath(
      pinPath,
      Paint()..color = const Color(0xFFE53935),
    );
    // White dot
    canvas.drawCircle(
      center,
      4,
      Paint()..color = Colors.white,
    );
  }

  void _drawRiderMarker(Canvas canvas, Offset center) {
    // Glow
    canvas.drawCircle(
      center,
      18,
      Paint()..color = const Color(0xFF4CAF50).withValues(alpha: 0.12),
    );
    // White background
    canvas.drawCircle(
      center,
      13,
      Paint()..color = Colors.white,
    );
    // Green circle
    canvas.drawCircle(
      center,
      10,
      Paint()..color = const Color(0xFF4CAF50),
    );
    // Bike icon (simplified as two small circles + frame)
    final bikePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Left wheel
    canvas.drawCircle(center.translate(-3, 1), 2.5, bikePaint);
    // Right wheel
    canvas.drawCircle(center.translate(3, 1), 2.5, bikePaint);
    // Frame
    canvas.drawLine(
      center.translate(-3, 1),
      center.translate(0, -3),
      bikePaint,
    );
    canvas.drawLine(
      center.translate(0, -3),
      center.translate(3, 1),
      bikePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LiveMapPainter oldDelegate) {
    return oldDelegate.riderProgress != riderProgress;
  }
}
