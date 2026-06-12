import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class DinauScreen extends ConsumerStatefulWidget {
  const DinauScreen({super.key});

  @override
  ConsumerState<DinauScreen> createState() => _DinauScreenState();
}

class _DinauScreenState extends ConsumerState<DinauScreen> {
  List<dynamic> _records = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _filterIndex = 0; // 0=All, 1=Unpaid, 2=Paid
  String _plan = 'starter';

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
      await _loadRecords();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Store Credit (Dinau) is not available on your plan.';
      });
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.getDinauRecords();
      if (response.data['success'] && mounted) {
        setState(() => _records = response.data['data']);
      } else {
        setState(() => _errorMessage = response.data['message'] ?? 'Error loading records.');
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('403') || e.toString().contains('401')) {
          setState(() => _errorMessage = 'Store Credit (Dinau) is not available on your plan.');
          setState(() => _plan = 'starter'); // fallback
        } else {
          setState(() => _errorMessage = 'Unable to load records. Please try again.');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsPaid(dynamic record) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.markDinauPaid(record['id']);
      _loadRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${record['customer_name']} marked as paid!'),
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
    }
  }

  void _showAddDinauDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Store Credit', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (K) *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty || amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Name and amount are required.')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                final client = ref.read(apiClientProvider);
                await client.addDinauRecord({
                  'customer_name': nameController.text.trim(),
                  'amount': double.parse(amountController.text.trim()),
                  'note': noteController.text.trim(),
                });
                _loadRecords();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Store credit record added!'),
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
              }
            },
            child: const Text('Add Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'K');

    final filtered = _records.where((r) {
      if (_filterIndex == 1) return r['status'] != 'paid';
      if (_filterIndex == 2) return r['status'] == 'paid';
      return true;
    }).toList();

    final totalUnpaid = _records
        .where((r) => r['status'] != 'paid')
        .fold(0.0, (sum, r) => sum + (r['amount'] as num).toDouble());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Credit (Dinau)', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecords),
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDinauDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 56, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _loadRecords, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Summary banner
                    if (_records.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Unpaid', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                Text(
                                  fmt.format(totalUnpaid),
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${_records.where((r) => r['status'] != 'paid').length} unpaid',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text('${_records.length} total',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Filter tabs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          _filterTab('All', 0),
                          const SizedBox(width: 8),
                          _filterTab('Unpaid', 1),
                          const SizedBox(width: 8),
                          _filterTab('Paid', 2),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.credit_card_off_outlined, size: 48, color: AppTheme.textSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    _filterIndex == 0 ? 'No records yet' : 'No ${_filterIndex == 1 ? "unpaid" : "paid"} records',
                                    style: const TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadRecords,
                              color: AppTheme.primary,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final record = filtered[index];
                                  final isPaid = record['status'] == 'paid';
                                  final dateStr = record['record_date'] != null
                                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(record['record_date']))
                                      : 'Unknown date';

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isPaid ? AppTheme.secondary.withOpacity(0.2) : AppTheme.error.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 46, height: 46,
                                          decoration: BoxDecoration(
                                            color: isPaid ? AppTheme.secondary.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
                                            color: isPaid ? AppTheme.secondary : AppTheme.error,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record['customer_name'] ?? 'Unknown',
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(dateStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                              if (record['note'] != null && record['note'].toString().isNotEmpty)
                                                Text(record['note'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              fmt.format(record['amount']),
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                            ),
                                            const SizedBox(height: 6),
                                            if (!isPaid)
                                              GestureDetector(
                                                onTap: () => _markAsPaid(record),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.secondary,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text('Mark Paid', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.secondary.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text('PAID', style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _plan == 'starter' 
          ? null 
          : FloatingActionButton(
              onPressed: _showAddDinauDialog,
              backgroundColor: AppTheme.primary,
              tooltip: 'Add Record',
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _filterTab(String label, int index) {
    final isActive = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
