import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../models/order_model.dart';

class DeliveryOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const DeliveryOrderDetailScreen({super.key, required this.orderId});

  @override
  State<DeliveryOrderDetailScreen> createState() => _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends State<DeliveryOrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    final order = await deliveryProvider.getOrderDetails(widget.orderId, token: token);
    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String status) async {
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.accessToken == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status to ${status.replaceAll('_', ' ').toUpperCase()}?'),
        content: const Text('This will notify the customer about the status change.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await deliveryProvider.updateOrderStatus(
        token: authProvider.accessToken!,
        orderId: widget.orderId,
        status: status,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully!')),
        );
        await _loadOrderDetails();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(deliveryProvider.error ?? 'Failed to update status')),
        );
      }
    }
  }

  Future<void> _openNavigation() async {
    if (_order == null) return;

    final address = _order!.deliveryAddress;
    
    // Use exact coordinates if available (more accurate for instant delivery)
    if (address.latitude != null && address.longitude != null) {
      try {
        final lat = double.parse(address.latitude!);
        final lng = double.parse(address.longitude!);
        
        // Open Google Maps with exact coordinates for turn-by-turn navigation
        final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'
        );
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open Google Maps')),
            );
          }
        }
      } catch (e) {
        // Fallback to text search if coordinate parsing fails
        _openNavigationWithText(address);
      }
    } else {
      // Fallback to text-based search if coordinates not available
      _openNavigationWithText(address);
    }
  }

  Future<void> _openNavigationWithText(dynamic address) async {
    final query = '${address.addressLine1}, ${address.city}, ${address.state} ${address.pincode}';
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Maps')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _viewOnMaps() async {
    if (_order == null) return;

    final address = _order!.deliveryAddress;
    
    // Use exact coordinates if available
    if (address.latitude != null && address.longitude != null) {
      try {
        final lat = double.parse(address.latitude!);
        final lng = double.parse(address.longitude!);
        
        // Navigate to map view screen with route
        context.push('/delivery/map', extra: {
          'destinationLat': lat,
          'destinationLng': lng,
          'destinationAddress': _order!.deliveryAddress.addressLine1,
          'orderId': _order!.id,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid coordinates')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address coordinates not available')),
        );
      }
    }
  }

  Future<void> _callCustomer() async {
    if (_order == null) return;

    final phoneNumber = _order!.user.phoneNumber;
    final url = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not make phone call')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Order not found')),
      );
    }

    final order = _order!;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _getStatusColor(order.status).withOpacity(0.1),
              child: Column(
                children: [
                  Text(
                    order.statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${currencyFormat.format(order.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Customer Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.user.name ?? 'Customer',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.user.phoneNumber,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call, color: AppTheme.primaryGreen),
                            onPressed: _callCustomer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Delivery Address
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                              Icons.location_on,
                              color: AppTheme.primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.deliveryAddress.addressLine1,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (order.deliveryAddress.addressLine2 != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                order.deliveryAddress.addressLine2!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${order.deliveryAddress.city}, ${order.deliveryAddress.state} - ${order.deliveryAddress.pincode}',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.grey,
                              ),
                            ),
                            if (order.deliveryAddress.landmark != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Landmark: ${order.deliveryAddress.landmark}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Show coordinates if available
                      if (order.deliveryAddress.latitude != null && order.deliveryAddress.longitude != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.gps_fixed, size: 14, color: AppTheme.primaryGreen),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${order.deliveryAddress.latitude}, ${order.deliveryAddress.longitude}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.grey,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Navigation buttons - Stack vertically on small screens
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // If width is less than 350, stack buttons vertically
                          if (constraints.maxWidth < 350) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _openNavigation,
                                    icon: const Icon(Icons.directions, size: 18),
                                    label: const Text('Get Directions'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: AppTheme.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _viewOnMaps,
                                    icon: const Icon(Icons.map, size: 18),
                                    label: const Text('View Map'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Horizontal layout for larger screens
                            return Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openNavigation,
                                    icon: const Icon(Icons.directions, size: 18),
                                    label: const Text('Get Directions'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: AppTheme.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _viewOnMaps,
                                    icon: const Icon(Icons.map, size: 18),
                                    label: const Text('View Map'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Order Items
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: item.product.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: item.product.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.image),
                                )
                              : const Icon(Icons.image),
                          title: Text(item.product.name),
                          subtitle: Text(
                            item.displayLabel != null
                                ? '${item.displayLabel} x ${currencyFormat.format(item.price)}'
                                : 'Qty: ${item.quantity} x ${currencyFormat.format(item.price)}',
                          ),
                          trailing: Text(
                            currencyFormat.format(item.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),

            // Action Buttons
            if (order.status != 'delivered' && order.status != 'cancelled')
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (order.status == 'accepted')
                      ElevatedButton(
                        onPressed: () => _updateStatus('preparing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Start Preparing'),
                      ),
                    if (order.status == 'preparing')
                      ElevatedButton(
                        onPressed: () => _updateStatus('out_for_delivery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Mark as Out for Delivery'),
                      ),
                    if (order.status == 'out_for_delivery')
                      ElevatedButton(
                        onPressed: () => _updateStatus('delivered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Mark as Delivered'),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
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

