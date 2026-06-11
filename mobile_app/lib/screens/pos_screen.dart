import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart'; // To get the apiClientProvider

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  List<dynamic> _inventory = [];
  List<Map<String, dynamic>> _cart = [];
  bool _isLoading = true;
  String _searchQuery = '';

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

  void _addToCart(dynamic item) {
    setState(() {
      final existingIndex = _cart.indexWhere((c) => c['id'] == item['id']);
      if (existingIndex >= 0) {
        // Only add if we have enough stock
        if (_cart[existingIndex]['qty'] < item['stock_qty']) {
          _cart[existingIndex]['qty']++;
          _cart[existingIndex]['total_price'] = _cart[existingIndex]['qty'] * item['price'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Not enough stock for ${item['item_name']}')),
          );
        }
      } else {
        if (item['stock_qty'] > 0) {
          _cart.add({
            'id': item['id'],
            'name': item['item_name'],
            'price': item['price'],
            'qty': 1,
            'total_price': item['price'],
          });
        }
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _checkout() async {
    if (_cart.isEmpty) return;

    final client = ref.read(apiClientProvider);
    try {
      final response = await client.checkout({
        'items': _cart,
        'payment_method': 'cash',
        'customer_name': '', // Blank for cash sales
      });

      if (response.data['success']) {
        setState(() {
          _cart.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sale successful! Receipt: ${response.data['receipt_id']}')),
          );
          _loadInventory(); // Refresh stock
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.data['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error during checkout.')),
        );
      }
    }
  }

  Widget _buildCartUI(double total) {
    final formatCurrency = NumberFormat.currency(symbol: 'K');
    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${_cart.length} items', style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _cart.length,
              itemBuilder: (context, index) {
                final item = _cart[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('${item['qty']} x ${formatCurrency.format(item['price'])}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatCurrency.format(item['total_price']), style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error),
                        onPressed: () {
                          _removeFromCart(index);
                          setState((){}); // Update if inside bottom sheet
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(formatCurrency.format(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty ? null : () {
                        Navigator.pop(context); // close sheet
                        _checkout();
                      },
                      child: const Text('Checkout (Cash)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCartSheet(double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Need a tiny wrapper to calculate total and pass setState
            double currentTotal = _cart.fold(0, (sum, item) => sum + item['total_price']);
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: _buildCartUI(currentTotal),
            );
          }
        );
      }
    );
  }




  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(symbol: 'K');
    final filteredInventory = _inventory.where((item) => 
      item['item_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (item['barcode'] != null && item['barcode'].toString().contains(_searchQuery))
    ).toList();

    double cartTotal = _cart.fold(0, (sum, item) => sum + item['total_price']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 800;

          final gridWidget = _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredInventory.length,
                itemBuilder: (context, index) {
                  final item = filteredInventory[index];
                  return GestureDetector(
                    onTap: () => _addToCart(item),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: const Icon(Icons.inventory, size: 50, color: AppTheme.primary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['item_name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formatCurrency.format(item['price']),
                                      style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Stock: ${item['stock_qty']}',
                                      style: TextStyle(
                                        color: item['stock_qty'] > 5 ? AppTheme.textSecondary : AppTheme.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );

          if (isMobile) {
            return gridWidget;
          }

          // Desktop/Tablet layout
          return Row(
            children: [
              Expanded(flex: 2, child: gridWidget),
              Expanded(flex: 1, child: _buildCartUI(cartTotal)),
            ],
          );
        },
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showCartSheet(cartTotal),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.shopping_cart),
            label: Text('${_cart.length} items • ${formatCurrency.format(cartTotal)}'),
          );
        }
      ),
    );
  }
}
