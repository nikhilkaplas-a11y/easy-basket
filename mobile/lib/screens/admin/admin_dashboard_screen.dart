import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.token != null) {
        adminProvider.fetchStats(token: authProvider.token);
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
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
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

