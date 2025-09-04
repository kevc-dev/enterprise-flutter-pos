import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/firebase_models.dart';

class FirestoreService {
  static FirestoreService? _instance;
  static FirestoreService get instance => _instance ??= FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Collection references
  CollectionReference get products => _db.collection('products');
  CollectionReference get transactions => _db.collection('transactions');
  CollectionReference get users => _db.collection('users');
  CollectionReference get dailySummaries => _db.collection('daily_summaries');

  /// PRODUCT OPERATIONS

  /// Get all active products
  Stream<List<FirebaseProduct>> getProducts() {
    return products
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirebaseProduct.fromFirestore(doc))
            .toList());
  }

  /// Get products by category
  Stream<List<FirebaseProduct>> getProductsByCategory(String category) {
    return products
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirebaseProduct.fromFirestore(doc))
            .toList());
  }

  /// Add new product
  Future<String> addProduct(FirebaseProduct product) async {
    try {
      final docRef = await products.add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      print('❌ Error adding product: $e');
      rethrow;
    }
  }

  /// Update product
  Future<void> updateProduct(FirebaseProduct product) async {
    try {
      await products.doc(product.id).update(product.toFirestore());
    } catch (e) {
      print('❌ Error updating product: $e');
      rethrow;
    }
  }

  /// Update product stock (for inventory management)
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await products.doc(productId).update({
        'stock': newStock,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Error updating product stock: $e');
      rethrow;
    }
  }

  /// Decrease product stock (after sale)
  Future<void> decreaseProductStock(String productId, int quantity) async {
    try {
      await _db.runTransaction((transaction) async {
        final productDoc = await transaction.get(products.doc(productId));
        if (!productDoc.exists) {
          throw Exception('Product not found');
        }

        final currentStock = productDoc.data() as Map<String, dynamic>;
        final newStock = (currentStock['stock'] ?? 0) - quantity;

        if (newStock < 0) {
          throw Exception('Insufficient stock');
        }

        transaction.update(products.doc(productId), {
          'stock': newStock,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      print('❌ Error decreasing product stock: $e');
      rethrow;
    }
  }

  /// TRANSACTION OPERATIONS

  /// Get transactions stream (for real-time updates)
  Stream<List<FirebaseTransaction>> getTransactions({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = transactions.orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => FirebaseTransaction.fromFirestore(doc))
        .toList());
  }

  /// Get today's transactions
  Stream<List<FirebaseTransaction>> getTodaysTransactions() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getTransactions(startDate: startOfDay, endDate: endOfDay);
  }

  /// Add new transaction
  Future<String> addTransaction(FirebaseTransaction transaction) async {
    try {
      final docRef = await transactions.add(transaction.toFirestore());
      
      // Update product stocks
      for (final item in transaction.items) {
        await decreaseProductStock(item.productId, item.quantity);
      }
      
      return docRef.id;
    } catch (e) {
      print('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  /// Update transaction status
  Future<void> updateTransactionStatus(String transactionId, TransactionStatus status) async {
    try {
      await transactions.doc(transactionId).update({
        'status': status.name,
      });
    } catch (e) {
      print('❌ Error updating transaction status: $e');
      rethrow;
    }
  }

  /// USER OPERATIONS

  /// Get user by ID
  Future<FirebaseUser?> getUser(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (doc.exists) {
        return FirebaseUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  /// Create new user profile
  Future<void> createUser(FirebaseUser user) async {
    try {
      await users.doc(user.id).set(user.toFirestore());
    } catch (e) {
      print('❌ Error creating user: $e');
      rethrow;
    }
  }

  /// Update user last login
  Future<void> updateUserLastLogin(String userId) async {
    try {
      await users.doc(userId).update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Error updating user last login: $e');
    }
  }

  /// ANALYTICS OPERATIONS

  /// Get daily summary
  Future<DailySummary?> getDailySummary(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final doc = await dailySummaries.doc(dateStr).get();
      if (doc.exists) {
        return DailySummary.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting daily summary: $e');
      return null;
    }
  }

  /// Generate daily summary from transactions
  Future<DailySummary> generateDailySummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final transactionsSnapshot = await transactions
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'completed')
          .get();

      double totalSales = 0;
      int transactionCount = transactionsSnapshot.docs.length;
      Set<String> uniqueCustomers = {};
      Map<String, int> topProducts = {};
      Map<String, double> salesByCategory = {};
      Map<String, int> paymentMethods = {};

      for (final doc in transactionsSnapshot.docs) {
        final transaction = FirebaseTransaction.fromFirestore(doc);
        
        totalSales += transaction.total;
        
        // Count unique customers (by email or phone)
        if (transaction.customerEmail != null) {
          uniqueCustomers.add(transaction.customerEmail!);
        } else if (transaction.customerPhone != null) {
          uniqueCustomers.add(transaction.customerPhone!);
        }

        // Count payment methods
        paymentMethods[transaction.paymentMethod] = 
            (paymentMethods[transaction.paymentMethod] ?? 0) + 1;

        // Process transaction items
        for (final item in transaction.items) {
          topProducts[item.productName] = 
              (topProducts[item.productName] ?? 0) + item.quantity;
        }
      }

      // Get product categories for sales by category
      for (final productName in topProducts.keys) {
        final productQuery = await products
            .where('name', isEqualTo: productName)
            .limit(1)
            .get();
        
        if (productQuery.docs.isNotEmpty) {
          final product = FirebaseProduct.fromFirestore(productQuery.docs.first);
          salesByCategory[product.category] = 
              (salesByCategory[product.category] ?? 0) + 
              (topProducts[productName]! * product.price);
        }
      }

      final summary = DailySummary(
        id: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        date: date,
        totalSales: totalSales,
        transactionCount: transactionCount,
        customerCount: uniqueCustomers.length,
        averageTicket: transactionCount > 0 ? totalSales / transactionCount : 0,
        topProducts: topProducts,
        salesByCategory: salesByCategory,
        paymentMethods: paymentMethods,
      );

      // Save the summary
      await dailySummaries.doc(summary.id).set(summary.toFirestore());
      return summary;
    } catch (e) {
      print('❌ Error generating daily summary: $e');
      rethrow;
    }
  }

  /// UTILITY METHODS

  /// Initialize sample data for demo
  Future<void> initializeSampleData() async {
    try {
      // Check if products already exist
      final existingProducts = await products.limit(1).get();
      if (existingProducts.docs.isNotEmpty) {
        print('✅ Sample data already exists');
        return;
      }

      print('📦 Initializing sample data...');

      // Sample products
      final sampleProducts = [
        FirebaseProduct(
          id: _uuid.v4(),
          name: 'Wireless Headphones',
          sku: 'WH-001',
          price: 299.99,
          category: 'Electronics',
          stock: 25,
          description: 'Premium wireless headphones with noise cancellation',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FirebaseProduct(
          id: _uuid.v4(),
          name: 'Smartphone Case',
          sku: 'SC-002',
          price: 24.99,
          category: 'Accessories',
          stock: 150,
          description: 'Protective case for smartphones',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FirebaseProduct(
          id: _uuid.v4(),
          name: 'Bluetooth Speaker',
          sku: 'BS-003',
          price: 79.99,
          category: 'Electronics',
          stock: 40,
          description: 'Portable Bluetooth speaker with excellent sound quality',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FirebaseProduct(
          id: _uuid.v4(),
          name: 'Power Bank',
          sku: 'PB-004',
          price: 49.99,
          category: 'Electronics',
          stock: 60,
          description: '10000mAh portable power bank',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FirebaseProduct(
          id: _uuid.v4(),
          name: 'USB Cable',
          sku: 'UC-005',
          price: 12.99,
          category: 'Accessories',
          stock: 200,
          description: 'High-quality USB-C cable',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Add sample products
      for (final product in sampleProducts) {
        await addProduct(product);
      }

      print('✅ Sample data initialized successfully');
    } catch (e) {
      print('❌ Error initializing sample data: $e');
    }
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      final batch = _db.batch();
      
      // Delete all documents in each collection
      final collections = [products, transactions, users, dailySummaries];
      
      for (final collection in collections) {
        final snapshot = await collection.get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }
      
      await batch.commit();
      print('✅ All data cleared successfully');
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }
}