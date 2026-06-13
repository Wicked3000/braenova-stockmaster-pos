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
  List<dynamic> _categories = [];
  List<Map<String, dynamic>> _cart = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _isCheckingOut = false;
  
  bool _hasOpenShift = false;
  Map<String, dynamic>? _currentShift;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final shiftRes = await client.getCurrentShift();
      bool hasShift = shiftRes.data['success'] == true;
      
      if (!hasShift) {
        if (mounted) setState(() { _hasOpenShift = false; _isLoading = false; });
        return;
      }
      
      final results = await Future.wait([
        client.getInventory(),
        client.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _hasOpenShift = true;
          _currentShift = shiftRes.data['data'];
          if (results[0].data['success']) _inventory = results[0].data['data'];
          if (results[1].data['success']) _categories = results[1].data['data'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredInventory {
    return _inventory.where((item) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          item['item_name'].toString().toLowerCase().contains(q) ||
          (item['barcode'] != null && item['barcode'].toString().contains(q));
      final matchesCategory = _selectedCategoryId == null ||
          item['category_id']?.toString() == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _addToCart(dynamic item) {
    final stockQty = (item['quantity'] ?? 0) as int;
    if (stockQty == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['item_name']} is out of stock'), backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() {
      final idx = _cart.indexWhere((c) => c['id'] == item['id']);
      if (idx >= 0) {
        if (_cart[idx]['qty'] < stockQty) {
          _cart[idx]['qty']++;
          _cart[idx]['total_price'] = _cart[idx]['qty'] * (_cart[idx]['price'] as num).toDouble();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Max stock reached')),
          );
        }
      } else {
        final price = ((item['unit_price'] ?? item['price'] ?? 0) as num).toDouble();
        _cart.add({
          'id': item['id'],
          'name': item['item_name'],
          'price': price,
          'qty': 1,
          'total_price': price,
          'max_qty': stockQty,
        });
      }
    });
  }

  void _updateCartQty(int index, int newQty) {
    setState(() {
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index]['qty'] = newQty;
        _cart[index]['total_price'] = newQty * (_cart[index]['price'] as num).toDouble();
      }
    });
  }

  double get _cartTotal => _cart.fold(0.0, (s, i) => s + (i['total_price'] as num).toDouble());
  int get _cartCount => _cart.fold(0, (s, i) => s + (i['qty'] as int));

  Future<void> _checkout(String method, {String customerName = ''}) async {
    if (_cart.isEmpty) return;
    setState(() => _isCheckingOut = true);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.checkout({
        'items': _cart.map((i) => {'id': i['id'], 'qty': i['qty'], 'price': i['price'], 'total_price': i['total_price']}).toList(),
        'payment_method': method,
        'customer_name': customerName,
        'total_amount': _cartTotal,
      });
      if (response.data['success'] && mounted) {
        final receiptId = response.data['receipt_id'] ?? response.data['data']?['receipt_id'] ?? '';
        final finalTotal = _cartTotal;
        _showReceipt(receiptId, method, customerName, finalTotal);
        setState(() => _cart.clear());
        _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Checkout failed'), backgroundColor: AppTheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  void _showReceipt(dynamic receiptId, String method, String customerName, double totalPaid) {
    final fmt = NumberFormat.currency(symbol: 'K');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 64),
            const SizedBox(height: 12),
            const Text('Sale Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            if (receiptId != '') Text('Receipt #$receiptId', style: const TextStyle(color: AppTheme.textSecondary)),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment'),
                Text(method.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (customerName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Customer'),
                  Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(fmt.format(totalPaid), style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog() {
    final fmt = NumberFormat.currency(symbol: 'K');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Checkout', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${_cart.length} item(s) • Total: ${fmt.format(_cartTotal)}',
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              const Text('Choose Payment Method:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PaymentButton(
                      icon: Icons.payments_rounded,
                      label: 'Cash',
                      color: AppTheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        _showCashDialog();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PaymentButton(
                      icon: Icons.phone_android_rounded,
                      label: 'Mobile Banking',
                      color: AppTheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _checkout('mobile');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PaymentButton(
                      icon: Icons.credit_card_rounded,
                      label: 'Internet Banking',
                      color: AppTheme.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _checkout('card');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PaymentButton(
                      icon: Icons.book_rounded,
                      label: 'Dinau\n(Store Credit)',
                      color: AppTheme.error,
                      onTap: () {
                        Navigator.pop(context);
                        _showDinauDialog();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Center(child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCashDialog() {
    final tenderedCtrl = TextEditingController();
    final fmt = NumberFormat.currency(symbol: 'K');
    double change = 0;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Cash Payment', style: TextStyle(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Due:', style: TextStyle(fontSize: 16)),
                    Text(fmt.format(_cartTotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.secondary)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tenderedCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cash Tendered',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  onChanged: (val) {
                    final t = double.tryParse(val) ?? 0;
                    setDialogState(() {
                      change = t - _cartTotal;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.surfaceLight.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(change >= 0 ? fmt.format(change) : 'Insufficient', 
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: change >= 0 ? AppTheme.secondary : AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
              ElevatedButton(
                onPressed: () {
                  final t = double.tryParse(tenderedCtrl.text) ?? 0;
                  if (t < _cartTotal) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient cash tendered'), backgroundColor: AppTheme.error));
                    return;
                  }
                  Navigator.pop(ctx);
                  _checkout('cash');
                },
                child: const Text('Confirm Sale'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showDinauDialog() {
    if (_cartTotal < 20.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dinau requires a minimum purchase of K20.00'), backgroundColor: AppTheme.error));
      return;
    }
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Store Credit (Dinau)', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the customer name for this credit sale:', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);
              _checkout('dinau', customerName: nameController.text.trim());
            },
            child: const Text('Confirm Credit Sale'),
          ),
        ],
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final fmt = NumberFormat.currency(symbol: 'K');
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, sc) => Column(
              children: [
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cart (${_cart.length} items)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      if (_cart.isNotEmpty)
                        TextButton(
                          onPressed: () { setState(() => _cart.clear()); setSheet(() {}); },
                          child: const Text('Clear All', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 52, color: AppTheme.textSecondary),
                            SizedBox(height: 12),
                            Text('Cart is empty', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ))
                      : ListView.builder(
                          controller: sc,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _cart.length,
                          itemBuilder: (_, i) {
                            final item = _cart[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.surfaceLight),
                              ),
                              child: Row(children: [
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(fmt.format(item['price']), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                )),
                                Row(children: [
                                  _QtyButton(icon: Icons.remove, onTap: () { _updateCartQty(i, (item['qty'] as int) - 1); setSheet(() {}); }),
                                  Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Text('${item['qty']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                                  _QtyButton(icon: Icons.add, isAdd: true, onTap: () {
                                    final max = item['max_qty'] ?? 999;
                                    if ((item['qty'] as int) < max) { _updateCartQty(i, (item['qty'] as int) + 1); setSheet(() {}); }
                                  }),
                                ]),
                                const SizedBox(width: 12),
                                Text(fmt.format(item['total_price']), style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 15)),
                              ]),
                            );
                          },
                        ),
                ),
                SafeArea(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(color: AppTheme.surfaceLight.withOpacity(0.3), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(fmt.format(_cartTotal), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.secondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _cart.isEmpty ? null : () { Navigator.pop(context); _showCheckoutDialog(); },
                        icon: const Icon(Icons.payments_rounded),
                        label: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(dynamic item) {
    final fmt = NumberFormat.currency(symbol: 'K');
    final cartItem = _cart.where((c) => c['id'] == item['id']).toList();
    final cartQty = cartItem.isNotEmpty ? cartItem.first['qty'] as int : 0;
    final stockQty = (item['quantity'] ?? 0) as int;
    final price = ((item['unit_price'] ?? item['price'] ?? 0) as num).toDouble();
    final isOut = stockQty == 0;

    return GestureDetector(
      onTap: isOut ? null : () => _addToCart(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cartQty > 0 ? AppTheme.primary : (isOut ? AppTheme.error.withOpacity(0.3) : AppTheme.surfaceLight),
            width: cartQty > 0 ? 2 : 1,
          ),
          boxShadow: [BoxShadow(
            color: cartQty > 0 ? AppTheme.primary.withOpacity(0.15) : Colors.black.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: isOut ? AppTheme.surfaceLight.withOpacity(0.3) : AppTheme.primary.withOpacity(0.07),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                    ? Image.network(
                  item['image_url'],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, color: isOut ? AppTheme.error.withOpacity(0.5) : AppTheme.primary.withOpacity(0.6), size: 26),
                )
              : Icon(Icons.inventory_2_rounded, size: 42,
                        color: isOut ? AppTheme.textSecondary.withOpacity(0.3) : AppTheme.primary.withOpacity(0.55)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['item_name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                  color: isOut ? AppTheme.textSecondary : AppTheme.textPrimary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(fmt.format(price),
                    style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOut ? AppTheme.error.withOpacity(0.12) :
                          (stockQty <= 5 ? Colors.orange.withOpacity(0.12) : AppTheme.secondary.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isOut ? 'OUT' : 'x$stockQty',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: isOut ? AppTheme.error : (stockQty <= 5 ? Colors.orange : AppTheme.secondary))),
                  ),
                ]),
              ]),
            ),
          ]),
          if (cartQty > 0) Positioned(top: 8, right: 8,
            child: Container(width: 26, height: 26, alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: Text('$cartQty', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)))),
          if (isOut) Positioned.fill(child: Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
          )),
        ]),
      ),
    );
  }

  Widget _buildCartPanel() {
    final fmt = NumberFormat.currency(symbol: 'K');
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(left: BorderSide(color: AppTheme.surfaceLight, width: 1)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppTheme.surfaceLight.withOpacity(0.25),
            border: const Border(bottom: BorderSide(color: AppTheme.surfaceLight, width: 1))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Cart • ${_cartCount} item${_cartCount != 1 ? 's' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            if (_cart.isNotEmpty)
              TextButton(onPressed: () => setState(() => _cart.clear()),
                child: const Text('Clear', style: TextStyle(color: AppTheme.error, fontSize: 12))),
          ]),
        ),
        Expanded(
          child: _cart.isEmpty
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 40, color: AppTheme.textSecondary),
                  SizedBox(height: 8),
                  Text('Tap items to add', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _cart.length,
                itemBuilder: (_, i) {
                  final item = _cart[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(fmt.format(item['price']), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ])),
                      Row(children: [
                        _QtyButton(icon: Icons.remove, onTap: () => _updateCartQty(i, (item['qty'] as int) - 1)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                        _QtyButton(icon: Icons.add, isAdd: true, onTap: () {
                          final max = item['max_qty'] ?? 999;
                          if ((item['qty'] as int) < max) _updateCartQty(i, (item['qty'] as int) + 1);
                        }),
                      ]),
                      const SizedBox(width: 8),
                      Text(fmt.format(item['total_price']),
                        style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 13)),
                    ]),
                  );
                },
              ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.surfaceLight))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(fmt.format(_cartTotal), style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 20)),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: (_cart.isEmpty || _isCheckingOut) ? null : _showCheckoutDialog,
                icon: _isCheckingOut
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.payments_rounded, size: 18),
                label: Text(_isCheckingOut ? 'Processing...' : 'Checkout',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }


  Future<void> _openShift(double floatAmount) async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).openShift(floatAmount);
      if (res.data['success']) {
        await _loadData();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Failed to open shift'), backgroundColor: AppTheme.error));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _closeShift(double actualCash) async {
    if (_currentShift == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).closeShift(_currentShift!['id'], actualCash);
      if (res.data['success']) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift closed successfully'), backgroundColor: AppTheme.secondary));
        await _loadData();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Failed to close shift'), backgroundColor: AppTheme.error));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      setState(() => _isLoading = false);
    }
  }
  
  void _showOpenShiftDialog() {
    final floatCtrl = TextEditingController(text: '0.00');
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      title: const Text('Open Register Shift'),
      content: TextField(
        controller: floatCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Starting Cash Float (K)', prefixText: 'K '),
      ),
      actions: [
        ElevatedButton(onPressed: () {
          final amt = double.tryParse(floatCtrl.text) ?? 0.0;
          Navigator.pop(context);
          _openShift(amt);
        }, child: const Text('Open Shift'))
      ],
    ));
  }

  void _showCloseShiftDialog() {
    final cashCtrl = TextEditingController(text: '0.00');
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Close Register Shift'),
      content: TextField(
        controller: cashCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Actual Cash in Drawer (K)', prefixText: 'K '),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
          onPressed: () {
          final amt = double.tryParse(cashCtrl.text) ?? 0.0;
          Navigator.pop(context);
          _closeShift(amt);
        }, child: const Text('Close Shift'))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {

    final isWide = MediaQuery.of(context).size.width >= 800;
    final fmt = NumberFormat.currency(symbol: 'K');
    final filtered = _filteredInventory;

    if (!_hasOpenShift && !_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Point of Sale')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.point_of_sale_rounded, size: 80, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text('Register Closed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You must open a shift to process sales.', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showOpenShiftDialog,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Open Shift'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              )
            ],
          ),
        ),
      );
    }

    Widget productArea = Column(children: [
      // Category filter chips
      if (_categories.isNotEmpty)
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategoryId == null,
                  onSelected: (_) => setState(() => _selectedCategoryId = null),
                  backgroundColor: AppTheme.surfaceLight,
                  selectedColor: AppTheme.primary.withOpacity(0.25),
                  labelStyle: TextStyle(
                    color: _selectedCategoryId == null ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: _selectedCategoryId == null ? FontWeight.w700 : FontWeight.normal,
                  ),
                  side: BorderSide(color: _selectedCategoryId == null ? AppTheme.primary : Colors.transparent),
                  checkmarkColor: AppTheme.primary,
                ),
              ),
              ..._categories.map((cat) {
                final id = cat['id'].toString();
                final selected = _selectedCategoryId == id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat['name']),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategoryId = selected ? null : id),
                    backgroundColor: AppTheme.surfaceLight,
                    selectedColor: AppTheme.primary.withOpacity(0.25),
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                    side: BorderSide(color: selected ? AppTheme.primary : Colors.transparent),
                    checkmarkColor: AppTheme.primary,
                  ),
                );
              }),
            ],
          ),
        ),

      // Product grid
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.search_off_rounded, size: 52, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(_searchQuery.isEmpty ? 'No products available' : 'No results for "$_searchQuery"',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  ]))
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildProductCard(filtered[i]),
                  ),
      ),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (_hasOpenShift) TextButton.icon(
            icon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.error),
            label: const Text('Close Shift', style: TextStyle(color: AppTheme.error)),
            onPressed: _showCloseShiftDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData, tooltip: 'Refresh'),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products or scan barcode...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchQuery = ''))
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
      ),
      body: isWide
          ? Row(children: [
              Expanded(flex: 2, child: productArea),
              SizedBox(width: 320, child: _buildCartPanel()),
            ])
          : productArea,
      floatingActionButton: !isWide
          ? FloatingActionButton.extended(
              onPressed: _showCartSheet,
              backgroundColor: _cart.isEmpty ? AppTheme.surfaceLight : AppTheme.primary,
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text(
                _cartCount > 0 ? '$_cartCount item${_cartCount > 1 ? 's' : ''} • ${fmt.format(_cartTotal)}' : 'Cart',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}

// Helper widgets
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isAdd;
  const _QtyButton({required this.icon, required this.onTap, this.isAdd = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isAdd ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 15, color: isAdd ? AppTheme.primary : AppTheme.textPrimary),
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PaymentButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}
