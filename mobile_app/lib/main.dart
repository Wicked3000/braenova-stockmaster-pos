import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/dinau_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/cashiers_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_layout.dart';
import 'screens/warehouse_screen.dart';
import 'screens/reports_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StockMasterApp(),
    ),
  );
}

// Basic router setup
final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/pos',
          builder: (context, state) => const PosScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/dinau',
          builder: (context, state) => const DinauScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/warehouse',
          builder: (context, state) => const WarehouseScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/sales_history',
      builder: (context, state) => const SalesHistoryScreen(),
    ),
    GoRoute(
      path: '/cashiers',
      builder: (context, state) => const CashiersScreen(),
    ),
  ],
);

class StockMasterApp extends ConsumerWidget {
  const StockMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'StockMaster',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
