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
  int _currentIndex = 1; // Default to POS
  String _role = 'cashier';
  bool _isLoading = true;

  List<String> _routes = [];
  List<String> _labels = [];
  List<String> _icons = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'cashier';
    
    // Always available tabs
    List<String> routes = ['/dashboard', '/pos', '/inventory', '/dinau'];
    List<String> labels = ['Dashboard', 'POS', 'Inventory', 'Dinau'];
    List<String> icons = [
      'assets/icons/dashboard.svg',
      'assets/icons/pos.svg',
      'assets/icons/inventory.svg',
      'assets/icons/dinau.svg',
    ];

    // Owner only tabs
    if (role == 'owner' || role == 'superadmin') {
      routes.add('/warehouse');
      labels.add('Warehouse');
      icons.add('assets/icons/inventory.svg'); // Reuse inventory icon for now or use a different one
      
      routes.add('/reports');
      labels.add('Reports');
      icons.add('assets/icons/dashboard.svg'); // Reuse dashboard icon
      
      routes.add('/settings');
      labels.add('Settings');
      icons.add('assets/icons/settings.svg');
    }

    setState(() {
      _role = role;
      _routes = routes;
      _labels = labels;
      _icons = icons;
      
      // Ensure current index is valid
      if (_currentIndex >= _routes.length) {
        _currentIndex = 0;
      }
      _isLoading = false;
    });
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.surfaceLight, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_labels.length, (index) {
                final isSelected = _currentIndex == index;
                return GestureDetector(
                  onTap: () => _onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          _icons[index],
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            isSelected ? AppTheme.primary : AppTheme.textSecondary,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
