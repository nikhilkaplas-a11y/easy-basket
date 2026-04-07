import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isScreenActive = true;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      _loadInitialData();
      _startAutoRefresh();
    }
  }

  void _loadInitialData() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      adminProvider.fetchStats(token: authProvider.token);
      _lastRefreshTime = DateTime.now();
    }
  }

  void _startAutoRefresh() {
    // Cancel existing timer
    _refreshTimer?.cancel();
    
    // Start new timer - refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isScreenActive && mounted) {
        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        if (authProvider.token != null) {
          // Silent refresh - no loading indicator
          adminProvider.fetchStats(token: authProvider.token);
          _lastRefreshTime = DateTime.now();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              adminProvider.fetchStats(token: authProvider.token);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'refresh_fcm') {
                if (kIsWeb) return;
                
                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                  
                  // Initialize or refresh notification service
                  await NotificationService().initialize(
                    context: context,
                    adminProvider: adminProvider,
                    authProvider: authProvider,
                  );
                  
                  // Ensure token is sent
                  await NotificationService().ensureTokenSent();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FCM token refreshed and sent to backend'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error refreshing FCM token: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error refreshing FCM token: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else if (value == 'logout') {
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
              if (!kIsWeb)
                PopupMenuItem(
                  value: 'refresh_fcm',
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh FCM Token'),
                    ],
                  ),
                ),
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
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await adminProvider.fetchStats(token: authProvider.token);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Overview
              if (adminProvider.stats != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Last refresh indicator
                          if (_lastRefreshTime != null)
                            Text(
                              'Updated ${_formatLastRefresh(_lastRefreshTime!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.grey.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        children: [
                          _StatCard(
                            title: 'Total Orders',
                            value: '${adminProvider.stats!['orders']?['total'] ?? 0}',
                            icon: Icons.shopping_bag,
                            color: AppTheme.primaryGreen,
                          ),
                          _StatCard(
                            title: 'Pending Orders',
                            value: '${adminProvider.stats!['orders']?['pending'] ?? 0}',
                            icon: Icons.pending,
                            color: Colors.orange,
                          ),
                          _StatCard(
                            title: "Today's Orders",
                            value: '${adminProvider.stats!['orders']?['today'] ?? 0}',
                            icon: Icons.today,
                            color: Colors.blue,
                          ),
                          _StatCard(
                            title: 'Total Users',
                            value: '${adminProvider.stats!['users']?['total'] ?? 0}',
                            icon: Icons.people,
                            color: Colors.purple,
                          ),
                          _StatCard(
                            title: 'Total Products',
                            value: '${adminProvider.stats!['products']?['total'] ?? 0}',
                            icon: Icons.inventory,
                            color: Colors.teal,
                          ),
                          _StatCard(
                            title: 'Low Stock',
                            value: '${adminProvider.stats!['products']?['lowStock'] ?? 0}',
                            icon: Icons.warning,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Revenue Card
                      Card(
                        color: AppTheme.primaryGreen,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Today's Revenue",
                                    style: TextStyle(
                                      color: AppTheme.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFormat.format(
                                      (adminProvider.stats!['revenue']?['today'] ?? 0).toDouble(),
                                    ),
                                    style: const TextStyle(
                                      color: AppTheme.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.currency_rupee,
                                color: AppTheme.white,
                                size: 48,
                              ),
                            ],
                          ),
                        ),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _ActionCard(
                          title: 'Orders',
                          icon: Icons.shopping_bag,
                          color: AppTheme.primaryGreen,
                          onTap: () => context.push('/admin/orders'),
                        ),
                        _ActionCard(
                          title: 'Users',
                          icon: Icons.people,
                          color: Colors.blue,
                          onTap: () => context.push('/admin/users'),
                        ),
                        _ActionCard(
                          title: 'Products',
                          icon: Icons.inventory,
                          color: Colors.orange,
                          onTap: () => context.push('/admin/products'),
                        ),
                        _ActionCard(
                          title: 'Categories',
                          icon: Icons.category,
                          color: Colors.purple,
                          onTap: () => context.push('/admin/categories'),
                        ),
                        _ActionCard(
                          title: 'Category Order',
                          icon: Icons.sort,
                          color: Colors.teal,
                          onTap: () => context.push('/admin/categories/order'),
                        ),
                        _ActionCard(
                          title: 'Campaigns',
                          icon: Icons.campaign,
                          color: Colors.deepOrange,
                          onTap: () => context.push('/admin/campaigns'),
                        ),
                        _ActionCard(
                          title: 'Push Notify',
                          icon: Icons.notifications_active,
                          color: Colors.red,
                          onTap: () => context.push('/admin/notifications'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastRefresh(DateTime lastRefresh) {
    final now = DateTime.now();
    final difference = now.difference(lastRefresh);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.grey,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
            mainAxisSize: MainAxisSize.min, // Use min to prevent overflow
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

