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
        child: const MainNavigationScreen(),
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

  const Product({
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

// Main Navigation Screen with Bottom Tabs
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ProductsPage(),
    const QuickSalePage(),
    const CartPage(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionSuccess) {
          context.read<CartBloc>().add(ClearCart());
          
          // Clear Quick Sale form if we're on that page
          if (_selectedIndex == 2) {
            // Find QuickSalePage and clear its form
            final quickSaleState = context.findAncestorStateOfType<_QuickSalePageState>();
            quickSaleState?._clearForm();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment successful! Transaction: ${state.transactionId}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Switch back to dashboard after successful payment
          setState(() {
            _selectedIndex = 0;
          });
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            return BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF1565C0),
              unselectedItemColor: Colors.grey[600],
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.store),
                  label: 'Products',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.point_of_sale),
                  label: 'Quick Sale',
                ),
                BottomNavigationBarItem(
                  icon: cartState.items.isNotEmpty
                      ? Badge(
                          label: Text('${cartState.items.length}'),
                          child: const Icon(Icons.shopping_cart),
                        )
                      : const Icon(Icons.shopping_cart_outlined),
                  label: 'Cart',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: 'Analytics',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Dashboard Page - Main Summary View
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank of America POS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'MBSS Terminal #001',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Today's Summary
            const Text(
              'Today\'s Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Summary Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryCard(
                  icon: Icons.attach_money,
                  title: 'Total Sales',
                  value: '\$12,543.50',
                  change: '+15.3%',
                  color: Colors.green,
                ),
                _buildSummaryCard(
                  icon: Icons.shopping_cart,
                  title: 'Transactions',
                  value: '87',
                  change: '+8.2%',
                  color: Colors.blue,
                ),
                _buildSummaryCard(
                  icon: Icons.people,
                  title: 'Customers',
                  value: '64',
                  change: '+12.5%',
                  color: Colors.orange,
                ),
                _buildSummaryCard(
                  icon: Icons.trending_up,
                  title: 'Avg. Sale',
                  value: '\$144.18',
                  change: '+6.8%',
                  color: Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.add_shopping_cart,
                    label: 'New Sale',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      // Navigate to Products tab
                      if (context.mounted) {
                        final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
                        state?.setState(() {
                          state._selectedIndex = 1; // Products index
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.point_of_sale,
                    label: 'Quick Sale',
                    color: Colors.green,
                    onTap: () {
                      // Navigate to Quick Sale tab
                      if (context.mounted) {
                        final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
                        state?.setState(() {
                          state._selectedIndex = 2; // Quick Sale index
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.receipt_long,
                    label: 'Last Receipt',
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Last receipt: TXN-1735830542'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.history,
                    label: 'Transaction History',
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to Analytics tab
                      if (context.mounted) {
                        final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
                        state?.setState(() {
                          state._selectedIndex = 4; // Analytics index
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Transactions
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._buildRecentTransactions(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String change,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildRecentTransactions() {
    final transactions = [
      {'id': 'TXN-001', 'amount': '\$299.99', 'time': '2 min ago', 'status': 'Completed'},
      {'id': 'TXN-002', 'amount': '\$79.50', 'time': '15 min ago', 'status': 'Completed'},
      {'id': 'TXN-003', 'amount': '\$156.25', 'time': '23 min ago', 'status': 'Completed'},
      {'id': 'TXN-004', 'amount': '\$44.99', 'time': '45 min ago', 'status': 'Completed'},
    ];
    
    return transactions.map((transaction) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.1),
            child: const Icon(Icons.check_circle, color: Colors.green),
          ),
          title: Text(
            transaction['id']!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(transaction['time']!),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction['amount']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1565C0),
                ),
              ),
              Text(
                transaction['status']!,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

// Quick Sale Page - Manual Transaction Entry
class QuickSalePage extends StatefulWidget {
  const QuickSalePage({super.key});

  @override
  State<QuickSalePage> createState() => _QuickSalePageState();
}

class _QuickSalePageState extends State<QuickSalePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedPaymentMethod = 'Credit Card';
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _appendToAmount(String value) {
    setState(() {
      if (value == 'C') {
        _amountController.clear();
      } else if (value == '⌫') {
        if (_amountController.text.isNotEmpty) {
          _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);
        }
      } else if (value == '.') {
        if (!_amountController.text.contains('.')) {
          _amountController.text += value;
        }
      } else {
        _amountController.text += value;
      }
    });
  }
  
  void _clearForm() {
    setState(() {
      _amountController.clear();
      _descriptionController.clear();
      _selectedPaymentMethod = 'Credit Card';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Sale'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Amount Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Enter Amount',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  readOnly: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                  decoration: const InputDecoration(
                    prefixText: '\$',
                    prefixStyle: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                    border: InputBorder.none,
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 16),
                // Description Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _descriptionController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Add description (optional)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Payment Method Selection
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPaymentMethodChip('Credit Card', Icons.credit_card),
                const SizedBox(width: 12),
                _buildPaymentMethodChip('Debit Card', Icons.credit_card),
                const SizedBox(width: 12),
                _buildPaymentMethodChip('Cash', Icons.attach_money),
              ],
            ),
          ),
          
          // Number Pad
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildNumberButton('1'),
                  _buildNumberButton('2'),
                  _buildNumberButton('3'),
                  _buildNumberButton('4'),
                  _buildNumberButton('5'),
                  _buildNumberButton('6'),
                  _buildNumberButton('7'),
                  _buildNumberButton('8'),
                  _buildNumberButton('9'),
                  _buildNumberButton('.'),
                  _buildNumberButton('0'),
                  _buildNumberButton('⌫', isBackspace: true),
                ],
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'CLEAR',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: BlocBuilder<TransactionBloc, TransactionState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is TransactionProcessing || _amountController.text.isEmpty
                              ? null
                              : () {
                                  final amount = double.tryParse(_amountController.text);
                                  if (amount != null && amount > 0) {
                                    context.read<TransactionBloc>().add(
                                      ProcessPayment(amount, _selectedPaymentMethod),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                          ),
                          child: state is TransactionProcessing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('PROCESSING...'),
                                  ],
                                )
                              : Text(
                                  _amountController.text.isEmpty
                                      ? 'CHARGE'
                                      : 'CHARGE \$${_amountController.text}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodChip(String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNumberButton(String value, {bool isBackspace = false}) {
    return InkWell(
      onTap: () => _appendToAmount(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isBackspace ? Colors.orange[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBackspace ? Colors.orange.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isBackspace ? Colors.orange : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// Products Page - Browse Products
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  final List<Product> _products = const [
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
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[100],
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return ProductCard(
              product: product,
              onTap: () {
                context.read<CartBloc>().add(AddProductToCart(product));
                // Show quick feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Cart Page - Dedicated Checkout Experience
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        centerTitle: true,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some products to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return CartItemTile(item: item);
                  },
                ),
              ),
              
              // Order Summary and Checkout
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Order Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text(
                                  '\$${state.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tax (8.25%):'),
                                Text(
                                  '\$${state.tax.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${state.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                context.read<CartBloc>().add(ClearCart());
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Clear Cart'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: BlocBuilder<TransactionBloc, TransactionState>(
                              builder: (context, transactionState) {
                                return ElevatedButton(
                                  onPressed: transactionState is TransactionProcessing
                                      ? null
                                      : () {
                                          context.read<TransactionBloc>().add(
                                            ProcessPayment(state.total, 'Credit Card'),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: transactionState is TransactionProcessing
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Processing...'),
                                          ],
                                        )
                                      : Text(
                                          'CHECKOUT \$${state.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag, size: 32, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              
              // Product Name
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Price
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              
              // Stock
              Text(
                'Stock: ${product.stock}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                Flexible(
                  child: Text(
                    '\$${item.product.price.toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<CartBloc>().add(
                          UpdateCartItem(item.product.id, item.quantity - 1),
                        );
                      },
                      icon: const Icon(Icons.remove, size: 16),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<CartBloc>().add(
                          UpdateCartItem(item.product.id, item.quantity + 1),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      padding: EdgeInsets.zero,
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

// Settings Page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Store Information Section
          _buildSectionHeader('Store Information'),
          _buildSettingsTile(
            icon: Icons.store,
            title: 'Store Name',
            subtitle: 'Bank of America MBSS Demo',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.location_on,
            title: 'Store Address',
            subtitle: '100 N Tryon St, Charlotte, NC',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.phone,
            title: 'Store Phone',
            subtitle: '(704) 386-5681',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Transaction Settings
          _buildSectionHeader('Transaction Settings'),
          _buildSettingsTile(
            icon: Icons.local_atm,
            title: 'Tax Rate',
            subtitle: '8.25%',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.receipt_long,
            title: 'Receipt Options',
            subtitle: 'Print & Email',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.payment,
            title: 'Payment Methods',
            subtitle: 'Credit, Debit, Cash',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // System Settings
          _buildSectionHeader('System'),
          _buildSettingsTile(
            icon: Icons.sync,
            title: 'Sync Data',
            subtitle: 'Last sync: 5 minutes ago',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data synced successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.backup,
            title: 'Backup Settings',
            subtitle: 'Auto backup enabled',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'PCI DSS Compliant',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0+1',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Contact support team',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Terms & Privacy',
            subtitle: 'View legal documents',
            onTap: () {},
          ),

          const SizedBox(height: 32),

          // Sign Out Button
          Card(
            color: Colors.red[50],
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Signed out successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1565C0)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}