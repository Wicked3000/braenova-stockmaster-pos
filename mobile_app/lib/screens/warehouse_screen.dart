import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
  List<dynamic> _logs = [];

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
        setState(() {
          _items = res.data['data'] ?? [];
          _logs = res.data['logs'] ?? [];
        });
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

  void _showActionDialog(Map<String, dynamic> item, bool isRestock) {
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isRestock ? 'Restock Warehouse' : 'Transfer to Shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${item['item_name']}'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
            ),
            if (!isRestock)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Current Stock: ${item['quantity']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text) ?? 0;
              if (qty <= 0) return;
              if (!isRestock && qty > (item['quantity'] as int)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock in warehouse.')));
                return;
              }
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final client = ref.read(apiClientProvider);
                final res = isRestock
                    ? await client.restockWarehouse(item['item_id'], qty)
                    : await client.transferWarehouse(item['item_id'], qty);
                if (res.data['success']) {
                  _loadWarehouseData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success!'), backgroundColor: AppTheme.secondary));
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Error'), backgroundColor: AppTheme.error));
                  setState(() => _isLoading = false);
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                setState(() => _isLoading = false);
              }
            },
            child: Text(isRestock ? 'Restock' : 'Transfer'),
          ),
        ],
      ),
    );
  }

  void _showItemOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppTheme.secondary),
              title: const Text('Restock Warehouse'),
              onTap: () {
                Navigator.pop(context);
                _showActionDialog(item, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined, color: AppTheme.primary),
              title: const Text('Transfer to Shop'),
              onTap: () {
                Navigator.pop(context);
                _showActionDialog(item, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_plan == 'starter') {
      return Scaffold(
        appBar: AppBar(title: const Text('Warehouse')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warehouse_outlined, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                const Text(
                  'Warehouse is a Pro feature.',
                  style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please login via Web Dashboard to upgrade your plan.')),
                    );
                  },
                  child: const Text('Upgrade Plan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Warehouse'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Inventory'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Inventory
                  _items.isEmpty
                      ? const Center(child: Text('No items in warehouse.', style: TextStyle(color: AppTheme.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: _loadWarehouseData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  onTap: () => _showItemOptions(item),
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
                        ),

                  // Tab 2: Logs/History
                  _logs.isEmpty
                      ? const Center(child: Text('No warehouse history.', style: TextStyle(color: AppTheme.textSecondary)))
                      : RefreshIndicator(
                          onRefresh: _loadWarehouseData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              final isTransfer = log['action_type'] == 'transfer';
                              final dateStr = log['action_date'] != null 
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(log['action_date']))
                                  : 'Unknown Date';
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isTransfer ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.secondary.withValues(alpha: 0.1),
                                    child: Icon(
                                      isTransfer ? Icons.local_shipping : Icons.add_business, 
                                      color: isTransfer ? AppTheme.primary : AppTheme.secondary,
                                    ),
                                  ),
                                  title: Text('${log['item_name'] ?? 'Item'} - Qty: ${log['quantity']}'),
                                  subtitle: Text('${isTransfer ? 'Transferred to Shop' : 'Restocked'} by ${log['user_name'] ?? 'User'}\n$dateStr'),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
