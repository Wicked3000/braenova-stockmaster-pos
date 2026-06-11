import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  List<dynamic> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final client = ref.read(apiClientProvider); // Will pass this via provider in a real app, assuming apiClientProvider is global
      // For now we'll just instantiate or import the provider
      // Actually, since apiClientProvider is in login_screen, let's move it to api_client.dart
    } catch (e) {
      // Handle
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {},
          ),
        ],
      ),
      body: const Center(
        child: Text('POS Grid Will Go Here'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Scan', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
