import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DinauScreen extends ConsumerStatefulWidget {
  const DinauScreen({super.key});

  @override
  ConsumerState<DinauScreen> createState() => _DinauScreenState();
}

class _DinauScreenState extends ConsumerState<DinauScreen> {
  List<dynamic> _dinauRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDinauRecords();
  }

  Future<void> _loadDinauRecords() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get('/dinau'); // We didn't define this in api_client exactly, but we can call it
      
      if (response.data['success']) {
        setState(() {
          _dinauRecords = response.data['data'];
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'];
        });
      }
    } on Exception catch (e) {
      if (e.toString().contains('403')) {
        setState(() {
          _errorMessage = 'Store credit (Dinau) is not available on your current plan.';
        });
      } else {
        setState(() {
          _errorMessage = 'Error loading Dinau records.';
        });
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
        title: const Text('Store Credit (Dinau)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadDinauRecords();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dinauRecords.length,
                  itemBuilder: (context, index) {
                    final record = _dinauRecords[index];
                    final isPaid = record['status'] == 'paid';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? AppTheme.secondary.withOpacity(0.2) : AppTheme.error.withOpacity(0.2),
                          child: Icon(
                            isPaid ? Icons.check_circle : Icons.pending,
                            color: isPaid ? AppTheme.secondary : AppTheme.error,
                          ),
                        ),
                        title: Text(record['customer_name'] ?? 'Unknown Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Date: ${record['record_date']?.split('T')[0] ?? ''}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCurrency.format(record['amount']),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              isPaid ? 'PAID' : 'UNPAID',
                              style: TextStyle(
                                color: isPaid ? AppTheme.secondary : AppTheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
