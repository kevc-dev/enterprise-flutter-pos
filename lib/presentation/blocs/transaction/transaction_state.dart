part of 'transaction_bloc.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionProcessing extends TransactionState {
  const TransactionProcessing();
}

class TransactionSuccess extends TransactionState {
  final Transaction transaction;

  const TransactionSuccess(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object> get props => [message];
}

class TransactionVoided extends TransactionState {
  final String voidId;

  const TransactionVoided(this.voidId);

  @override
  List<Object> get props => [voidId];
}

class TransactionRefunded extends TransactionState {
  final String refundId;
  final double refundAmount;

  const TransactionRefunded(this.refundId, this.refundAmount);

  @override
  List<Object> get props => [refundId, refundAmount];
}

class TransactionStatusLoading extends TransactionState {
  const TransactionStatusLoading();
}

class TransactionStatusLoaded extends TransactionState {
  final TransactionStatusResponse status;

  const TransactionStatusLoaded(this.status);

  @override
  List<Object> get props => [status];
}