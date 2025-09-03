import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  runApp(const SimplePosApp());
}

class SimplePosApp extends StatelessWidget {
  const SimplePosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank of America POS Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1565C0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => CartBloc()),
          BlocProvider(create: (context) => TransactionBloc()),
        ],
        child: const PosMainScreen(),
      ),
    );
  }
}

// Simple Product Model
class Product {
  final String id;
  final String name;
  final String sku;
  final double price;
  final String category;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.category,
    required this.stock,
  });
}

// Cart Item
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

// Cart Bloc
abstract class CartEvent {}

class AddProductToCart extends CartEvent {
  final Product product;
  AddProductToCart(this.product);
}

class UpdateCartItem extends CartEvent {
  final String productId;
  final int quantity;
  UpdateCartItem(this.productId, this.quantity);
}

class ClearCart extends CartEvent {}

class CartState {
  final List<CartItem> items;
  
  CartState({required this.items});
  
  double get subtotal => items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  double get tax => subtotal * 0.0825;
  double get total => subtotal + tax;
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState(items: [])) {
    on<AddProductToCart>(_onAddProduct);
    on<UpdateCartItem>(_onUpdateItem);
    on<ClearCart>(_onClearCart);
  }

  void _onAddProduct(AddProductToCart event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final existingIndex = items.indexWhere((item) => item.product.id == event.product.id);
    
    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + 1,
      );
    } else {
      items.add(CartItem(product: event.product, quantity: 1));
    }
    
    emit(CartState(items: items));
  }

  void _onUpdateItem(UpdateCartItem event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    
    if (event.quantity <= 0) {
      items.removeWhere((item) => item.product.id == event.productId);
    } else {
      final index = items.indexWhere((item) => item.product.id == event.productId);
      if (index >= 0) {
        items[index] = items[index].copyWith(quantity: event.quantity);
      }
    }
    
    emit(CartState(items: items));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartState(items: []));
  }
}

// Transaction Bloc
abstract class TransactionEvent {}

class ProcessPayment extends TransactionEvent {
  final double amount;
  final String paymentMethod;
  ProcessPayment(this.amount, this.paymentMethod);
}

abstract class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionProcessing extends TransactionState {}

class TransactionSuccess extends TransactionState {
  final String transactionId;
  TransactionSuccess(this.transactionId);
}

class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
}

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc() : super(TransactionInitial()) {
    on<ProcessPayment>(_onProcessPayment);
  }

  Future<void> _onProcessPayment(ProcessPayment event, Emitter<TransactionState> emit) async {
    emit(TransactionProcessing());
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    // Random success/failure for demo
    if (DateTime.now().millisecond % 10 != 0) {
      emit(TransactionSuccess('TXN-${DateTime.now().millisecondsSinceEpoch}'));
    } else {
      emit(TransactionError('Payment declined'));
    }
  }
}

// Main POS Screen
class PosMainScreen extends StatefulWidget {
  const PosMainScreen({super.key});

  @override
  State<PosMainScreen> createState() => _PosMainScreenState();
}

class _PosMainScreenState extends State<PosMainScreen> {
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Wireless Headphones',
      sku: 'WH-001',
      price: 299.99,
      category: 'Electronics',
      stock: 25,
    ),
    Product(
      id: '2',
      name: 'Smartphone Case',
      sku: 'SC-002',
      price: 24.99,
      category: 'Accessories',
      stock: 150,
    ),
    Product(
      id: '3',
      name: 'Bluetooth Speaker',
      sku: 'BS-003',
      price: 79.99,
      category: 'Electronics',
      stock: 40,
    ),
    Product(
      id: '4',
      name: 'Power Bank',
      sku: 'PB-004',
      price: 49.99,
      category: 'Electronics',
      stock: 60,
    ),
    Product(
      id: '5',
      name: 'USB Cable',
      sku: 'UC-005',
      price: 12.99,
      category: 'Accessories',
      stock: 200,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank of America POS'),
        actions: [
          IconButton(
            onPressed: () => _showAnalytics(context),
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics',
          ),
        ],
      ),
      body: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess) {
            context.read<CartBloc>().add(ClearCart());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment successful! Transaction: ${state.transactionId}'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Row(
          children: [
            // Product Grid
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[100],
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.read<CartBloc>().add(AddProductToCart(product)),
                    );
                  },
                ),
              ),
            ),
            
            // Cart Panel
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.grey)),
                ),
                child: const CartPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalytics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
    );
  }
}

// Product Card Widget
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Placeholder
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              
              // Product Name
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Price and Stock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Cart Panel Widget
class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cart (${state.items.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (state.items.isNotEmpty)
                    TextButton(
                      onPressed: () => context.read<CartBloc>().add(ClearCart()),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            
            // Cart Items
            Expanded(
              child: state.items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Cart is empty', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return CartItemTile(item: item);
                      },
                    ),
            ),
            
            // Totals and Checkout
            if (state.items.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('\$${state.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax (8.25%):'),
                        Text('\$${state.tax.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '\$${state.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<TransactionBloc, TransactionState>(
                        builder: (context, transactionState) {
                          return ElevatedButton(
                            onPressed: transactionState is TransactionProcessing
                                ? null
                                : () => context.read<TransactionBloc>().add(
                                      ProcessPayment(state.total, 'Credit Card'),
                                    ),
                            child: transactionState is TransactionProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('CHECKOUT'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// Cart Item Tile Widget
class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.product.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: ${item.product.sku}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${item.product.price.toStringAsFixed(2)}'),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<CartBloc>().add(
                          UpdateCartItem(item.product.id, item.quantity - 1),
                        );
                      },
                      icon: const Icon(Icons.remove),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      onPressed: () {
                        context.read<CartBloc>().add(
                          UpdateCartItem(item.product.id, item.quantity + 1),
                        );
                      },
                      icon: const Icon(Icons.add),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: \$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Analytics Screen
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // KPI Cards
            Row(
              children: [
                Expanded(child: _buildKpiCard('Daily Sales', '\$12,543.50', '+15.3%', Icons.attach_money)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard('Transactions', '87', '+8.2%', Icons.receipt_long)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildKpiCard('Avg. Ticket', '\$144.18', '+6.8%', Icons.shopping_cart)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard('Top Product', 'Headphones', '\$2,134.90', Icons.star)),
              ],
            ),
            const SizedBox(height: 32),
            
            // Demo Chart Placeholder
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sales Trend - Today',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.show_chart, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Interactive Chart\n(FL Chart integration)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String change, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: const Color(0xFF1565C0)),
                Text(
                  change,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}