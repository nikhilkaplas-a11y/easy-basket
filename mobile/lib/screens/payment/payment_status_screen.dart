import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';

enum PaymentStatus {
  success,
  failed,
  pending,
  orderPlaced,
}

class PaymentStatusScreen extends StatefulWidget {
  final PaymentStatus status;
  final String message;
  final int? orderId;

  const PaymentStatusScreen({
    super.key,
    required this.status,
    required this.message,
    this.orderId,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    if (!kIsWeb &&
        (widget.status == PaymentStatus.success ||
            widget.status == PaymentStatus.orderPlaced)) {
      NotificationService().requestNotificationPermission();
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _navigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate() {
    final isSuccess = widget.status == PaymentStatus.success ||
        widget.status == PaymentStatus.orderPlaced;
    if (isSuccess && widget.orderId != null) {
      context.go('/order/${widget.orderId}');
    } else {
      context.go('/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.status == PaymentStatus.success ||
        widget.status == PaymentStatus.orderPlaced;
    final color = isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935);
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
    final title = isSuccess ? 'Order Placed!' : 'Payment Failed';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(icon, size: 80, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
