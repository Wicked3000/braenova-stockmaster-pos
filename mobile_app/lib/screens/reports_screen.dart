import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isLoading = true;
  String _plan = 'starter';
  List<dynamic> _reports = [];

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
      await _loadReportsData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReportsData() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.getReports();
      if (res.data['success']) {
        setState(() => _reports = res.data['data']['reports'] ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _closeDay() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).closeDayReport();
      if (res.data['success']) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message']), backgroundColor: AppTheme.secondary));
        await _loadReportsData();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Failed to close day'), backgroundColor: AppTheme.error));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLockedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_rounded, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 24),
          const Text(
            'Reports Locked',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Detailed reports are a Pro feature.\nPlease upgrade your plan to access this.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please login via Web Dashboard to upgrade your plan.')),
              );
            },
            child: const Text('Upgrade to Pro'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'K');
    final dateFmt = DateFormat('dd MMM yyyy');

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_plan == 'starter') {
      return Scaffold(
        appBar: AppBar(title: const Text('Financial Reports')),
        body: _buildLockedState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Close-Out Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportsData,
          ),
        ],
      ),
      body: _reports.isEmpty
          ? const Center(child: Text('No reports available', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                final rDate = report['report_date'] != null 
                    ? dateFmt.format(DateTime.parse(report['report_date']).toLocal()) 
                    : 'Unknown';
                    
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: const Icon(Icons.summarize_rounded, color: AppTheme.primary),
                    title: Text(rDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Sales: ${fmt.format(report['total_sales'] ?? 0)}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Expected Cash:', style: TextStyle(color: AppTheme.textSecondary)),
                                Text(fmt.format(report['expected_cash'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Actual Cash:', style: TextStyle(color: AppTheme.textSecondary)),
                                Text(fmt.format(report['actual_cash'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Difference:', style: TextStyle(color: AppTheme.textSecondary)),
                                Text(
                                  fmt.format(report['difference'] ?? 0), 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (report['difference'] ?? 0) < 0 ? AppTheme.error : AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Profit:', style: TextStyle(color: AppTheme.textSecondary)),
                                Text(fmt.format(report['total_profit'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => AlertDialog(
            title: const Text('Close Day'),
            content: const Text('Are you sure you want to generate the End of Day report? This will aggregate all closed shifts for today.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(onPressed: () {
                Navigator.pop(context);
                _closeDay();
              }, child: const Text('Generate Z-Report'))
            ],
          ));
        },
        icon: const Icon(Icons.summarize_rounded),
        label: const Text('Close Day'),
      ),
    );
  }
}
