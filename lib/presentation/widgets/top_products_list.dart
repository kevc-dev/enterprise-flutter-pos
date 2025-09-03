import 'package:flutter/material.dart';
import 'package:enterprise_flutter_pos/presentation/themes/app_theme.dart';

class TopProductsList extends StatelessWidget {
  final String period;

  const TopProductsList({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    final products = _getTopProducts();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: _getRankColor(index),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            product['name'],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${product['quantity']} sold',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Text(
            '\$${product['revenue'].toStringAsFixed(0)}',
            style: AppTheme.currencyTextStyle.copyWith(
              color: AppTheme.success,
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.gold[700] ?? Colors.amber;
      case 1:
        return Colors.grey[400] ?? Colors.grey;
      case 2:
        return Colors.brown[400] ?? Colors.brown;
      default:
        return AppTheme.primaryBlue;
    }
  }

  List<Map<String, dynamic>> _getTopProducts() {
    switch (period) {
      case 'Today':
        return [
          {'name': 'Wireless Headphones', 'quantity': 8, 'revenue': 2399.92},
          {'name': 'Bluetooth Speaker', 'quantity': 6, 'revenue': 479.94},
          {'name': 'Power Bank', 'quantity': 12, 'revenue': 599.88},
          {'name': 'Smartphone Case', 'quantity': 15, 'revenue': 374.85},
          {'name': 'USB Cable', 'quantity': 20, 'revenue': 259.80},
        ];
      case '7 Days':
        return [
          {'name': 'Wireless Headphones', 'quantity': 32, 'revenue': 9599.68},
          {'name': 'Power Bank', 'quantity': 45, 'revenue': 2249.55},
          {'name': 'Bluetooth Speaker', 'quantity': 28, 'revenue': 2239.72},
          {'name': 'Smartphone Case', 'quantity': 67, 'revenue': 1674.33},
          {'name': 'USB Cable', 'quantity': 89, 'revenue': 1156.11},
        ];
      case '30 Days':
        return [
          {'name': 'Wireless Headphones', 'quantity': 156, 'revenue': 46798.44},
          {'name': 'Power Bank', 'quantity': 189, 'revenue': 9448.11},
          {'name': 'Bluetooth Speaker', 'quantity': 134, 'revenue': 10718.66},
          {'name': 'Smartphone Case', 'quantity': 298, 'revenue': 7445.02},
          {'name': 'USB Cable', 'quantity': 445, 'revenue': 5780.55},
        ];
      case '90 Days':
        return [
          {'name': 'Wireless Headphones', 'quantity': 445, 'revenue': 133455.55},
          {'name': 'Power Bank', 'quantity': 567, 'revenue': 28349.33},
          {'name': 'Bluetooth Speaker', 'quantity': 389, 'revenue': 31106.11},
          {'name': 'Smartphone Case', 'quantity': 823, 'revenue': 20565.77},
          {'name': 'USB Cable', 'quantity': 1234, 'revenue': 16027.66},
        ];
      default:
        return [
          {'name': 'Sample Product', 'quantity': 10, 'revenue': 999.90},
        ];
    }
  }
}