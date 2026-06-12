import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _inventory = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _filterCategoryId;
  String _sortBy = 'name'; // name, price, stock
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final results = await Future.wait([client.getInventory(), client.getCategories()]);
      if (mounted) {
        setState(() {
          if (results[0].data['success']) _inventory = results[0].data['data'];
          if (results[1].data['success']) _categories = results[1].data['data'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredInventory {
    var list = _inventory.where((item) {
      final q = _searchQuery.toLowerCase();
      final matchQ = q.isEmpty ||
          item['item_name'].toString().toLowerCase().contains(q) ||
          (item['barcode'] != null && item['barcode'].toString().contains(q));
      final matchCat = _filterCategoryId == null || item['category_id']?.toString() == _filterCategoryId;
      return matchQ && matchCat;
    }).toList();

    switch (_sortBy) {
      case 'price':
        list.sort((a, b) => ((b['unit_price'] ?? b['price'] ?? 0) as num).compareTo((a['unit_price'] ?? a['price'] ?? 0) as num));
        break;
      case 'stock':
        list.sort((a, b) => ((a['quantity'] ?? a['stock_qty'] ?? 0) as int).compareTo((b['quantity'] ?? b['stock_qty'] ?? 0) as int));
        break;
      default:
        list.sort((a, b) => a['item_name'].toString().compareTo(b['item_name'].toString()));
    }
    return list;
  }

  List<dynamic> get _lowStockItems => _inventory.where((i) => ((i['quantity'] ?? 0) as int) <= 5 && ((i['quantity'] ?? 0) as int) > 0).toList();
  List<dynamic> get _outOfStockItems => _inventory.where((i) => ((i['quantity'] ?? 0) as int) == 0).toList();

  String _getCategoryName(dynamic categoryId) {
    if (categoryId == null) return 'Uncategorized';
    final cat = _categories.firstWhere(
      (c) => c['id'].toString() == categoryId.toString(),
      orElse: () => null,
    );
    return cat != null ? cat['name'] : 'Unknown';
  }

  Future<void> _deleteProduct(dynamic item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${item['item_name']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final client = ref.read(apiClientProvider);
      await client.deleteProduct(item['id']);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['item_name']} deleted'), backgroundColor: AppTheme.secondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showAddProductSheet({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['item_name'] ?? '');
    final priceCtrl = TextEditingController(text: existing?['unit_price']?.toString() ?? existing?['price']?.toString() ?? '');
    final costCtrl = TextEditingController(text: existing?['cost_price']?.toString() ?? existing?['cost']?.toString() ?? '0');
    final qtyCtrl = TextEditingController(text: existing?['quantity']?.toString() ?? existing?['stock_qty']?.toString() ?? '0');
    final threshCtrl = TextEditingController(text: existing?['min_threshold']?.toString() ?? existing?['low_stock_threshold']?.toString() ?? '5');
    final barcodeCtrl = TextEditingController(text: existing?['barcode'] ?? '');
    final imageUrlCtrl = TextEditingController(text: existing?['image_url'] ?? '');
    String? selectedCatId = existing?['category_id']?.toString();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Form(
              key: formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(existing == null ? 'Add Product' : 'Edit Product',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 16),

                // Name
                const Text('Product Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'e.g. Coke 330ml', prefixIcon: Icon(Icons.inventory_2_rounded)),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Price + Cost row
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sell Price (K) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.sell_rounded)),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cost Price (K)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                      ),
                    ],
                  )),
                ]),
                const SizedBox(height: 16),

                // Qty + Threshold row
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stock Qty', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0', prefixIcon: Icon(Icons.storage_rounded)),
                      ),
                    ],
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Low Stock Alert', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: threshCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '5', prefixIcon: Icon(Icons.warning_amber_rounded)),
                      ),
                    ],
                  )),
                ]),
                const SizedBox(height: 16),

                // Category dropdown
                const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  decoration: const InputDecoration(hintText: 'Select Category', prefixIcon: Icon(Icons.category_rounded)),
                  dropdownColor: AppTheme.surfaceLight,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Category')),
                    ..._categories.map((c) => DropdownMenuItem<String>(
                      value: c['id'].toString(),
                      child: Text(c['name']),
                    )),
                  ],
                  onChanged: (v) => setSheet(() => selectedCatId = v),
                ),
                const SizedBox(height: 16),

                // Barcode
                const Text('Barcode (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: barcodeCtrl,
                  decoration: const InputDecoration(hintText: 'Scan or type barcode', prefixIcon: Icon(Icons.qr_code_rounded)),
                ),
                const SizedBox(height: 16),
                
                // Image URL
                const Text('Image URL (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: imageUrlCtrl,
                  decoration: const InputDecoration(hintText: 'https://...', prefixIcon: Icon(Icons.image_outlined)),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setSheet(() => isSaving = true);
                      try {
                        final client = ref.read(apiClientProvider);
                        final data = {
                          'item_name': nameCtrl.text.trim(),
                          'price': double.tryParse(priceCtrl.text) ?? 0,
                          'cost': double.tryParse(costCtrl.text) ?? 0,
                          'stock_qty': int.tryParse(qtyCtrl.text) ?? 0,
                          'low_stock_threshold': int.tryParse(threshCtrl.text) ?? 5,
                          'barcode': barcodeCtrl.text.trim(),
                          'category_id': selectedCatId,
                          'image_url': imageUrlCtrl.text.trim(),
                        };
                        if (existing == null) {
                          await client.addProduct(data);
                        } else {
                          await client.updateProduct(existing['id'], data);
                        }
                        Navigator.pop(ctx);
                        _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(existing == null ? '✅ Product added!' : '✅ Product updated!'),
                              backgroundColor: AppTheme.secondary,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                          );
                        }
                      } finally {
                        setSheet(() => isSaving = false);
                      }
                    },
                    child: isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(existing == null ? 'Add Product' : 'Save Changes',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryManager() {
    final nameCtrl = TextEditingController();
    bool isAdding = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, sc) => Column(children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            // Add new category
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'New category name...', prefixIcon: Icon(Icons.add)),
                )),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isAdding ? null : () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    setSheet(() => isAdding = true);
                    try {
                      final client = ref.read(apiClientProvider);
                      await client.addCategory(nameCtrl.text.trim());
                      nameCtrl.clear();
                      await _loadData();
                      setSheet(() {});
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                        );
                      }
                    } finally {
                      setSheet(() => isAdding = false);
                    }
                  },
                  child: isAdding
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add'),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: _categories.isEmpty
                  ? const Center(child: Text('No categories yet', style: TextStyle(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      controller: sc,
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final itemCount = _inventory.where((item) => item['category_id']?.toString() == cat['id'].toString()).length;
                        return ListTile(
                          leading: Container(width: 38, height: 38, alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.category_rounded, color: AppTheme.primary, size: 20)),
                          title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('$itemCount product${itemCount != 1 ? 's' : ''}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildProductTile(dynamic item) {
    final fmt = NumberFormat.currency(symbol: 'K');
    final stockQty = (item['quantity'] ?? 0) as int;
    final price = ((item['unit_price'] ?? item['price'] ?? 0) as num).toDouble();
    final isOut = stockQty == 0;
    final isLow = stockQty > 0 && stockQty <= 5;

    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await _deleteProduct(item);
        return false; // We handle the deletion ourselves
      },
      child: GestureDetector(
        onTap: () => _showAddProductSheet(existing: Map<String, dynamic>.from(item)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOut ? AppTheme.error.withOpacity(0.3) : isLow ? Colors.orange.withOpacity(0.3) : AppTheme.surfaceLight,
            ),
          ),
          child: Row(children: [
            Container(width: 50, height: 50,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: isOut ? AppTheme.error.withOpacity(0.08) : AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12)),
              child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                  ? Image.network(
                      item['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, color: isOut ? AppTheme.error.withOpacity(0.5) : AppTheme.primary.withOpacity(0.6), size: 26),
                    )
                  : Icon(Icons.inventory_2_rounded,
                      color: isOut ? AppTheme.error.withOpacity(0.5) : AppTheme.primary.withOpacity(0.6), size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['item_name'],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(5)),
                  child: Text(_getCategoryName(item['category_id']),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
                if (item['barcode'] != null && item['barcode'].toString().isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('• ${item['barcode']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmt.format(price),
                style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOut ? AppTheme.error.withOpacity(0.12) : isLow ? Colors.orange.withOpacity(0.12) : AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(
                  isOut ? 'Out of Stock' : isLow ? '⚠ Low: $stockQty' : 'Qty: $stockQty',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isOut ? AppTheme.error : isLow ? Colors.orange : AppTheme.secondary)),
              ),
            ]),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 18),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredInventory;
    final totalValue = _inventory.fold(0.0, (s, i) {
      final p = ((i['unit_price'] ?? i['price'] ?? 0) as num).toDouble();
      final q = (i['quantity'] ?? 0) as int;
      return s + (p * q);
    });
    final fmt = NumberFormat.currency(symbol: 'K');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.category_rounded), onPressed: _showCategoryManager, tooltip: 'Manage Categories'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            color: AppTheme.surfaceLight,
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'price', child: Text('Sort by Price')),
              const PopupMenuItem(value: 'stock', child: Text('Sort by Stock')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or barcode...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchQuery = ''))
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            // Category chips
            if (_categories.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    Padding(padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _filterCategoryId == null,
                        onSelected: (_) => setState(() => _filterCategoryId = null),
                        backgroundColor: AppTheme.surfaceLight,
                        selectedColor: AppTheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _filterCategoryId == null ? AppTheme.primary : AppTheme.textSecondary,
                          fontWeight: _filterCategoryId == null ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 12),
                        side: BorderSide(color: _filterCategoryId == null ? AppTheme.primary : Colors.transparent),
                        checkmarkColor: AppTheme.primary,
                      )),
                    ..._categories.map((cat) {
                      final id = cat['id'].toString();
                      final sel = _filterCategoryId == id;
                      return Padding(padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat['name']),
                          selected: sel,
                          onSelected: (_) => setState(() => _filterCategoryId = sel ? null : id),
                          backgroundColor: AppTheme.surfaceLight,
                          selectedColor: AppTheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(color: sel ? AppTheme.primary : AppTheme.textSecondary,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.normal, fontSize: 12),
                          side: BorderSide(color: sel ? AppTheme.primary : Colors.transparent),
                          checkmarkColor: AppTheme.primary,
                        ));
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 4),
          ]),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Summary row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppTheme.surface,
                child: Row(children: [
                  _StatPill('${_inventory.length}', 'Total Products', AppTheme.primary),
                  const SizedBox(width: 10),
                  _StatPill('${_lowStockItems.length}', 'Low Stock', Colors.orange),
                  const SizedBox(width: 10),
                  _StatPill('${_outOfStockItems.length}', 'Out of Stock', AppTheme.error),
                  const Spacer(),
                  Text('Value: ${fmt.format(totalValue)}',
                    style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
              const Divider(height: 1),
              // Product list
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.inventory_2_outlined, size: 52, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text(_searchQuery.isEmpty ? 'No products yet' : 'No results found',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddProductSheet(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Product'),
                          ),
                        ],
                      ]))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _buildProductTile(filtered[i]),
                        ),
                      ),
              ),
            ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatPill(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
      ]),
    );
  }
}
