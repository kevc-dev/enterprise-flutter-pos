import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:enterprise_flutter_pos/presentation/themes/app_theme.dart';
import 'package:enterprise_flutter_pos/presentation/widgets/analytics_card.dart';
import 'package:enterprise_flutter_pos/presentation/widgets/sales_chart.dart';
import 'package:enterprise_flutter_pos/presentation/widgets/payment_distribution_chart.dart';
import 'package:enterprise_flutter_pos/presentation/widgets/top_products_list.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', '7 Days', '30 Days', '90 Days'];
  
  // Mock data - in production this would come from API
  final Map<String, Map<String, dynamic>> _mockData = {
    'Today': {
      'totalSales': 12543.50,
      'salesChange': 15.3,
      'transactionCount': 87,
      'transactionChange': 8.2,
      'avgTicket': 144.18,
      'avgTicketChange': 6.8,
      'topProduct': 'Wireless Headphones',
      'topProductSales': 2134.90,
    },
    '7 Days': {
      'totalSales': 89432.10,
      'salesChange': 12.7,
      'transactionCount': 623,
      'transactionChange': 5.4,
      'avgTicket': 143.52,
      'avgTicketChange': 7.1,
      'topProduct': 'Smartphone Case',
      'topProductSales': 8921.45,
    },
    '30 Days': {
      'totalSales': 387654.75,
      'salesChange': 18.9,
      'transactionCount': 2847,
      'transactionChange': 14.3,
      'avgTicket': 136.23,
      'avgTicketChange': 4.0,
      'topProduct': 'Bluetooth Speaker',
      'topProductSales': 23456.78,
    },
    '90 Days': {
      'totalSales': 1234567.89,
      'salesChange': 22.5,
      'transactionCount': 9876,
      'transactionChange': 19.7,
      'avgTicket': 124.98,
      'avgTicketChange': 2.3,
      'topProduct': 'Power Bank',
      'topProductSales': 67890.12,
    },
  };

  @override
  Widget build(BuildContext context) {
    final currentData = _mockData[_selectedPeriod]!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => _periods
                .map((period) => PopupMenuItem(
                      value: period,
                      child: Text(period),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _exportReport,
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    title: 'Total Sales',
                    value: NumberFormat.currency(symbol: '\$')
                        .format(currentData['totalSales']),
                    change: currentData['salesChange'],
                    icon: Icons.attach_money,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Transactions',
                    value: NumberFormat.decimalPattern()
                        .format(currentData['transactionCount']),
                    change: currentData['transactionChange'],
                    icon: Icons.receipt_long,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Avg. Ticket',
                    value: NumberFormat.currency(symbol: '\$')
                        .format(currentData['avgTicket']),
                    change: currentData['avgTicketChange'],
                    icon: Icons.shopping_cart,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    title: 'Top Product',
                    value: currentData['topProduct'],
                    subValue: NumberFormat.currency(symbol: '\$')
                        .format(currentData['topProductSales']),
                    icon: Icons.star,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Charts Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales Trend Chart
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales Trend - $_selectedPeriod',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: SalesChart(period: _selectedPeriod),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Payment Method Distribution
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Methods',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: PaymentDistributionChart(period: _selectedPeriod),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Bottom Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Products List
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Products',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          TopProductsList(period: _selectedPeriod),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Hourly Performance
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hourly Performance',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _buildHourlyChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppTheme.textPrimary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${group.x + 9}:00\n\$${rod.toY.round()}k',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${(value.toInt() + 9) % 24}',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}k',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          12,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: [8, 12, 15, 18, 16, 14, 11, 9, 7, 5, 3, 2][i].toDouble(),
                color: AppTheme.primaryBlue,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report export functionality would be implemented here'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }
}