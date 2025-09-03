import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:enterprise_flutter_pos/domain/entities/product.dart';
import 'package:enterprise_flutter_pos/domain/entities/transaction.dart';
import 'package:enterprise_flutter_pos/presentation/blocs/transaction/transaction_bloc.dart';
import 'package:enterprise_flutter_pos/presentation/widgets/product_grid.dart';
import 'package:enterprise_flutter_pos/presentation/widgets/cart_panel.dart';
import 'package:enterprise_flutter_pos/presentation/widgets/payment_panel.dart';
import 'package:enterprise_flutter_pos/presentation/widgets/category_tabs.dart';
import 'package:enterprise_flutter_pos/presentation/themes/app_theme.dart';

class PosMainPage extends StatefulWidget {
  const PosMainPage({super.key});

  @override
  State<PosMainPage> createState() => _PosMainPageState();
}

class _PosMainPageState extends State<PosMainPage> {
  final List<CartItem> _cartItems = [];
  String _selectedCategory = 'All';
  bool _showPaymentPanel = false;
  
  double get subtotal => _cartItems.fold(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );
  
  double get taxAmount => subtotal * 0.0825; // 8.25% tax rate
  
  double get total => subtotal + taxAmount;

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      
      if (existingIndex >= 0) {
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
          quantity: _cartItems[existingIndex].quantity + 1,
        );
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _updateCartItem(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cartItems.removeWhere((item) => item.product.id == productId);
      } else {
        final index = _cartItems.indexWhere(
          (item) => item.product.id == productId,
        );
        if (index >= 0) {
          _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
        }
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _showPaymentPanel = false;
    });
  }

  void _showPayment() {
    if (_cartItems.isNotEmpty) {
      setState(() {
        _showPaymentPanel = true;
      });
    }
  }

  void _hidePayment() {
    setState(() {
      _showPaymentPanel = false;
    });
  }

  void _processPayment(PaymentMethod method, Map<String, dynamic>? cardData) {
    final transactionItems = _cartItems.map((cartItem) => TransactionItem(
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      sku: cartItem.product.sku,
      quantity: cartItem.quantity,
      unitPrice: cartItem.product.price,
      discount: 0.0,
      subtotal: cartItem.product.price * cartItem.quantity,
      taxable: cartItem.product.taxable,
    )).toList();

    context.read<TransactionBloc>().add(
      ProcessTransactionEvent(
        items: transactionItems,
        paymentMethod: method,
        amount: subtotal,
        taxAmount: taxAmount,
        cardData: cardData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank of America POS'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/analytics');
            },
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/transaction-history');
            },
            icon: const Icon(Icons.history),
            tooltip: 'Transaction History',
          ),
        ],
      ),
      body: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess) {
            _clearCart();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Transaction successful! ID: ${state.transaction.id}',
                ),
                backgroundColor: AppTheme.success,
              ),
            );
          } else if (state is TransactionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        child: Stack(
          children: [
            Row(
              children: [
                // Product Catalog Section (Left Side)
                Expanded(
                  flex: 2,
                  child: Container(
                    color: AppTheme.backgroundGrey,
                    child: Column(
                      children: [
                        // Category Tabs
                        CategoryTabs(
                          selectedCategory: _selectedCategory,
                          onCategoryChanged: (category) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        // Product Grid
                        Expanded(
                          child: ProductGrid(
                            selectedCategory: _selectedCategory,
                            onProductTap: _addToCart,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Cart Section (Right Side)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(color: AppTheme.divider),
                      ),
                    ),
                    child: CartPanel(
                      items: _cartItems,
                      subtotal: subtotal,
                      taxAmount: taxAmount,
                      total: total,
                      onUpdateItem: _updateCartItem,
                      onClearCart: _clearCart,
                      onCheckout: _showPayment,
                    ),
                  ),
                ),
              ],
            ),
            
            // Payment Panel Overlay
            if (_showPaymentPanel)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                      maxHeight: 700,
                    ),
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: PaymentPanel(
                        subtotal: subtotal,
                        taxAmount: taxAmount,
                        total: total,
                        items: _cartItems,
                        onPayment: _processPayment,
                        onCancel: _hidePayment,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}