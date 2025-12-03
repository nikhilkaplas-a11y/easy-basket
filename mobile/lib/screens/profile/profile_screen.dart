import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Icon(Icons.person, size: 50, color: AppTheme.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.user?.name ?? 'Customer',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.user?.phoneNumber ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.grey,
                      fontFamily: 'RoundedSans',
                    ),
                  ),
                  if (authProvider.user?.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      authProvider.user!.email!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.grey,
                        fontFamily: 'RoundedSans',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Menu Items
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('My Orders', style: TextStyle(fontFamily: 'RoundedSans')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/orders'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('My Addresses', style: TextStyle(fontFamily: 'RoundedSans')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/addresses'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications', style: TextStyle(fontFamily: 'RoundedSans')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement notifications
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support', style: TextStyle(fontFamily: 'RoundedSans')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement help
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontFamily: 'RoundedSans'),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
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
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

