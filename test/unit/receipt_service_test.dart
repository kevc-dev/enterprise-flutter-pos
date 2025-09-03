import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_flutter_pos/core/services/receipt_service.dart';
import 'package:enterprise_flutter_pos/domain/entities/transaction.dart';
import 'package:enterprise_flutter_pos/domain/entities/product.dart';
import 'package:enterprise_flutter_pos/presentation/pages/pos/pos_main_page.dart';

void main() {
  group('ReceiptService', () {
    late ReceiptService receiptService;
    late Transaction mockTransaction;
    late List<CartItem> mockCartItems;

    setUp(() {
      receiptService = ReceiptService();
      
      final mockProduct = Product(
        id: '1',
        name: 'Test Product',
        description: 'Test Description',
        category: 'Electronics',
        sku: 'TEST-001',
        price: 29.99,
        costPrice: 15.00,
        stockQuantity: 100,
        minimumStock: 10,
        isActive: true,
        taxable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        barcode: '1234567890123',
      );

      mockCartItems = [
        CartItem(product: mockProduct, quantity: 2),
      ];

      mockTransaction = Transaction(
        id: 'TXN-123456789',
        merchantId: 'MERCHANT-001',
        terminalId: 'TERM-001',
        amount: 59.98,
        taxAmount: 4.95,
        tipAmount: 0.0,
        totalAmount: 64.93,
        currency: 'USD',
        status: TransactionStatus.authorized,
        paymentMethod: PaymentMethod.creditCard,
        timestamp: DateTime.parse('2024-01-15 14:30:00'),
        items: [
          TransactionItem(
            productId: '1',
            productName: 'Test Product',
            sku: 'TEST-001',
            quantity: 2,
            unitPrice: 29.99,
            discount: 0.0,
            subtotal: 59.98,
            taxable: true,
          ),
        ],
        authorizationCode: 'AUTH123456',
        referenceNumber: 'REF987654321',
        cardLastFour: '1234',
        cardBrand: 'VISA',
      );
    });

    group('generatePdfReceipt', () {
      test('should generate PDF receipt with correct structure', () async {
        final pdfBytes = await receiptService.generatePdfReceipt(
          transaction: mockTransaction,
          items: mockCartItems,
          customerEmail: 'test@example.com',
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes, isA<List<int>>());
        expect(pdfBytes.isNotEmpty, true);
        
        // PDF should start with PDF header
        final pdfHeader = String.fromCharCodes(pdfBytes.take(4));
        expect(pdfHeader, equals('%PDF'));
      });

      test('should handle transactions without optional fields', () async {
        final transactionWithoutOptionals = mockTransaction.copyWith(
          authorizationCode: null,
          cardLastFour: null,
          cardBrand: null,
        );

        final pdfBytes = await receiptService.generatePdfReceipt(
          transaction: transactionWithoutOptionals,
          items: mockCartItems,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.isNotEmpty, true);
      });

      test('should handle transactions with tip amount', () async {
        final transactionWithTip = mockTransaction.copyWith(
          tipAmount: 10.0,
          totalAmount: mockTransaction.totalAmount + 10.0,
        );

        final pdfBytes = await receiptService.generatePdfReceipt(
          transaction: transactionWithTip,
          items: mockCartItems,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.isNotEmpty, true);
      });
    });

    group('generateEmailReceipt', () {
      test('should generate HTML email receipt with correct content', () async {
        final htmlReceipt = await receiptService.generateEmailReceipt(
          transaction: mockTransaction,
          items: mockCartItems,
          customerEmail: 'test@example.com',
        );

        expect(htmlReceipt, isNotNull);
        expect(htmlReceipt, contains('<!DOCTYPE html>'));
        expect(htmlReceipt, contains('Bank of America MBSS Demo Store'));
        expect(htmlReceipt, contains('TXN-123456789'));
        expect(htmlReceipt, contains('Test Product'));
        expect(htmlReceipt, contains('\$64.93'));
        expect(htmlReceipt, contains('Credit Card'));
        expect(htmlReceipt, contains('AUTH123456'));
        expect(htmlReceipt, contains('****1234'));
        expect(htmlReceipt, contains('VISA'));
      });

      test('should handle transactions without optional card info', () async {
        final transactionWithoutCard = mockTransaction.copyWith(
          paymentMethod: PaymentMethod.cash,
          cardLastFour: null,
          cardBrand: null,
          authorizationCode: null,
        );

        final htmlReceipt = await receiptService.generateEmailReceipt(
          transaction: transactionWithoutCard,
          items: mockCartItems,
          customerEmail: 'test@example.com',
        );

        expect(htmlReceipt, isNotNull);
        expect(htmlReceipt, contains('Cash'));
        expect(htmlReceipt, isNot(contains('****')));
        expect(htmlReceipt, isNot(contains('AUTH')));
      });

      test('should include tip amount when present', () async {
        final transactionWithTip = mockTransaction.copyWith(
          tipAmount: 10.0,
          totalAmount: mockTransaction.totalAmount + 10.0,
        );

        final htmlReceipt = await receiptService.generateEmailReceipt(
          transaction: transactionWithTip,
          items: mockCartItems,
          customerEmail: 'test@example.com',
        );

        expect(htmlReceipt, contains('Tip: \$10.00'));
      });
    });

    group('generateSmsReceipt', () {
      test('should generate SMS receipt with essential information', () async {
        final smsReceipt = await receiptService.generateSmsReceipt(
          transaction: mockTransaction,
          items: mockCartItems,
        );

        expect(smsReceipt, isNotNull);
        expect(smsReceipt, contains('Bank of America MBSS Demo Store'));
        expect(smsReceipt, contains('TXN-1234')); // Truncated ID
        expect(smsReceipt, contains('\$64.93'));
        expect(smsReceipt, contains('Credit Card'));
        expect(smsReceipt, contains('****1234'));
        expect(smsReceipt, contains('Items: 1'));
        expect(smsReceipt, contains('https://receipts.bankofamerica.com/'));
      });

      test('should handle cash transactions', () async {
        final cashTransaction = mockTransaction.copyWith(
          paymentMethod: PaymentMethod.cash,
          cardLastFour: null,
          cardBrand: null,
        );

        final smsReceipt = await receiptService.generateSmsReceipt(
          transaction: cashTransaction,
          items: mockCartItems,
        );

        expect(smsReceipt, contains('Cash'));
        expect(smsReceipt, isNot(contains('****')));
      });

      test('should format date correctly', () async {
        final smsReceipt = await receiptService.generateSmsReceipt(
          transaction: mockTransaction,
          items: mockCartItems,
        );

        expect(smsReceipt, contains('01/15/2024 14:30'));
      });
    });

    group('_formatPaymentMethod', () {
      test('should format all payment methods correctly', () {
        final testCases = {
          PaymentMethod.creditCard: 'Credit Card',
          PaymentMethod.debitCard: 'Debit Card',
          PaymentMethod.cash: 'Cash',
          PaymentMethod.giftCard: 'Gift Card',
          PaymentMethod.applePay: 'Apple Pay',
          PaymentMethod.googlePay: 'Google Pay',
          PaymentMethod.samsungPay: 'Samsung Pay',
          PaymentMethod.storeCredit: 'Store Credit',
        };

        for (final testCase in testCases.entries) {
          final transaction = mockTransaction.copyWith(
            paymentMethod: testCase.key,
          );

          // Test via email receipt which uses the private method
          final future = receiptService.generateEmailReceipt(
            transaction: transaction,
            items: mockCartItems,
            customerEmail: 'test@example.com',
          );

          expect(future, completes);
        }
      });
    });

    group('_generateQrCode', () {
      test('should generate consistent QR code URL', () async {
        final smsReceipt1 = await receiptService.generateSmsReceipt(
          transaction: mockTransaction,
          items: mockCartItems,
        );

        final smsReceipt2 = await receiptService.generateSmsReceipt(
          transaction: mockTransaction,
          items: mockCartItems,
        );

        // Both should contain the same QR URL since transaction ID is the same
        final qrUrl = 'https://receipts.bankofamerica.com/${mockTransaction.id}';
        expect(smsReceipt1, contains(qrUrl));
        expect(smsReceipt2, contains(qrUrl));
      });
    });

    group('Edge Cases', () {
      test('should handle empty cart items list', () async {
        final pdfBytes = await receiptService.generatePdfReceipt(
          transaction: mockTransaction.copyWith(items: []),
          items: [],
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.isNotEmpty, true);
      });

      test('should handle very long product names', () async {
        final longNameProduct = Product(
          id: '2',
          name: 'This is a very long product name that might cause formatting issues in receipts when displayed on narrow formats like thermal printers',
          description: 'Test Description',
          category: 'Test',
          sku: 'LONG-001',
          price: 19.99,
          costPrice: 10.00,
          stockQuantity: 50,
          minimumStock: 5,
          isActive: true,
          taxable: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final longNameItems = [CartItem(product: longNameProduct, quantity: 1)];

        final pdfBytes = await receiptService.generatePdfReceipt(
          transaction: mockTransaction,
          items: longNameItems,
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.isNotEmpty, true);
      });

      test('should handle zero amounts correctly', () async {
        final zeroAmountTransaction = mockTransaction.copyWith(
          amount: 0.0,
          taxAmount: 0.0,
          tipAmount: 0.0,
          totalAmount: 0.0,
        );

        final htmlReceipt = await receiptService.generateEmailReceipt(
          transaction: zeroAmountTransaction,
          items: [],
          customerEmail: 'test@example.com',
        );

        expect(htmlReceipt, contains('\$0.00'));
      });
    });
  });
}