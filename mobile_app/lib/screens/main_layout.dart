import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentRoute = '/pos'; // Default
  String _role = 'cashier';
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _bottomNavItems = [];
  List<Map<String, dynamic>> _endDrawerItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'cashier';
    
    // Bottom Nav: Max 5 items (Dashboard, POS, Inventory, Dinau, Menu)
    List<Map<String, dynamic>> bottomNav = [
      {'route': '/dashboard', 'label': 'Dashboard', 'icon': 'assets/icons/dashboard.svg'},
      {'route': '/pos', 'label': 'POS', 'icon': 'assets/icons/pos.svg'},
      {'route': '/inventory', 'label': 'Inventory', 'icon': 'assets/icons/inventory.svg'},
      {'route': '/dinau', 'label': 'Dinau', 'icon': 'assets/icons/dinau.svg'},
    ];
    
    // Right Side Menu (endDrawer) Items
    List<Map<String, dynamic>> rightMenuNav = [];

    if (role == 'owner' || role == 'superadmin') {
      rightMenuNav.add({'route': '/warehouse', 'label': 'Warehouse', 'icon': 'assets/icons/inventory.svg'});
      rightMenuNav.add({'route': '/reports', 'label': 'Reports', 'icon': 'assets/icons/dashboard.svg'});
      rightMenuNav.add({'route': '/settings', 'label': 'Settings', 'icon': Icons.settings});
    }

    setState(() {
      _role = role;
      _bottomNavItems = bottomNav;
      _endDrawerItems = rightMenuNav;
      _isLoading = false;
    });
  }

  void _onNavTap(String route) {
    if (route == _currentRoute) return;
    setState(() {
      _currentRoute = route;
    });
    context.go(route);
  }

  Widget _buildIcon(dynamic iconData, Color color) {
    if (iconData is String) {
      return SvgPicture.asset(
        iconData, 
        width: 24, 
        height: 24, 
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn)
      );
    } else if (iconData is IconData) {
      return Icon(iconData, size: 24, color: color);
    }
    return const SizedBox(width: 24, height: 24);
  }

  Widget _buildNavItem(Map<String, dynamic> item, bool isSelected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _onNavTap(item['route']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(item['icon'], isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              item['label'],
              style: TextStyle(
                fontSize: 10, // slightly smaller to fit 5 items comfortably
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              color: AppTheme.background,
              child: Image.asset(
                'assets/images/logo.png', 
                height: 40, 
                alignment: Alignment.centerLeft,
                errorBuilder: (_, __, ___) => const Text(
                  'Menu', 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _endDrawerItems.map((item) {
                  final isSelected = _currentRoute == item['route'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: _buildIcon(item['icon'], isSelected ? AppTheme.primary : AppTheme.textSecondary),
                      title: Text(
                        item['label'],
                        style: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppTheme.primary.withOpacity(0.1),
                      onTap: () {
                        Navigator.pop(context); // Close endDrawer
                        _onNavTap(item['route']);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppTheme.surfaceLight),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout, color: AppTheme.error),
                title: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool isDrawerRouteSelected = _endDrawerItems.any((item) => item['route'] == _currentRoute);

    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      endDrawer: _buildEndDrawer(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(
            top: BorderSide(color: AppTheme.surfaceLight, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ..._bottomNavItems.map((item) {
                  final isSelected = _currentRoute == item['route'];
                  return Expanded(
                    child: _buildNavItem(item, isSelected),
                  );
                }),
                if (_endDrawerItems.isNotEmpty)
                  Expanded(
                    child: _buildNavItem(
                      {'label': 'Menu', 'icon': Icons.menu},
                      isDrawerRouteSelected,
                      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
