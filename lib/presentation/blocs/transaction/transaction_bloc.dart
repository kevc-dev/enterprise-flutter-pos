import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:enterprise_flutter_pos/domain/entities/transaction.dart';
import 'package:enterprise_flutter_pos/domain/entities/product.dart';
import 'package:enterprise_flutter_pos/domain/usecases/transaction_usecases.dart';
import 'package:enterprise_flutter_pos/core/errors/failures.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final ProcessTransactionUseCase _processTransaction;
  final VoidTransactionUseCase _voidTransaction;
  final RefundTransactionUseCase _refundTransaction;
  final GetTransactionStatusUseCase _getTransactionStatus;

  TransactionBloc({
    required ProcessTransactionUseCase processTransaction,
    required VoidTransactionUseCase voidTransaction,
    required RefundTransactionUseCase refundTransaction,
    required GetTransactionStatusUseCase getTransactionStatus,
  })  : _processTransaction = processTransaction,
        _voidTransaction = voidTransaction,
        _refundTransaction = refundTransaction,
        _getTransactionStatus = getTransactionStatus,
        super(const TransactionInitial()) {
    on<ProcessTransactionEvent>(_onProcessTransaction);
    on<VoidTransactionEvent>(_onVoidTransaction);
    on<RefundTransactionEvent>(_onRefundTransaction);
    on<GetTransactionStatusEvent>(_onGetTransactionStatus);
    on<ResetTransactionEvent>(_onResetTransaction);
  }

  Future<void> _onProcessTransaction(
    ProcessTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionProcessing());

    final result = await _processTransaction(
      TransactionParams(
        items: event.items,
        paymentMethod: event.paymentMethod,
        amount: event.amount,
        taxAmount: event.taxAmount,
        tipAmount: event.tipAmount,
        customerId: event.customerId,
        cardData: event.cardData,
      ),
    );

    result.fold(
      (failure) => emit(TransactionError(_mapFailureToMessage(failure))),
      (transaction) => emit(TransactionSuccess(transaction)),
    );
  }

  Future<void> _onVoidTransaction(
    VoidTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionProcessing());

    final result = await _voidTransaction(VoidParams(event.transactionId));

    result.fold(
      (failure) => emit(TransactionError(_mapFailureToMessage(failure))),
      (voidResponse) => emit(TransactionVoided(voidResponse.voidId)),
    );
  }

  Future<void> _onRefundTransaction(
    RefundTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionProcessing());

    final result = await _refundTransaction(
      RefundParams(
        originalTransactionId: event.originalTransactionId,
        amount: event.amount,
        reason: event.reason,
      ),
    );

    result.fold(
      (failure) => emit(TransactionError(_mapFailureToMessage(failure))),
      (refundResponse) => emit(TransactionRefunded(
        refundResponse.refundId,
        refundResponse.refundAmount,
      )),
    );
  }

  Future<void> _onGetTransactionStatus(
    GetTransactionStatusEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionStatusLoading());

    final result = await _getTransactionStatus(
      TransactionStatusParams(event.transactionId),
    );

    result.fold(
      (failure) => emit(TransactionError(_mapFailureToMessage(failure))),
      (status) => emit(TransactionStatusLoaded(status)),
    );
  }

  void _onResetTransaction(
    ResetTransactionEvent event,
    Emitter<TransactionState> emit,
  ) {
    emit(const TransactionInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'Network connection failed. Please check your internet connection.';
      case ServerFailure:
        return 'Server error occurred. Please try again.';
      case AuthenticationFailure:
        return 'Authentication failed. Please log in again.';
      case ValidationFailure:
        return 'Invalid transaction data. Please review and try again.';
      case PaymentDeclinedFailure:
        return 'Payment was declined. Please try a different payment method.';
      case InsufficientFundsFailure:
        return 'Insufficient funds. Please try a different payment method.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}