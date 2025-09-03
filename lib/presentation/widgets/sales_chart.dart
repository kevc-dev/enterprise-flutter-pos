import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:enterprise_flutter_pos/presentation/themes/app_theme.dart';

class SalesChart extends StatelessWidget {
  final String period;

  const SalesChart({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getHorizontalInterval(),
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) => _buildBottomTitle(value, meta),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getHorizontalInterval(),
              reservedSize: 40,
              getTitlesWidget: (value, meta) => _buildLeftTitle(value, meta),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minX: 0,
        maxX: _getMaxX(),
        minY: 0,
        maxY: _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: _generateSpots(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue,
                AppTheme.accentBlue,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryBlue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.2),
                  AppTheme.accentBlue.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppTheme.textPrimary,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '\$${barSpot.y.toStringAsFixed(0)}k',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    switch (period) {
      case 'Today':
        return [
          const FlSpot(0, 2),
          const FlSpot(1, 4),
          const FlSpot(2, 6),
          const FlSpot(3, 8),
          const FlSpot(4, 12),
          const FlSpot(5, 15),
          const FlSpot(6, 18),
          const FlSpot(7, 16),
          const FlSpot(8, 14),
          const FlSpot(9, 11),
          const FlSpot(10, 8),
          const FlSpot(11, 5),
        ];
      case '7 Days':
        return [
          const FlSpot(0, 45),
          const FlSpot(1, 52),
          const FlSpot(2, 48),
          const FlSpot(3, 68),
          const FlSpot(4, 75),
          const FlSpot(5, 89),
          const FlSpot(6, 94),
        ];
      case '30 Days':
        return List.generate(15, (index) {
          final baseValue = 150 + (index * 15);
          final variance = (index % 3) * 20 - 10;
          return FlSpot(index.toDouble(), (baseValue + variance).toDouble());
        });
      case '90 Days':
        return List.generate(12, (index) {
          final baseValue = 800 + (index * 50);
          final variance = (index % 4) * 100 - 50;
          return FlSpot(index.toDouble(), (baseValue + variance).toDouble());
        });
      default:
        return [];
    }
  }

  double _getMaxX() {
    switch (period) {
      case 'Today':
        return 11;
      case '7 Days':
        return 6;
      case '30 Days':
        return 14;
      case '90 Days':
        return 11;
      default:
        return 10;
    }
  }

  double _getMaxY() {
    switch (period) {
      case 'Today':
        return 20;
      case '7 Days':
        return 100;
      case '30 Days':
        return 400;
      case '90 Days':
        return 1200;
      default:
        return 100;
    }
  }

  double _getHorizontalInterval() {
    switch (period) {
      case 'Today':
        return 5;
      case '7 Days':
        return 20;
      case '30 Days':
        return 100;
      case '90 Days':
        return 300;
      default:
        return 20;
    }
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    String text;
    switch (period) {
      case 'Today':
        text = '${value.toInt() + 9}:00'.substring(0, 2);
        break;
      case '7 Days':
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        text = days[value.toInt() % 7];
        break;
      case '30 Days':
        text = '${value.toInt() + 1}';
        break;
      case '90 Days':
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        text = months[value.toInt() % 12];
        break;
      default:
        text = value.toInt().toString();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    String text;
    if (value == 0) {
      text = '0';
    } else if (value < 1000) {
      text = '${value.toInt()}';
    } else {
      text = '${(value / 1000).toInt()}k';
    }

    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      textAlign: TextAlign.left,
    );
  }
}