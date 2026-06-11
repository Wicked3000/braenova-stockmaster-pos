import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/pos_screen.dart';

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
    GoRoute(
      path: '/pos',
      builder: (context, state) => const PosScreen(),
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
      theme: AppTheme.darkTheme, // We're using a dark theme by default
      routerConfig: _router,
    );
  }
}
