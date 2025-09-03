import 'package:flutter/material.dart';
import 'package:enterprise_flutter_pos/domain/entities/transaction.dart';
import 'package:enterprise_flutter_pos/presentation/pages/pos/pos_main_page.dart';
import 'package:enterprise_flutter_pos/presentation/themes/app_theme.dart';

class PaymentPanel extends StatefulWidget {
  final double subtotal;
  final double taxAmount;
  final double total;
  final List<CartItem> items;
  final Function(PaymentMethod, Map<String, dynamic>?) onPayment;
  final VoidCallback onCancel;

  const PaymentPanel({
    super.key,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.items,
    required this.onPayment,
    required this.onCancel,
  });

  @override
  State<PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends State<PaymentPanel> {
  PaymentMethod _selectedMethod = PaymentMethod.creditCard;
  double _tipAmount = 0.0;
  
  final List<double> _tipPresets = [0.0, 0.15, 0.18, 0.20];
  
  double get totalWithTip => widget.total + _tipAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Order Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(
                      '\$${widget.subtotal.toStringAsFixed(2)}',
                      style: AppTheme.currencyTextStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax:'),
                    Text(
                      '\$${widget.taxAmount.toStringAsFixed(2)}',
                      style: AppTheme.currencyTextStyle,
                    ),
                  ],
                ),
                if (_tipAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tip:'),
                      Text(
                        '\$${_tipAmount.toStringAsFixed(2)}',
                        style: AppTheme.currencyTextStyle,
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '\$${totalWithTip.toStringAsFixed(2)}',
                      style: AppTheme.largeCurrencyTextStyle.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tip Selection
          Text(
            'Tip',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: _tipPresets.map((tipPercent) {
              final tipAmount = tipPercent == 0 ? 0.0 : widget.subtotal * tipPercent;
              final isSelected = (_tipAmount - tipAmount).abs() < 0.01;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _tipAmount = tipAmount;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? AppTheme.primaryBlue : null,
                      foregroundColor: isSelected ? Colors.white : null,
                    ),
                    child: Text(
                      tipPercent == 0 
                          ? 'No Tip'
                          : '${(tipPercent * 100).toInt()}%',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Method Selection
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _PaymentMethodTile(
                  method: PaymentMethod.creditCard,
                  icon: Icons.credit_card,
                  label: 'Credit Card',
                  isSelected: _selectedMethod == PaymentMethod.creditCard,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.creditCard),
                ),
                _PaymentMethodTile(
                  method: PaymentMethod.debitCard,
                  icon: Icons.payment,
                  label: 'Debit Card',
                  isSelected: _selectedMethod == PaymentMethod.debitCard,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.debitCard),
                ),
                _PaymentMethodTile(
                  method: PaymentMethod.cash,
                  icon: Icons.attach_money,
                  label: 'Cash',
                  isSelected: _selectedMethod == PaymentMethod.cash,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
                ),
                _PaymentMethodTile(
                  method: PaymentMethod.applePay,
                  icon: Icons.phone_iphone,
                  label: 'Apple Pay',
                  isSelected: _selectedMethod == PaymentMethod.applePay,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.applePay),
                ),
                _PaymentMethodTile(
                  method: PaymentMethod.googlePay,
                  icon: Icons.android,
                  label: 'Google Pay',
                  isSelected: _selectedMethod == PaymentMethod.googlePay,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.googlePay),
                ),
                _PaymentMethodTile(
                  method: PaymentMethod.giftCard,
                  icon: Icons.card_giftcard,
                  label: 'Gift Card',
                  isSelected: _selectedMethod == PaymentMethod.giftCard,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.giftCard),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Map<String, dynamic>? cardData;
                    
                    // Simulate card data for credit/debit cards
                    if (_selectedMethod == PaymentMethod.creditCard || 
                        _selectedMethod == PaymentMethod.debitCard) {
                      cardData = {
                        'card_type': _selectedMethod == PaymentMethod.creditCard ? 'credit' : 'debit',
                        'last_four': '1234',
                        'brand': 'VISA',
                        // Never include actual card numbers in real implementation
                      };
                    }
                    
                    widget.onPayment(_selectedMethod, cardData);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'PROCESS PAYMENT - \$${totalWithTip.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryBlue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}