import re

with open('mobile_app/lib/screens/warehouse_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add _logs variable
content = content.replace('List<dynamic> _items = [];', 'List<dynamic> _items = [];\n  List<dynamic> _logs = [];')

# Update _loadWarehouseData
load_data = '''  Future<void> _loadWarehouseData() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.getWarehouseItems();
      if (res.data['success']) {
        setState(() {
          _items = res.data['data'];
          _logs = res.data['logs'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading warehouse: \');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }'''
content = re.sub(r'''  Future<void> _loadWarehouseData\(\) async \{\n    setState\(\(\) => _isLoading = true\);\n    try \{\n      final client = ref\.read\(apiClientProvider\);\n      final res = await client\.getWarehouseItems\(\);\n      if \(res\.data\['success'\]\) \{\n        setState\(\(\) => _items = res\.data\['data'\]\);\n      \}\n    \} catch \(e\) \{\n      debugPrint\('Error loading warehouse: \'\);\n    \} finally \{\n      if \(mounted\) setState\(\(\) => _isLoading = false\);\n    \}\n  \}''', load_data, content)

# Change Scaffold to use DefaultTabController
scaffold_code = '''    return DefaultTabController(
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse'),
        bottom: const TabBar(tabs: [Tab(text: 'Inventory'), Tab(text: 'History')]),
      ),
      body: _plan == 'starter'
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Warehouse is a Pro feature.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 16),
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
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    // Tab 1: Inventory
                    _items.isEmpty
                  ? const Center(child: Text('No items in warehouse.'))
                  : RefreshIndicator(
                      onRefresh: _loadWarehouseData,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.surfaceLight),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
                              ),
                              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('SKU: \\\nQuantity: \'),
                              trailing: const Icon(Icons.swap_horiz, color: AppTheme.secondary),
                              onTap: () => _showActionDialog(item, false),
                              onLongPress: () => _showActionDialog(item, true),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Tab 2: Logs
                    _logs.isEmpty
                      ? const Center(child: Text('No warehouse history.'))
                      : RefreshIndicator(
                          onRefresh: _loadWarehouseData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return ListTile(
                                leading: Icon(log['action'] == 'transfer' ? Icons.output : Icons.input, color: log['action'] == 'transfer' ? AppTheme.primary : AppTheme.secondary),
                                title: Text('\ - \ qty'),
                                subtitle: Text('\ by \'),
                                trailing: Text(log['log_date'].toString().split(' ')[0], style: const TextStyle(fontSize: 12)),
                              );
                            },
                          ),
                      ),
                  ],
                ),
    ));'''

content = re.sub(r'''    return Scaffold\(\n      appBar: AppBar\(title: const Text\('Warehouse'\)\),\n      body: _plan == 'starter'.*?,\n                    \),\n            \),\n    \);''', scaffold_code, content, flags=re.DOTALL)

with open('mobile_app/lib/screens/warehouse_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched warehouse_screen.dart')
