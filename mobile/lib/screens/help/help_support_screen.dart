import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Center(
              child: Icon(
                Icons.support_agent,
                size: 70,
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'How can we help you?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                'Choose an option below to get help with your order.',
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text(
                  'Raise a Support Request',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Report an issue with your order, payment or delivery',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/support');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}