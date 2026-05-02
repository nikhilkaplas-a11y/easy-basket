import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/delivery_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/date_utils.dart';
import 'package:intl/intl.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.accessToken != null) {
        final token = authProvider.accessToken!;
        deliveryProvider.fetchStats(token: token);
        deliveryProvider.fetchOrders(token: token);
        deliveryProvider.fetchAvailableOrders(token: token);
        deliveryProvider.fetchWallet(token: token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryProvider = Provider.of<DeliveryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final token = authProvider.accessToken;
              if (token != null) {
                deliveryProvider.fetchStats(token: token);
                deliveryProvider.fetchOrders(token: token);
                deliveryProvider.fetchAvailableOrders(token: token);
                deliveryProvider.fetchWallet(token: token);
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true && context.mounted) {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final token = authProvider.accessToken;
          if (token != null) {
            await deliveryProvider.fetchStats(token: token);
            await deliveryProvider.fetchOrders(token: token);
            await deliveryProvider.fetchAvailableOrders(token: token);
            await deliveryProvider.fetchWallet(token: token);
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BIG wallet card — first thing the rider sees on dashboard.
              // Cash-in-hand is the number that matters most: it's what they
              // owe the company and need to deposit at end of day.
              _WalletCard(wallet: deliveryProvider.wallet),

              // Stats Cards
              if (deliveryProvider.stats != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _StatCard(
                        title: 'Total Deliveries',
                        value: '${deliveryProvider.stats!['total'] ?? 0}',
                        icon: Icons.local_shipping,
                        color: AppTheme.primaryGreen,
                      ),
                      _StatCard(
                        title: 'Pending',
                        value: '${deliveryProvider.stats!['pending'] ?? 0}',
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        title: 'Today',
                        value: '${deliveryProvider.stats!['today'] ?? 0}',
                        icon: Icons.today,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Completed',
                        value: '${deliveryProvider.stats!['completed'] ?? 0}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              
              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'New Orders',
                            icon: Icons.add_shopping_cart,
                            color: AppTheme.primaryGreen,
                            onTap: () => context.push('/delivery/orders?status=accepted'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            title: 'Out for Delivery',
                            icon: Icons.delivery_dining,
                            color: Colors.orange,
                            onTap: () => context.push('/delivery/orders?status=out_for_delivery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Available Orders (Unassigned)
              if (deliveryProvider.availableOrders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${deliveryProvider.availableOrders.length}',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: deliveryProvider.availableOrders.length > 3 ? 3 : deliveryProvider.availableOrders.length,
                        itemBuilder: (context, index) {
                          final order = deliveryProvider.availableOrders[index];
                          return _AvailableOrderCard(order: order);
                        },
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Recent Orders
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/delivery/orders'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              
              if (deliveryProvider.isLoading && deliveryProvider.orders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (deliveryProvider.orders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 64, color: AppTheme.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No orders assigned',
                          style: TextStyle(color: AppTheme.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: deliveryProvider.orders.length > 5 ? 5 : deliveryProvider.orders.length,
                  itemBuilder: (context, index) {
                    final order = deliveryProvider.orders[index];
                    return _OrderCard(order: order);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/delivery/order/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
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
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.deliveryAddress.addressLine1}, ${order.deliveryAddress.city}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Row(
                    children: [
                      // Quick navigation button if coordinates available
                      if (order.deliveryAddress?.latitude != null && order.deliveryAddress?.longitude != null)
                        IconButton(
                          icon: const Icon(Icons.navigation, size: 20, color: AppTheme.primaryGreen),
                          onPressed: () async {
                            final lat = double.parse(order.deliveryAddress.latitude!);
                            final lng = double.parse(order.deliveryAddress.longitude!);
                            final url = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          tooltip: 'Get Directions',
                        ),
                      Text(
                        formatISTShort(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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

class _AvailableOrderCard extends StatelessWidget {
  final dynamic order;

  const _AvailableOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${order.user.name ?? order.user.phoneNumber}',
              style: TextStyle(fontSize: 14, color: AppTheme.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.deliveryAddress.addressLine1}, ${order.deliveryAddress.city}',
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (authProvider.accessToken != null) {
                      final success = await deliveryProvider.acceptOrder(
                        token: authProvider.accessToken!,
                        orderId: order.id,
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order accepted successfully!')),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(deliveryProvider.error ?? 'Failed to accept order')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Big "Cash In Hand" card displayed at the top of the rider dashboard.
///
/// Reads `wallet.cashInHandPaise` (paise -> rupees) and shows it large so a
/// rider glancing at the screen mid-shift can immediately see how much cash
/// they're carrying. Lifetime collected/deposited shown as small chips below.
class _WalletCard extends StatelessWidget {
  final Map<String, dynamic>? wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final cashPaise = (wallet?['cashInHandPaise'] as num?)?.toInt() ?? 0;
    final lifetimeCollectedPaise =
        (wallet?['lifetimeCollectedPaise'] as num?)?.toInt() ?? 0;
    final lifetimeDepositedPaise =
        (wallet?['lifetimeDepositedPaise'] as num?)?.toInt() ?? 0;

    String fmt(int paise) {
      final rupees = paise / 100.0;
      return NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(rupees);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet,
                  color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'CASH IN HAND',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            wallet == null ? '—' : fmt(cashPaise),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Deposit to admin at end of shift',
            style: TextStyle(
              color: Color(0xFFC8E6C9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (wallet != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _MiniStat(
                  label: 'Collected',
                  value: fmt(lifetimeCollectedPaise),
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: 'Deposited',
                  value: fmt(lifetimeDepositedPaise),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFC8E6C9),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

