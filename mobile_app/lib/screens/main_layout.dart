import 'package:flutter/material.dart';
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
  // ignore: unused_field
  String _role = 'cashier';
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _bottomNavItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'cashier';
    
    // Bottom Nav
    List<Map<String, dynamic>> bottomNav = [
      {'route': '/pos', 'label': 'POS', 'icon': 'assets/icons/pos.svg'},
      {'route': '/inventory', 'label': 'Inventory', 'icon': 'assets/icons/inventory.svg'},
      {'route': '/dinau', 'label': 'Dinau', 'icon': 'assets/icons/dinau.svg'},
      {'route': '/logout', 'label': 'Logout', 'icon': Icons.logout},
    ];

    setState(() {
      _role = role;
      _bottomNavItems = bottomNav;
      _isLoading = false;
    });
  }

  void _onNavTap(String route) async {
    if (route == '/logout') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) context.go('/login');
      return;
    }
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
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
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



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(
            top: BorderSide(color: AppTheme.surfaceLight, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
