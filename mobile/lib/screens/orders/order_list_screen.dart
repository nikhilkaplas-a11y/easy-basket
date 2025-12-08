import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import 'package:intl/intl.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool _hasLoaded = false;
  String? _selectedOrderStatus; // null means "All"
  String? _selectedTimeFilter; // null means "All"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    if (_hasLoaded) return;
    
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      _hasLoaded = true;
      if (kDebugMode) {
        print('🔄 Loading orders...');
      }
      orderProvider.fetchOrders(authProvider.token!);
    }
  }

  String _getPaymentStatusText(OrderModel order) {
    if (order.paymentMethod?.toLowerCase() == 'cash') {
      return 'Cash on Delivery';
    }
    if (order.isPaid) {
      return 'Paid';
    }
    return 'Pending';
  }

  bool _hasActiveFilters() {
    return _selectedOrderStatus != null || _selectedTimeFilter != null;
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    
    return orders.where((order) {
      // Filter by order status
      if (_selectedOrderStatus != null && order.status != _selectedOrderStatus) {
        return false;
      }
      
      // Filter by time period
      if (_selectedTimeFilter != null) {
        final orderDate = order.createdAt;
        final daysDiff = now.difference(orderDate).inDays;
        
        switch (_selectedTimeFilter) {
          case 'today':
            // Check if order was created today (same day, month, year)
            if (orderDate.day != now.day || 
                orderDate.month != now.month || 
                orderDate.year != now.year) {
              return false;
            }
            break;
          case 'last_7_days':
            if (daysDiff > 7) {
              return false;
            }
            break;
          case 'last_30_days':
            if (daysDiff > 30) {
              return false;
            }
            break;
          case 'last_3_months':
            if (daysDiff > 90) {
              return false;
            }
            break;
        }
      }
      
      return true;
    }).toList();
  }

  Widget _buildOrderList(OrderProvider orderProvider, NumberFormat currencyFormat) {
    final filteredOrders = _getFilteredOrders(orderProvider.orders);
    
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.token != null) {
          await orderProvider.fetchOrders(authProvider.token!);
        }
      },
      child: Column(
        children: [
          // Filter Section - Redesigned with better UI/UX
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Filters Indicator
                if (_hasActiveFilters())
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.lightGrey.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.filter_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${filteredOrders.length} of ${orderProvider.orders.length} orders',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'RoundedSans',
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedOrderStatus = null;
                              _selectedTimeFilter = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primaryGreen, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close, size: 14, color: AppTheme.primaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'RoundedSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Filter Chips Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Status Section
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 16,
                            color: AppTheme.grey.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.grey.withOpacity(0.8),
                              fontFamily: 'RoundedSans',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildModernFilterChip(
                              'All',
                              null,
                              Icons.apps,
                              _selectedOrderStatus == null,
                              (value) {
                                setState(() => _selectedOrderStatus = null);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Pending',
                              'pending',
                              Icons.pending,
                              _selectedOrderStatus == 'pending',
                              (value) {
                                setState(() => _selectedOrderStatus = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Accepted',
                              'accepted',
                              Icons.check_circle_outline,
                              _selectedOrderStatus == 'accepted',
                              (value) {
                                setState(() => _selectedOrderStatus = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Preparing',
                              'preparing',
                              Icons.restaurant,
                              _selectedOrderStatus == 'preparing',
                              (value) {
                                setState(() => _selectedOrderStatus = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Out for Delivery',
                              'out_for_delivery',
                              Icons.delivery_dining,
                              _selectedOrderStatus == 'out_for_delivery',
                              (value) {
                                setState(() => _selectedOrderStatus = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Delivered',
                              'delivered',
                              Icons.check_circle,
                              _selectedOrderStatus == 'delivered',
                              (value) {
                                setState(() => _selectedOrderStatus = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Cancelled',
                              'cancelled',
                              Icons.cancel,
                              _selectedOrderStatus == 'cancelled',
                              (value) {
                                setState(() => _selectedOrderStatus = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Time Period Section
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.grey.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Time Period',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.grey.withOpacity(0.8),
                              fontFamily: 'RoundedSans',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildModernFilterChip(
                              'All Time',
                              null,
                              Icons.all_inclusive,
                              _selectedTimeFilter == null,
                              (value) {
                                setState(() => _selectedTimeFilter = null);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Today',
                              'today',
                              Icons.today,
                              _selectedTimeFilter == 'today',
                              (value) {
                                setState(() => _selectedTimeFilter = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Last 7 Days',
                              'last_7_days',
                              Icons.calendar_view_week,
                              _selectedTimeFilter == 'last_7_days',
                              (value) {
                                setState(() => _selectedTimeFilter = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Last 30 Days',
                              'last_30_days',
                              Icons.calendar_month,
                              _selectedTimeFilter == 'last_30_days',
                              (value) {
                                setState(() => _selectedTimeFilter = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildModernFilterChip(
                              'Last 3 Months',
                              'last_3_months',
                              Icons.calendar_today,
                              _selectedTimeFilter == 'last_3_months',
                              (value) {
                                setState(() => _selectedTimeFilter = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Orders List
          filteredOrders.isEmpty && orderProvider.orders.isNotEmpty
              ? Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_off,
                            size: 80,
                            color: AppTheme.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.grey,
                              fontFamily: 'RoundedSans',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try selecting a different filter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.grey.withOpacity(0.7),
                              fontFamily: 'RoundedSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order, currencyFormat);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(
    String label,
    String? value,
    IconData icon,
    bool isSelected,
    Function(String?) onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : AppTheme.lightGrey,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                fontFamily: 'RoundedSans',
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.lightGrey.withOpacity(0.3),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'RoundedSans',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: orderProvider.isLoading && orderProvider.orders.isEmpty
          ? _buildLoadingState()
          : orderProvider.error != null && orderProvider.orders.isEmpty
              ? _buildErrorState(orderProvider)
              : _buildOrderList(orderProvider, currencyFormat),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your orders...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.grey,
              fontFamily: 'RoundedSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OrderProvider orderProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey,
                fontFamily: 'RoundedSans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              orderProvider.error ?? 'Failed to load orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey,
                fontFamily: 'RoundedSans',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _hasLoaded = false);
                _loadOrders();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.grey,
                fontFamily: 'RoundedSans',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start shopping to see your orders here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.grey.withOpacity(0.7),
                fontFamily: 'RoundedSans',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, NumberFormat currencyFormat) {
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/order/${order.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Order ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 20,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Order #${order.id}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatISTDefault(order.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.grey,
                                  fontFamily: 'RoundedSans',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontFamily: 'RoundedSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Product Preview
                if (order.items.isNotEmpty) ...[
                  Container(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: order.items.length > 3 ? 3 : order.items.length,
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return Container(
                          margin: EdgeInsets.only(right: index < order.items.length - 1 ? 8 : 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.product.imageUrl != null
                                ? Image.network(
                                    item.product.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: AppTheme.lightGrey,
                                      child: Icon(
                                        Icons.image,
                                        color: AppTheme.grey,
                                        size: 24,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: AppTheme.lightGrey,
                                    child: Icon(
                                      Icons.image,
                                      color: AppTheme.grey,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (order.items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${order.items.length - 3} more items',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                          fontFamily: 'RoundedSans',
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                // Divider
                Divider(
                  color: AppTheme.lightGrey,
                  height: 1,
                ),
                const SizedBox(height: 12),
                // Footer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Payment Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              order.paymentMethod?.toLowerCase() == 'cash'
                                  ? Icons.money
                                  : Icons.payment,
                              size: 14,
                              color: AppTheme.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPaymentStatusText(order),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey,
                                fontFamily: 'RoundedSans',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                      ],
                    ),
                    // Total Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(order.totalAmount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            fontFamily: 'RoundedSans',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/order/${order.id}'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'preparing':
        return Colors.blue;
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return AppTheme.primaryGreen;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

