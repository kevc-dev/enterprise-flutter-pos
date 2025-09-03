import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:enterprise_flutter_pos/presentation/blocs/transaction/transaction_bloc.dart';
import 'package:enterprise_flutter_pos/domain/entities/transaction.dart';
import 'package:enterprise_flutter_pos/main.dart';

class MockProcessTransactionUseCase extends Mock implements MockProcessTransactionUseCase {}
class MockVoidTransactionUseCase extends Mock implements MockVoidTransactionUseCase {}
class MockRefundTransactionUseCase extends Mock implements MockRefundTransactionUseCase {}
class MockGetTransactionStatusUseCase extends Mock implements MockGetTransactionStatusUseCase {}

void main() {
  group('TransactionBloc', () {
    late TransactionBloc transactionBloc;
    late MockProcessTransactionUseCase mockProcessTransaction;
    late MockVoidTransactionUseCase mockVoidTransaction;
    late MockRefundTransactionUseCase mockRefundTransaction;
    late MockGetTransactionStatusUseCase mockGetTransactionStatus;

    setUp(() {
      mockProcessTransaction = MockProcessTransactionUseCase();
      mockVoidTransaction = MockVoidTransactionUseCase();
      mockRefundTransaction = MockRefundTransactionUseCase();
      mockGetTransactionStatus = MockGetTransactionStatusUseCase();
      
      transactionBloc = TransactionBloc(
        processTransaction: mockProcessTransaction,
        voidTransaction: mockVoidTransaction,
        refundTransaction: mockRefundTransaction,
        getTransactionStatus: mockGetTransactionStatus,
      );
    });

    tearDown(() {
      transactionBloc.close();
    });

    test('initial state is TransactionInitial', () {
      expect(transactionBloc.state, equals(const TransactionInitial()));
    });

    group('ProcessTransactionEvent', () {
      final mockTransaction = Transaction(
        id: 'test-transaction-id',
        merchantId: 'test-merchant',
        terminalId: 'test-terminal',
        amount: 100.0,
        taxAmount: 8.25,
        tipAmount: 0.0,
        totalAmount: 108.25,
        currency: 'USD',
        status: TransactionStatus.authorized,
        paymentMethod: PaymentMethod.creditCard,
        timestamp: DateTime.now(),
        items: const [],
      );

      final transactionParams = TransactionParams(
        items: const [],
        paymentMethod: PaymentMethod.creditCard,
        amount: 100.0,
        taxAmount: 8.25,
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [TransactionProcessing, TransactionSuccess] when transaction succeeds',
        build: () {
          when(() => mockProcessTransaction.call(any()))
              .thenAnswer((_) async => Right(mockTransaction));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(ProcessTransactionEvent(
          items: transactionParams.items,
          paymentMethod: transactionParams.paymentMethod,
          amount: transactionParams.amount,
          taxAmount: transactionParams.taxAmount,
        )),
        expect: () => [
          const TransactionProcessing(),
          TransactionSuccess(mockTransaction),
        ],
        verify: (_) {
          verify(() => mockProcessTransaction.call(any())).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [TransactionProcessing, TransactionError] when transaction fails',
        build: () {
          when(() => mockProcessTransaction.call(any()))
              .thenAnswer((_) async => Left(NetworkFailure()));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(ProcessTransactionEvent(
          items: transactionParams.items,
          paymentMethod: transactionParams.paymentMethod,
          amount: transactionParams.amount,
          taxAmount: transactionParams.taxAmount,
        )),
        expect: () => [
          const TransactionProcessing(),
          const TransactionError(
            'Network connection failed. Please check your internet connection.',
          ),
        ],
        verify: (_) {
          verify(() => mockProcessTransaction.call(any())).called(1);
        },
      );
    });

    group('VoidTransactionEvent', () {
      const voidResponse = VoidResponse(
        voidId: 'void-123',
        status: 'success',
        responseMessage: 'Transaction voided',
        timestamp: null,
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [TransactionProcessing, TransactionVoided] when void succeeds',
        build: () {
          when(() => mockVoidTransaction.call(any()))
              .thenAnswer((_) async => const Right(voidResponse));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(const VoidTransactionEvent('transaction-id')),
        expect: () => [
          const TransactionProcessing(),
          const TransactionVoided('void-123'),
        ],
        verify: (_) {
          verify(() => mockVoidTransaction.call(any())).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [TransactionProcessing, TransactionError] when void fails',
        build: () {
          when(() => mockVoidTransaction.call(any()))
              .thenAnswer((_) async => Left(ServerFailure()));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(const VoidTransactionEvent('transaction-id')),
        expect: () => [
          const TransactionProcessing(),
          const TransactionError('Server error occurred. Please try again.'),
        ],
        verify: (_) {
          verify(() => mockVoidTransaction.call(any())).called(1);
        },
      );
    });

    group('RefundTransactionEvent', () {
      final refundResponse = RefundResponse(
        refundId: 'refund-123',
        status: 'success',
        refundAmount: 50.0,
        responseMessage: 'Refund processed',
        timestamp: DateTime.now(),
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [TransactionProcessing, TransactionRefunded] when refund succeeds',
        build: () {
          when(() => mockRefundTransaction.call(any()))
              .thenAnswer((_) async => Right(refundResponse));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(const RefundTransactionEvent(
          originalTransactionId: 'original-id',
          amount: 50.0,
          reason: 'Customer request',
        )),
        expect: () => [
          const TransactionProcessing(),
          const TransactionRefunded('refund-123', 50.0),
        ],
        verify: (_) {
          verify(() => mockRefundTransaction.call(any())).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [TransactionProcessing, TransactionError] when refund fails',
        build: () {
          when(() => mockRefundTransaction.call(any()))
              .thenAnswer((_) async => Left(PaymentDeclinedFailure()));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(const RefundTransactionEvent(
          originalTransactionId: 'original-id',
          amount: 50.0,
          reason: 'Customer request',
        )),
        expect: () => [
          const TransactionProcessing(),
          const TransactionError(
            'Payment was declined. Please try a different payment method.',
          ),
        ],
        verify: (_) {
          verify(() => mockRefundTransaction.call(any())).called(1);
        },
      );
    });

    group('GetTransactionStatusEvent', () {
      final statusResponse = TransactionStatusResponse(
        transactionId: 'transaction-id',
        status: 'authorized',
        amount: 100.0,
        timestamp: DateTime.now(),
        paymentMethod: 'credit_card',
        authCode: 'AUTH123',
        referenceNumber: 'REF123',
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [TransactionStatusLoading, TransactionStatusLoaded] when status check succeeds',
        build: () {
          when(() => mockGetTransactionStatus.call(any()))
              .thenAnswer((_) async => Right(statusResponse));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(const GetTransactionStatusEvent('transaction-id')),
        expect: () => [
          const TransactionStatusLoading(),
          TransactionStatusLoaded(statusResponse),
        ],
        verify: (_) {
          verify(() => mockGetTransactionStatus.call(any())).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [TransactionStatusLoading, TransactionError] when status check fails',
        build: () {
          when(() => mockGetTransactionStatus.call(any()))
              .thenAnswer((_) async => Left(AuthenticationFailure()));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(const GetTransactionStatusEvent('transaction-id')),
        expect: () => [
          const TransactionStatusLoading(),
          const TransactionError('Authentication failed. Please log in again.'),
        ],
        verify: (_) {
          verify(() => mockGetTransactionStatus.call(any())).called(1);
        },
      );
    });

    group('ResetTransactionEvent', () {
      blocTest<TransactionBloc, TransactionState>(
        'emits TransactionInitial when reset event is added',
        build: () => transactionBloc,
        seed: () => const TransactionError('Some error'),
        act: (bloc) => bloc.add(const ResetTransactionEvent()),
        expect: () => [const TransactionInitial()],
      );
    });
  });
}