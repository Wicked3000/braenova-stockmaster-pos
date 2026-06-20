import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.getExpenses();
      if (res.data['success']) {
        setState(() => _expenses = res.data['data'] ?? []);
      } else {
        setState(() => _errorMessage = res.data['message'] ?? 'Error loading expenses');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Pro feature required or network error.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddExpenseDialog() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: 'K '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final client = ref.read(apiClientProvider);
                await client.addExpense({
                  'amount': double.parse(amountCtrl.text),
                  'description': descCtrl.text,
                });
                _loadExpenses();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense added!'), backgroundColor: AppTheme.secondary));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'K');
    final total = _expenses.fold(0.0, (sum, e) => sum + (e['amount'] as num).toDouble());

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock, size: 64, color: Colors.grey), const SizedBox(height: 16), Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)), const SizedBox(height: 16), ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Go Back'))])))
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Today\'s Total', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          Text(fmt.format(total), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _expenses.isEmpty
                          ? const Center(child: Text('No expenses logged today'))
                          : ListView.builder(
                              itemCount: _expenses.length,
                              itemBuilder: (context, index) {
                                final exp = _expenses[index];
                                return ListTile(
                                  leading: CircleAvatar(backgroundColor: AppTheme.error.withValues(alpha: 0.1), child: Icon(Icons.money_off, color: AppTheme.error)),
                                  title: Text(exp['description']),
                                  subtitle: Text(exp['logged_by_name'] ?? 'Staff'),
                                  trailing: Text(fmt.format(exp['amount']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.error)),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
