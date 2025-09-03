import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:enterprise_flutter_pos/presentation/themes/app_theme.dart';

class PaymentDistributionChart extends StatelessWidget {
  final String period;

  const PaymentDistributionChart({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _generateSections(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                enabled: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _generateSections() {
    final data = _getPaymentData();
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.accentBlue,
      AppTheme.success,
      AppTheme.warning,
      Colors.purple[400]!,
    ];

    return List.generate(data.length, (index) {
      final item = data[index];
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: item['percentage'],
        title: '${item['percentage'].toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: null,
      );
    });
  }

  Widget _buildLegend() {
    final data = _getPaymentData();
    final colors = [
      AppTheme.primaryBlue,
      AppTheme.accentBlue,
      AppTheme.success,
      AppTheme.warning,
      Colors.purple[400]!,
    ];

    return Column(
      children: List.generate(data.length, (index) {
        final item = data[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item['method']} (${item['percentage'].toInt()}%)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<Map<String, dynamic>> _getPaymentData() {
    switch (period) {
      case 'Today':
        return [
          {'method': 'Credit Card', 'percentage': 45.0},
          {'method': 'Debit Card', 'percentage': 25.0},
          {'method': 'Mobile Pay', 'percentage': 20.0},
          {'method': 'Cash', 'percentage': 10.0},
        ];
      case '7 Days':
        return [
          {'method': 'Credit Card', 'percentage': 42.0},
          {'method': 'Debit Card', 'percentage': 28.0},
          {'method': 'Mobile Pay', 'percentage': 18.0},
          {'method': 'Cash', 'percentage': 12.0},
        ];
      case '30 Days':
        return [
          {'method': 'Credit Card', 'percentage': 40.0},
          {'method': 'Debit Card', 'percentage': 30.0},
          {'method': 'Mobile Pay', 'percentage': 15.0},
          {'method': 'Cash', 'percentage': 10.0},
          {'method': 'Gift Card', 'percentage': 5.0},
        ];
      case '90 Days':
        return [
          {'method': 'Credit Card', 'percentage': 38.0},
          {'method': 'Debit Card', 'percentage': 32.0},
          {'method': 'Mobile Pay', 'percentage': 17.0},
          {'method': 'Cash', 'percentage': 8.0},
          {'method': 'Gift Card', 'percentage': 5.0},
        ];
      default:
        return [
          {'method': 'Credit Card', 'percentage': 50.0},
          {'method': 'Other', 'percentage': 50.0},
        ];
    }
  }
}