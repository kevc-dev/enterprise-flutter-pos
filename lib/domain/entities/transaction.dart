import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
enum TransactionStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  authorized,
  @HiveField(2)
  captured,
  @HiveField(3)
  declined,
  @HiveField(4)
  voided,
  @HiveField(5)
  refunded,
  @HiveField(6)
  failed,
  @HiveField(7)
  settled,
}

@HiveType(typeId: 2)
enum PaymentMethod {
  @HiveField(0)
  creditCard,
  @HiveField(1)
  debitCard,
  @HiveField(2)
  cash,
  @HiveField(3)
  giftCard,
  @HiveField(4)
  applePay,
  @HiveField(5)
  googlePay,
  @HiveField(6)
  samsungPay,
  @HiveField(7)
  storeCredit,
}

@HiveType(typeId: 3)
class Transaction extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String merchantId;
  
  @HiveField(2)
  final String terminalId;
  
  @HiveField(3)
  final double amount;
  
  @HiveField(4)
  final double taxAmount;
  
  @HiveField(5)
  final double tipAmount;
  
  @HiveField(6)
  final double totalAmount;
  
  @HiveField(7)
  final String currency;
  
  @HiveField(8)
  final TransactionStatus status;
  
  @HiveField(9)
  final PaymentMethod paymentMethod;
  
  @HiveField(10)
  final DateTime timestamp;
  
  @HiveField(11)
  final String? authorizationCode;
  
  @HiveField(12)
  final String? referenceNumber;
  
  @HiveField(13)
  final String? batchId;
  
  @HiveField(14)
  final String? customerId;
  
  @HiveField(15)
  final List<TransactionItem> items;
  
  @HiveField(16)
  final String? receiptUrl;
  
  @HiveField(17)
  final String? responseMessage;
  
  @HiveField(18)
  final Map<String, dynamic>? metadata;
  
  @HiveField(19)
  final String? originalTransactionId;
  
  @HiveField(20)
  final String? cardLastFour;
  
  @HiveField(21)
  final String? cardBrand;

  const Transaction({
    required this.id,
    required this.merchantId,
    required this.terminalId,
    required this.amount,
    required this.taxAmount,
    required this.tipAmount,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.timestamp,
    required this.items,
    this.authorizationCode,
    this.referenceNumber,
    this.batchId,
    this.customerId,
    this.receiptUrl,
    this.responseMessage,
    this.metadata,
    this.originalTransactionId,
    this.cardLastFour,
    this.cardBrand,
  });

  Transaction copyWith({
    String? id,
    String? merchantId,
    String? terminalId,
    double? amount,
    double? taxAmount,
    double? tipAmount,
    double? totalAmount,
    String? currency,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? timestamp,
    String? authorizationCode,
    String? referenceNumber,
    String? batchId,
    String? customerId,
    List<TransactionItem>? items,
    String? receiptUrl,
    String? responseMessage,
    Map<String, dynamic>? metadata,
    String? originalTransactionId,
    String? cardLastFour,
    String? cardBrand,
  }) {
    return Transaction(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      terminalId: terminalId ?? this.terminalId,
      amount: amount ?? this.amount,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      timestamp: timestamp ?? this.timestamp,
      authorizationCode: authorizationCode ?? this.authorizationCode,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      batchId: batchId ?? this.batchId,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      responseMessage: responseMessage ?? this.responseMessage,
      metadata: metadata ?? this.metadata,
      originalTransactionId: originalTransactionId ?? this.originalTransactionId,
      cardLastFour: cardLastFour ?? this.cardLastFour,
      cardBrand: cardBrand ?? this.cardBrand,
    );
  }

  @override
  List<Object?> get props => [
        id,
        merchantId,
        terminalId,
        amount,
        taxAmount,
        tipAmount,
        totalAmount,
        currency,
        status,
        paymentMethod,
        timestamp,
        authorizationCode,
        referenceNumber,
        batchId,
        customerId,
        items,
        receiptUrl,
        responseMessage,
        metadata,
        originalTransactionId,
        cardLastFour,
        cardBrand,
      ];
}

@HiveType(typeId: 4)
class TransactionItem extends Equatable {
  @HiveField(0)
  final String productId;
  
  @HiveField(1)
  final String productName;
  
  @HiveField(2)
  final String sku;
  
  @HiveField(3)
  final int quantity;
  
  @HiveField(4)
  final double unitPrice;
  
  @HiveField(5)
  final double discount;
  
  @HiveField(6)
  final double subtotal;
  
  @HiveField(7)
  final bool taxable;

  const TransactionItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.subtotal,
    required this.taxable,
  });

  @override
  List<Object> get props => [
        productId,
        productName,
        sku,
        quantity,
        unitPrice,
        discount,
        subtotal,
        taxable,
      ];
}