import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'sales_history_screen.dart';
import 'cashiers_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _username = '';
  String _role = 'cashier';
  String _plan = 'starter';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User';
      _role = prefs.getString('role') ?? 'cashier';
      _plan = prefs.getString('plan') ?? 'starter';
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final client = ref.read(apiClientProvider);
      await client.secureStorage.deleteAll();
      if (context.mounted) context.go('/login');
    }
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceLight, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }


  Future<void> _updateShopProfile(String shopName, String header, String footer) async {
    final client = ref.read(apiClientProvider);
    try {
      final res = await client.updateShopProfile({
        if (shopName.isNotEmpty) 'shop_name': shopName,
        if (header.isNotEmpty) 'receipt_header': header,
        if (footer.isNotEmpty) 'receipt_footer': footer,
      });
      if (res.data['success']) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop profile updated'), backgroundColor: AppTheme.secondary));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Failed to update profile'), backgroundColor: AppTheme.error));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  void _showShopProfileDialog() {
    final nameCtrl = TextEditingController();
    final headerCtrl = TextEditingController();
    final footerCtrl = TextEditingController();
    
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Update Shop Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Shop Name (optional)')),
            const SizedBox(height: 12),
            TextField(controller: headerCtrl, decoration: const InputDecoration(labelText: 'Receipt Header (optional)')),
            const SizedBox(height: 12),
            TextField(controller: footerCtrl, decoration: const InputDecoration(labelText: 'Receipt Footer (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          Navigator.pop(context);
          _updateShopProfile(nameCtrl.text.trim(), headerCtrl.text.trim(), footerCtrl.text.trim());
        }, child: const Text('Save'))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withValues(alpha: 0.8), AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username.isEmpty ? 'User' : _username,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _role == 'superadmin' ? 'Super Admin' : _role == 'owner' ? 'Store Owner' : 'Cashier',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_plan.toUpperCase()} PLAN',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account section
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 4),
              child: Text('Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1.2)),
            ),
            _buildTile(
              icon: Icons.receipt_long_rounded,
              title: 'Sales History',
              subtitle: 'View all past transactions',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
              ),
            ),
            if (_role == 'owner' || _role == 'superadmin') ...[
              _buildTile(
                icon: Icons.people_alt_rounded,
                title: 'Staff Management',
                subtitle: 'Manage cashiers & staff',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CashiersScreen()),
                ),
              ),
              _buildTile(
                icon: Icons.storefront_rounded,
                title: 'Shop Details',
                subtitle: 'Edit shop info',
                onTap: _showShopProfileDialog,
              ),
                _buildTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Manage Expenses',
                  subtitle: 'Track operational costs',
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () {
                    context.push('/expenses');
                  },
                ),
                _buildTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Subscription Plan',
                  subtitle: 'Manage plan & billing',
                  iconColor: const Color(0xFF8B5CF6),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Manage Subscription'),
                        content: const Text('To manage your billing and subscription plan, please log into the StockMaster Web Dashboard on your computer.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],

            // App preferences
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 4),
              child: Text('Preferences', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1.2)),
            ),
            _buildTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Currently enabled',
              onTap: null,
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeThumbColor: AppTheme.primary,
              ),
            ),
            _buildTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // About section
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 4),
              child: Text('About', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1.2)),
            ),
            _buildTile(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              subtitle: 'StockMaster v1.0.0',
              onTap: null,
              trailing: const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Logout
            GestureDetector(
              onTap: () => _logout(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
