import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

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

  void _addToCart(dynamic item) {
    setState(() {
      final existingIndex = _cart.indexWhere((c) => c['id'] == item['id']);
      if (existingIndex >= 0) {
        if (_cart[existingIndex]['qty'] < item['stock_qty']) {
          _cart[existingIndex]['qty']++;
          _cart[existingIndex]['total_price'] = _cart[existingIndex]['qty'] * (item['price'] as num).toDouble();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Max stock reached for ${item['item_name']}')),
          );
        }
      } else {
        if (item['stock_qty'] > 0) {
          _cart.add({
            'id': item['id'],
            'name': item['item_name'],
            'price': (item['price'] as num).toDouble(),
            'qty': 1,
            'total_price': (item['price'] as num).toDouble(),
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item['item_name']} is out of stock'), backgroundColor: AppTheme.error),
          );
        }
      }
    });
  }

  void _decrementCart(int index) {
    setState(() {
      if (_cart[index]['qty'] > 1) {
        _cart[index]['qty']--;
        _cart[index]['total_price'] = _cart[index]['qty'] * _cart[index]['price'];
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  Future<void> _checkout({String method = 'cash', String customerName = ''}) async {
    if (_cart.isEmpty) return;
    final client = ref.read(apiClientProvider);
    try {
      final response = await client.checkout({
        'items': _cart,
        'payment_method': method,
        'customer_name': customerName,
      });
      if (response.data['success']) {
        setState(() => _cart.clear());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Sale complete! Receipt #${response.data['receipt_id']}'),
              backgroundColor: AppTheme.secondary,
            ),
          );
          _loadInventory();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.data['message']}'), backgroundColor: AppTheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error during checkout.'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showCheckoutDialog() {
    final fmt = NumberFormat.currency(symbol: 'K');
    final cartTotal = _cart.fold(0.0, (sum, item) => sum + (item['total_price'] as num).toDouble());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${fmt.format(cartTotal)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.secondary)),
            const SizedBox(height: 8),
            Text('${_cart.length} item(s) in cart', style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            const Text('Select Payment Method:', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _checkout(method: 'cash');
            },
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Cash'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showDinauCheckout();
            },
            icon: const Icon(Icons.credit_card_outlined, size: 18),
            label: const Text('Dinau'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  void _showDinauCheckout() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Store Credit (Dinau)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter customer name for store credit:', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _checkout(method: 'dinau', customerName: nameController.text.trim());
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showCartSheet() {
    final fmt = NumberFormat.currency(symbol: 'K');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final cartTotal = _cart.fold(0.0, (sum, item) => sum + (item['total_price'] as num).toDouble());
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cart (${_cart.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      if (_cart.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() => _cart.clear());
                            setSheetState(() {});
                          },
                          child: const Text('Clear All', style: TextStyle(color: AppTheme.error)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textSecondary),
                              SizedBox(height: 12),
                              Text('Cart is empty', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _cart.length,
                          itemBuilder: (_, index) {
                            final item = _cart[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'],
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(fmt.format(item['price']),
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          _decrementCart(index);
                                          setSheetState(() {});
                                        },
                                        child: Container(
                                          width: 30, height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.remove, size: 16),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text('${item['qty']}',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          final invItem = _inventory.firstWhere((i) => i['id'] == item['id'], orElse: () => null);
                                          if (invItem != null) _addToCart(invItem);
                                          setSheetState(() {});
                                        },
                                        child: Container(
                                          width: 30, height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(fmt.format(item['total_price']),
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              Text(fmt.format(cartTotal),
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.secondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _cart.isEmpty ? null : () {
                              Navigator.pop(ctx);
                              _showCheckoutDialog();
                            },
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'K');
    final filtered = _inventory.where((item) {
      final q = _searchQuery.toLowerCase();
      return item['item_name'].toString().toLowerCase().contains(q) ||
          (item['barcode'] != null && item['barcode'].toString().contains(q));
    }).toList();

    final cartTotal = _cart.fold(0.0, (sum, item) => sum + (item['total_price'] as num).toDouble());
    final isWide = MediaQuery.of(context).size.width >= 800;
    final cartCount = _cart.fold(0, (sum, item) => sum + (item['qty'] as int));

    Widget productGrid = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isEmpty ? 'No products found' : 'No results for "$_searchQuery"',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final inCart = _cart.firstWhere((c) => c['id'] == item['id'], orElse: () => {});
                  final cartQty = inCart.isNotEmpty ? inCart['qty'] as int : 0;
                  final isOutOfStock = item['stock_qty'] == 0;

                  return GestureDetector(
                    onTap: isOutOfStock ? null : () => _addToCart(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cartQty > 0 ? AppTheme.primary.withOpacity(0.5) : AppTheme.surfaceLight,
                          width: cartQty > 0 ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cartQty > 0 ? AppTheme.primary.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? AppTheme.surfaceLight.withOpacity(0.3)
                                        : AppTheme.primary.withOpacity(0.08),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_rounded,
                                    size: 44,
                                    color: isOutOfStock ? AppTheme.textSecondary.withOpacity(0.4) : AppTheme.primary.withOpacity(0.6),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['item_name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isOutOfStock ? AppTheme.textSecondary : AppTheme.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          fmt.format(item['price']),
                                          style: const TextStyle(
                                            color: AppTheme.secondary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOutOfStock
                                                ? AppTheme.error.withOpacity(0.1)
                                                : item['stock_qty'] <= 5
                                                    ? Colors.orange.withOpacity(0.1)
                                                    : AppTheme.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isOutOfStock ? 'OUT' : 'x${item['stock_qty']}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isOutOfStock
                                                  ? AppTheme.error
                                                  : item['stock_qty'] <= 5
                                                      ? Colors.orange
                                                      : AppTheme.secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (cartQty > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$cartQty',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );

    Widget cartPanel = Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.surfaceLight, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.3),
              border: const Border(bottom: BorderSide(color: AppTheme.surfaceLight, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Cart', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                if (_cart.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _cart.clear()),
                    child: const Text('Clear', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 40, color: AppTheme.textSecondary),
                        SizedBox(height: 8),
                        Text('Tap items to add', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _cart.length,
                    itemBuilder: (_, i) {
                      final item = _cart[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(fmt.format(item['price']), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _decrementCart(i),
                                  child: Container(
                                    width: 26, height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)),
                                    child: const Icon(Icons.remove, size: 14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    final inv = _inventory.firstWhere((i) => i['id'] == item['id'], orElse: () => null);
                                    if (inv != null) _addToCart(inv);
                                  },
                                  child: Container(
                                    width: 26, height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                    child: const Icon(Icons.add, size: 14, color: AppTheme.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(fmt.format(item['total_price']), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.secondary, fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.surfaceLight, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(fmt.format(cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.secondary)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty ? null : _showCheckoutDialog,
                    child: const Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInventory),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
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
      body: isWide
          ? Row(children: [
              Expanded(flex: 2, child: productGrid),
              SizedBox(width: 340, child: cartPanel),
            ])
          : productGrid,
      floatingActionButton: !isWide
          ? FloatingActionButton.extended(
              onPressed: _showCartSheet,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                cartCount > 0 ? '$cartCount item${cartCount > 1 ? 's' : ''} • ${fmt.format(cartTotal)}' : 'Cart',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}
