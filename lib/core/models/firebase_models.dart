import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Product model for Firebase
class FirebaseProduct extends Equatable {
  final String id;
  final String name;
  final String sku;
  final double price;
  final String category;
  final int stock;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirebaseProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.category,
    required this.stock,
    this.description,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FirebaseProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseProduct(
      id: doc.id,
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      stock: data['stock'] ?? 0,
      description: data['description'],
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sku': sku,
      'price': price,
      'category': category,
      'stock': stock,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FirebaseProduct copyWith({
    String? name,
    String? sku,
    double? price,
    String? category,
    int? stock,
    String? description,
    String? imageUrl,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return FirebaseProduct(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, sku, price, category, stock];
}

/// Transaction model for Firebase
class FirebaseTransaction extends Equatable {
  final String id;
  final String userId;
  final String terminalId;
  final List<TransactionItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final TransactionStatus status;
  final DateTime timestamp;
  final String? description;
  final String? customerEmail;
  final String? customerPhone;

  const FirebaseTransaction({
    required this.id,
    required this.userId,
    required this.terminalId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.timestamp,
    this.description,
    this.customerEmail,
    this.customerPhone,
  });

  factory FirebaseTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      terminalId: data['terminalId'] ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => TransactionItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      status: TransactionStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
      customerEmail: data['customerEmail'],
      customerPhone: data['customerPhone'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'terminalId': terminalId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
    };
  }

  @override
  List<Object?> get props => [id, userId, timestamp, total];
}

/// Transaction item model
class TransactionItem extends Equatable {
  final String productId;
  final String productName;
  final String productSku;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  const TransactionItem({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productSku: map['productSku'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productSku': productSku,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  @override
  List<Object> get props => [productId, quantity, totalPrice];
}

/// Transaction status enum
enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

/// User model for Firebase
class FirebaseUser extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String? terminalId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const FirebaseUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.terminalId,
    this.isActive = true,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory FirebaseUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == data['role'],
        orElse: () => UserRole.cashier,
      ),
      terminalId: data['terminalId'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'terminalId': terminalId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  @override
  List<Object?> get props => [id, email, role];
}

/// User roles
enum UserRole {
  admin,      // Full access to all features
  manager,    // Store management, reports, user management
  cashier,    // Basic POS operations
  viewer,     // Read-only access for reporting
}

/// Analytics model for daily summaries
class DailySummary extends Equatable {
  final String id;
  final DateTime date;
  final double totalSales;
  final int transactionCount;
  final int customerCount;
  final double averageTicket;
  final Map<String, int> topProducts;
  final Map<String, double> salesByCategory;
  final Map<String, int> paymentMethods;

  const DailySummary({
    required this.id,
    required this.date,
    required this.totalSales,
    required this.transactionCount,
    required this.customerCount,
    required this.averageTicket,
    required this.topProducts,
    required this.salesByCategory,
    required this.paymentMethods,
  });

  factory DailySummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailySummary(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      totalSales: (data['totalSales'] ?? 0.0).toDouble(),
      transactionCount: data['transactionCount'] ?? 0,
      customerCount: data['customerCount'] ?? 0,
      averageTicket: (data['averageTicket'] ?? 0.0).toDouble(),
      topProducts: Map<String, int>.from(data['topProducts'] ?? {}),
      salesByCategory: Map<String, double>.from(data['salesByCategory'] ?? {}),
      paymentMethods: Map<String, int>.from(data['paymentMethods'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'totalSales': totalSales,
      'transactionCount': transactionCount,
      'customerCount': customerCount,
      'averageTicket': averageTicket,
      'topProducts': topProducts,
      'salesByCategory': salesByCategory,
      'paymentMethods': paymentMethods,
    };
  }

  @override
  List<Object> get props => [id, date, totalSales, transactionCount];
}