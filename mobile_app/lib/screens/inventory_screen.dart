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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.getInventory();
      if (response.data['success'] && mounted) {
        setState(() {
          _inventory = response.data['data'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'K');
    final filtered = _inventory.where((item) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          item['item_name'].toString().toLowerCase().contains(q) ||
          (item['barcode'] != null && item['barcode'].toString().contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
              if (result == true) _loadInventory();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products or barcode...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 52, color: AppTheme.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty ? 'No products in inventory' : 'No results found',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddProductScreen()),
                            );
                            if (result == true) _loadInventory();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Product'),
                        ),
                      ]
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInventory,
                  color: AppTheme.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final stockQty = item['stock_qty'] as int;
                      final isLow = stockQty > 0 && stockQty <= 5;
                      final isOut = stockQty == 0;

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AddProductScreen(existingProduct: item)),
                          );
                          if (result == true) _loadInventory();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isOut
                                  ? AppTheme.error.withOpacity(0.3)
                                  : isLow
                                      ? Colors.orange.withOpacity(0.3)
                                      : AppTheme.surfaceLight,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon box
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isOut
                                      ? AppTheme.error.withOpacity(0.08)
                                      : AppTheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: isOut ? AppTheme.error.withOpacity(0.5) : AppTheme.primary.withOpacity(0.7),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['item_name'],
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item['barcode'] != null ? 'Barcode: ${item['barcode']}' : 'No barcode',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Price + stock
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    fmt.format(item['price']),
                                    style: const TextStyle(
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isOut
                                          ? AppTheme.error.withOpacity(0.12)
                                          : isLow
                                              ? Colors.orange.withOpacity(0.12)
                                              : AppTheme.secondary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isOut ? 'Out of Stock' : isLow ? 'Low: $stockQty' : 'In Stock: $stockQty',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isOut ? AppTheme.error : isLow ? Colors.orange : AppTheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          if (result == true) _loadInventory();
        },
        backgroundColor: AppTheme.primary,
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }
}
