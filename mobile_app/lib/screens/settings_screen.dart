import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart'; // For apiClientProvider

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final client = ref.read(apiClientProvider);
    await client.secureStorage.delete(key: 'jwt_token');
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text('Account Settings', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Sales History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/sales_history'),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Staff Management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/cashiers'),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Shop Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          const ListTile(
            title: Text('App Preferences', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: true,
            onChanged: (val) {
              // We're currently hardcoded to Dark Theme in MVP
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            onTap: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}
