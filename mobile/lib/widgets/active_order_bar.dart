import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';

/// Active order bar — shows at bottom of home screen when orders are in progress
/// Replaces cart bar when active orders exist (like Blinkit/Zepto)
class ActiveOrderBar extends StatelessWidget {
  const ActiveOrderBar({super.key});

  // Terminal states — order khatam
  static const _terminalStatuses = ['delivered', 'cancelled'];

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProvider, authProvider, _) {
        // Filter active orders only
        final activeOrders = orderProvider.orders
            .where((o) => !_terminalStatuses.contains(o.status))
            .toList();

        if (activeOrders.isEmpty) return const SizedBox.shrink();

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: activeOrders.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OrderBarItem(order: order),
              )).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _OrderBarItem extends StatelessWidget {
  final OrderModel order;

  const _OrderBarItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(order.status);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [statusInfo.color, statusInfo.color.withValues(alpha: 0.85)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: statusInfo.color.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusInfo.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order #${order.id} • ${statusInfo.label}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${currencyFormat.format(order.totalAmount)} • ${statusInfo.subtitle}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            // Track button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Track',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusInfo.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return _StatusInfo(
          label: 'Order Placed',
          subtitle: 'Confirming your order...',
          icon: Icons.schedule_rounded,
          color: const Color(0xFFFF9800), // orange
        );
      case 'accepted':
        return _StatusInfo(
          label: 'Confirmed',
          subtitle: 'Order accepted by store',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF2196F3), // blue
        );
      case 'preparing':
        return _StatusInfo(
          label: 'Preparing',
          subtitle: 'Being packed with care',
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF9C27B0), // purple
        );
      case 'out_for_delivery':
        return _StatusInfo(
          label: 'On the way',
          subtitle: 'Arriving soon!',
          icon: Icons.delivery_dining_rounded,
          color: const Color(0xFF0A5C18), // dark green
        );
      default:
        return _StatusInfo(
          label: 'Processing',
          subtitle: 'Please wait...',
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFF757575),
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  _StatusInfo({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
