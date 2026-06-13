import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _summaryData;
  List<dynamic> _recentSales = [];
  List<dynamic> _chartData = [];
  List<dynamic> _hourlyData = [];
  List<dynamic> _catDist = [];
  bool _isLoading = true;
  String _role = 'cashier';
  String _plan = 'starter';

  @override
  void initState() {
    super.initState();
    _loadRoleAndData();
  }

  Future<void> _loadRoleAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'cashier';
      _plan = prefs.getString('plan') ?? 'starter';
    });
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final summaryFuture = client.getDashboardSummary();
      final salesFuture = client.getSalesHistory();

      final results = await Future.wait([summaryFuture, salesFuture]);

      if (mounted) {
        setState(() {
          if (results[0].data['success']) {
            _summaryData = results[0].data['data'];
            _chartData = results[0].data['chart_data'] ?? [];
            _hourlyData = results[0].data['hourly_data'] ?? [];
            _catDist = results[0].data['cat_dist'] ?? [];
          }
          if (results[1].data['success']) {
            final allSales = results[1].data['data'] as List<dynamic>;
            _recentSales = allSales.take(5).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load dashboard: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surface, AppTheme.surfaceLight.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    if (_chartData.isEmpty && _hourlyData.isEmpty && _catDist.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_chartData.isNotEmpty) ...[
          const Text('Weekly Revenue Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(4, 16, 16, 4),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.surfaceLight, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _chartData.length) {
                          final dateStr = _chartData[index]['date'].toString();
                          final parts = dateStr.split(' ');
                          String label = '';
                          if (parts.length >= 3) {
                             label = '${parts[1]} ${parts[2]}'; 
                          } else {
                             final dParts = dateStr.split('-');
                             if (dParts.length >= 3) {
                               label = '${dParts[2]}/${dParts[1]}';
                             } else {
                               label = dateStr.length > 5 ? dateStr.substring(0, 5) : dateStr;
                             }
                          }
                          return Padding(padding: const EdgeInsets.only(top: 6.0), child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text('K${value.toInt()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['total'] ?? 0).toDouble())).toList(),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.15)),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_hourlyData.isNotEmpty) ...[
          const Text('Peak Hours (Today)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.surfaceLight, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text('K${value.toInt()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _hourlyData.length) {
                          final hourStr = _hourlyData[index]['hour'].toString();
                          return Padding(padding: const EdgeInsets.only(top: 6.0), child: Text('${hourStr}h', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _hourlyData.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [BarChartRodData(toY: (e.value['total'] ?? 0).toDouble(), color: Colors.amber, width: 12, borderRadius: BorderRadius.circular(4))],
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_catDist.isNotEmpty) ...[
          const Text('Sales by Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceLight),
            ),
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _catDist.asMap().entries.map((e) {
                  final index = e.key;
                  final category = e.value['category'] ?? 'Unknown';
                  final total = (e.value['total'] ?? 0).toDouble();
                  final totalSum = _catDist.fold(0.0, (sum, item) => sum + (item['total'] ?? 0));
                  final percent = totalSum > 0 ? (total / totalSum * 100) : 0;
                  final colors = [AppTheme.primary, AppTheme.secondary, Colors.amber, Colors.green, Colors.purple, Colors.orange];
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: total,
                    title: '${percent.toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    badgeWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                      child: Text(category, style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                    badgePositionPercentageOffset: 1.2,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: 'K');
    final dateFmt = DateFormat('dd MMM • hh:mm a');
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 56,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text('StockMaster', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header greeting
                    const Text(
                      'Sales Overview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Stats grid
                    GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isWide ? 1.4 : 1.3,
                      children: [
                        _buildStatCard(
                          "Today's Sales",
                          fmt.format(_summaryData?['sales_today'] ?? 0),
                          Icons.trending_up_rounded,
                          AppTheme.primary,
                        ),
                        _buildStatCard(
                          'Transactions',
                          '${_summaryData?['transactions_today'] ?? 0}',
                          Icons.receipt_long_rounded,
                          AppTheme.secondary,
                        ),
                        if ((_role == 'owner' || _role == 'superadmin') && _plan != 'starter')
                          _buildStatCard(
                            'Est. Profit',
                            fmt.format(_summaryData?['total_profit'] ?? 0),
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFF8B5CF6),
                          ),
                        _buildStatCard(
                          'Low Stock',
                          '${_summaryData?['low_stock_count'] ?? 0}',
                          Icons.warning_amber_rounded,
                          AppTheme.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    _buildCharts(),

                    // Recent Sales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Sales',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All', style: TextStyle(color: AppTheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_recentSales.isEmpty)
                      Container(
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.textSecondary),
                            SizedBox(height: 8),
                            Text('No sales today yet', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentSales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final sale = _recentSales[index];
                          final saleDate = sale['sale_date'] != null
                              ? dateFmt.format(DateTime.parse(sale['sale_date']).toLocal())
                              : 'Unknown';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.surfaceLight, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_circle_outline, color: AppTheme.secondary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Receipt #${sale['receipt_id'] ?? sale['id'] ?? index + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(saleDate, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text(
                                  fmt.format(sale['total_price'] ?? 0),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
