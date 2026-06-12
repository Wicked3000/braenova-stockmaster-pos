import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class WarehouseScreen extends ConsumerStatefulWidget {
  const WarehouseScreen({super.key});

  @override
  ConsumerState<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends ConsumerState<WarehouseScreen> {
  bool _isLoading = true;
  String _plan = 'starter';
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _checkPlanAndLoad();
  }

  Future<void> _checkPlanAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final plan = prefs.getString('plan') ?? 'starter';
    setState(() => _plan = plan);

    if (plan != 'starter') {
      await _loadWarehouseData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWarehouseData() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.getWarehouse();
      if (res.data['success']) {
        setState(() => _items = res.data['data']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading warehouse: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLockedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 24),
          const Text(
            'Warehouse Locked',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Warehouse storage is a Pro feature.\nPlease upgrade your plan to access this.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Usually direct to payment portal or show contact info
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please login via Web Dashboard to upgrade your plan.')),
              );
            },
            child: const Text('Upgrade to Pro'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_plan == 'starter') {
      return Scaffold(
        appBar: AppBar(title: const Text('Warehouse')),
        body: _buildLockedState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWarehouseData,
          ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('Warehouse is empty', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.surfaceLight,
                      child: Icon(Icons.inventory_2, color: AppTheme.primary),
                    ),
                    title: Text(item['item_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Supplier: ${item['supplier_name'] ?? 'N/A'}'),
                    trailing: Text(
                      'Qty: ${item['quantity'] ?? 0}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add warehouse item modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Item coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
