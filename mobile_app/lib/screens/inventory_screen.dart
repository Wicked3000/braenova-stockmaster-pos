import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'add_product_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  List<dynamic> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.getInventory();
      if (response.data['success']) {
        setState(() {
          _inventory = response.data['data'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(symbol: 'K');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadInventory();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
              if (result == true) {
                setState(() => _isLoading = true);
                _loadInventory();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inventory.length,
              itemBuilder: (context, index) {
                final item = _inventory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2),
                    ),
                    title: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Category ID: ${item['category_id'] ?? 'None'} • Barcode: ${item['barcode'] ?? 'N/A'}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency.format(item['price']),
                          style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Qty: ${item['stock_qty']}',
                          style: TextStyle(
                            color: item['stock_qty'] > 5 ? AppTheme.textSecondary : AppTheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AddProductScreen(existingProduct: item)),
                      );
                      if (result == true) {
                        setState(() => _isLoading = true);
                        _loadInventory();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
