import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:enterprise_flutter_pos/domain/entities/product.dart';

class CategoryTabs extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Product>>(
      valueListenable: Hive.box<Product>('products').listenable(),
      builder: (context, box, _) {
        final categories = <String>{'All'};
        for (final product in box.values) {
          if (product.isActive) {
            categories.add(product.category);
          }
        }

        final categoryList = categories.toList()..sort();

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoryList.length,
            itemBuilder: (context, index) {
              final category = categoryList[index];
              final isSelected = category == selectedCategory;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) => onCategoryChanged(category),
                  backgroundColor: Colors.white,
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}