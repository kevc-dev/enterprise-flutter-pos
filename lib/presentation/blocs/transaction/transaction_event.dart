part of 'transaction_bloc.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class ProcessTransactionEvent extends TransactionEvent {
  final List<TransactionItem> items;
  final PaymentMethod paymentMethod;
  final double amount;
  final double taxAmount;
  final double tipAmount;
  final String? customerId;
  final Map<String, dynamic>? cardData;

  const ProcessTransactionEvent({
    required this.items,
    required this.paymentMethod,
    required this.amount,
    required this.taxAmount,
    this.tipAmount = 0.0,
    this.customerId,
    this.cardData,
  });

  @override
  List<Object?> get props => [
        items,
        paymentMethod,
        amount,
        taxAmount,
        tipAmount,
        customerId,
        cardData,
      ];
}

class VoidTransactionEvent extends TransactionEvent {
  final String transactionId;

  const VoidTransactionEvent(this.transactionId);

  @override
  List<Object> get props => [transactionId];
}

class RefundTransactionEvent extends TransactionEvent {
  final String originalTransactionId;
  final double amount;
  final String reason;

  const RefundTransactionEvent({
    required this.originalTransactionId,
    required this.amount,
    required this.reason,
  });

  @override
  List<Object> get props => [originalTransactionId, amount, reason];
}

class GetTransactionStatusEvent extends TransactionEvent {
  final String transactionId;

  const GetTransactionStatusEvent(this.transactionId);

  @override
  List<Object> get props => [transactionId];
}

class ResetTransactionEvent extends TransactionEvent {
  const ResetTransactionEvent();
}