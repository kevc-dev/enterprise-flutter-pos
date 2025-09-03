import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String category;
  
  @HiveField(4)
  final String sku;
  
  @HiveField(5)
  final double price;
  
  @HiveField(6)
  final double costPrice;
  
  @HiveField(7)
  final int stockQuantity;
  
  @HiveField(8)
  final int minimumStock;
  
  @HiveField(9)
  final bool isActive;
  
  @HiveField(10)
  final bool taxable;
  
  @HiveField(11)
  final DateTime createdAt;
  
  @HiveField(12)
  final DateTime updatedAt;
  
  @HiveField(13)
  final String? imageUrl;
  
  @HiveField(14)
  final String? barcode;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.sku,
    required this.price,
    required this.costPrice,
    required this.stockQuantity,
    required this.minimumStock,
    required this.isActive,
    required this.taxable,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.barcode,
  });

  bool get isInStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity <= minimumStock && stockQuantity > 0;
  double get profitMargin => price > 0 ? ((price - costPrice) / price) * 100 : 0;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? sku,
    double? price,
    double? costPrice,
    int? stockQuantity,
    int? minimumStock,
    bool? isActive,
    bool? taxable,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      isActive: isActive ?? this.isActive,
      taxable: taxable ?? this.taxable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        sku,
        price,
        costPrice,
        stockQuantity,
        minimumStock,
        isActive,
        taxable,
        createdAt,
        updatedAt,
        imageUrl,
        barcode,
      ];
}