import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

enum PaymentStatus {
  success,
  failed,
  pending,
  orderPlaced, // For COD orders - order placed but payment pending
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

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/orders');
      }
    });
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case PaymentStatus.success:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.orderPlaced:
        return AppTheme.primaryGreen; // Use app theme color for order confirmation
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case PaymentStatus.success:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.orderPlaced:
        return Icons.shopping_bag_rounded; // Shopping bag for order placed
    }
  }

  String _getStatusTitle() {
    switch (widget.status) {
      case PaymentStatus.success:
        return 'Payment Successful!';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.orderPlaced:
        return 'Order Placed!'; // Clear title for COD orders
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon with gradient for order placed
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: widget.status == PaymentStatus.orderPlaced
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getStatusColor().withOpacity(0.2),
                              _getStatusColor().withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: widget.status == PaymentStatus.orderPlaced
                        ? null
                        : _getStatusColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: widget.status == PaymentStatus.orderPlaced
                        ? [
                            BoxShadow(
                              color: _getStatusColor().withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    size: 64,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Status Title
                Text(
                  _getStatusTitle(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.status == PaymentStatus.orderPlaced
                        ? AppTheme.grey
                        : Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // COD-specific info card
                if (widget.status == PaymentStatus.orderPlaced) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.money_rounded,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash on Delivery',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please keep exact change ready',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                // Order ID if available
                if (widget.orderId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Order #${widget.orderId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 48),
                
                // Loading indicator for auto-redirect
                const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Redirecting to orders...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Manual redirect button
                ElevatedButton(
                  onPressed: () => context.go('/orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('View Orders'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

