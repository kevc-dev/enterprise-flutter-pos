import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:enterprise_flutter_pos/domain/entities/transaction.dart';
import 'package:enterprise_flutter_pos/presentation/pages/pos/pos_main_page.dart';
import 'package:intl/intl.dart';
import 'package:barcode/barcode.dart';

class ReceiptService {
  static const String _merchantName = 'Bank of America MBSS Demo Store';
  static const String _merchantAddress = '1234 Main Street\nAnytown, TX 12345';
  static const String _merchantPhone = '(555) 123-4567';
  static const String _taxId = 'Tax ID: 12-3456789';

  Future<Uint8List> generatePdfReceipt({
    required Transaction transaction,
    required List<CartItem> items,
    String? customerEmail,
  }) async {
    final pdf = pw.Document();
    
    // Generate QR code data
    final qrData = _generateQrCode(transaction);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              
              pw.SizedBox(height: 16),
              
              // Transaction Info
              _buildTransactionInfo(transaction),
              
              pw.SizedBox(height: 12),
              
              // Items
              _buildItemsList(items),
              
              pw.SizedBox(height: 12),
              
              // Totals
              _buildTotals(transaction),
              
              pw.SizedBox(height: 16),
              
              // Payment Info
              _buildPaymentInfo(transaction),
              
              pw.SizedBox(height: 16),
              
              // QR Code
              _buildQrCode(qrData),
              
              pw.SizedBox(height: 12),
              
              // Footer
              _buildFooter(transaction),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      children: [
        pw.Text(
          _merchantName,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _merchantAddress,
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          _merchantPhone,
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          _taxId,
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildTransactionInfo(Transaction transaction) {
    final formatter = DateFormat('MM/dd/yyyy HH:mm:ss');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Transaction ID:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              transaction.id.substring(0, 12),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date/Time:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              formatter.format(transaction.timestamp),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Terminal:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              transaction.terminalId,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        if (transaction.authorizationCode != null) ...[
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Auth Code:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                transaction.authorizationCode!,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  pw.Widget _buildItemsList(List<CartItem> items) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 4),
        ...items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.product.name,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SKU: ${item.product.sku}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    'Qty: ${item.quantity}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '\$${item.product.price.toStringAsFixed(2)} each',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        )),
        pw.SizedBox(height: 4),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildTotals(Transaction transaction) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 11)),
            pw.Text(
              '\$${transaction.amount.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tax (8.25%):', style: const pw.TextStyle(fontSize: 11)),
            pw.Text(
              '\$${transaction.taxAmount.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
          ],
        ),
        if (transaction.tipAmount > 0) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tip:', style: const pw.TextStyle(fontSize: 11)),
              pw.Text(
                '\$${transaction.tipAmount.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Divider(),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL:',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '\$${transaction.totalAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaymentInfo(Transaction transaction) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Payment Method:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              _formatPaymentMethod(transaction.paymentMethod),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        if (transaction.cardLastFour != null) ...[
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Card:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                '****${transaction.cardLastFour}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
        if (transaction.cardBrand != null) ...[
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Brand:', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                transaction.cardBrand!,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Status:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              transaction.status.name.toUpperCase(),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildQrCode(String qrData) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Container(
            width: 80,
            height: 80,
            child: pw.BarcodeWidget(
              barcode: Barcode.qrCode(),
              data: qrData,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Scan for digital receipt',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Transaction transaction) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Customer Service: (555) 123-4567',
          style: const pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Return Policy: 30 days with receipt',
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Powered by Bank of America MBSS',
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Transaction processed securely',
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  String _generateQrCode(Transaction transaction) {
    final receiptUrl = 'https://receipts.bankofamerica.com/${transaction.id}';
    return receiptUrl;
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.giftCard:
        return 'Gift Card';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.samsungPay:
        return 'Samsung Pay';
      case PaymentMethod.storeCredit:
        return 'Store Credit';
    }
  }

  Future<String> generateEmailReceipt({
    required Transaction transaction,
    required List<CartItem> items,
    required String customerEmail,
  }) async {
    final formatter = DateFormat('MM/dd/yyyy HH:mm:ss');
    final qrData = _generateQrCode(transaction);
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Receipt - ${transaction.id}</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; border-bottom: 2px solid #1565C0; padding-bottom: 20px; margin-bottom: 20px; }
        .merchant-name { font-size: 24px; font-weight: bold; color: #1565C0; }
        .merchant-info { font-size: 14px; color: #666; margin-top: 10px; }
        .transaction-info { background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0; }
        .items-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        .items-table th, .items-table td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        .items-table th { background: #1565C0; color: white; }
        .totals { background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0; }
        .total-row { font-weight: bold; font-size: 18px; }
        .payment-info { background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 20px 0; }
        .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 20px; }
        .qr-code { text-align: center; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <div class="merchant-name">$_merchantName</div>
        <div class="merchant-info">
            $_merchantAddress<br>
            $_merchantPhone<br>
            $_taxId
        </div>
    </div>

    <div class="transaction-info">
        <h3>Transaction Details</h3>
        <p><strong>Transaction ID:</strong> ${transaction.id}</p>
        <p><strong>Date/Time:</strong> ${formatter.format(transaction.timestamp)}</p>
        <p><strong>Terminal:</strong> ${transaction.terminalId}</p>
        ${transaction.authorizationCode != null ? '<p><strong>Authorization Code:</strong> ${transaction.authorizationCode}</p>' : ''}
    </div>

    <table class="items-table">
        <thead>
            <tr>
                <th>Item</th>
                <th>SKU</th>
                <th>Qty</th>
                <th>Price</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
            ${items.map((item) => '''
            <tr>
                <td>${item.product.name}</td>
                <td>${item.product.sku}</td>
                <td>${item.quantity}</td>
                <td>\$${item.product.price.toStringAsFixed(2)}</td>
                <td>\$${(item.product.price * item.quantity).toStringAsFixed(2)}</td>
            </tr>
            ''').join()}
        </tbody>
    </table>

    <div class="totals">
        <div>Subtotal: \$${transaction.amount.toStringAsFixed(2)}</div>
        <div>Tax (8.25%): \$${transaction.taxAmount.toStringAsFixed(2)}</div>
        ${transaction.tipAmount > 0 ? '<div>Tip: \$${transaction.tipAmount.toStringAsFixed(2)}</div>' : ''}
        <div class="total-row">TOTAL: \$${transaction.totalAmount.toStringAsFixed(2)}</div>
    </div>

    <div class="payment-info">
        <h3>Payment Information</h3>
        <p><strong>Method:</strong> ${_formatPaymentMethod(transaction.paymentMethod)}</p>
        ${transaction.cardLastFour != null ? '<p><strong>Card:</strong> ****${transaction.cardLastFour}</p>' : ''}
        ${transaction.cardBrand != null ? '<p><strong>Brand:</strong> ${transaction.cardBrand}</p>' : ''}
        <p><strong>Status:</strong> ${transaction.status.name.toUpperCase()}</p>
    </div>

    <div class="qr-code">
        <p>Digital Receipt: <a href="$qrData">$qrData</a></p>
    </div>

    <div class="footer">
        <p><strong>Thank you for your business!</strong></p>
        <p>Customer Service: (555) 123-4567</p>
        <p>Return Policy: 30 days with receipt</p>
        <br>
        <p>Powered by Bank of America MBSS</p>
        <p>Transaction processed securely</p>
    </div>
</body>
</html>
    ''';
  }

  Future<String> generateSmsReceipt({
    required Transaction transaction,
    required List<CartItem> items,
  }) async {
    final formatter = DateFormat('MM/dd/yyyy HH:mm');
    final qrData = _generateQrCode(transaction);
    
    return '''
$_merchantName
Receipt: ${transaction.id.substring(0, 8)}
${formatter.format(transaction.timestamp)}

Items: ${items.length}
Total: \$${transaction.totalAmount.toStringAsFixed(2)}
${_formatPaymentMethod(transaction.paymentMethod)}${transaction.cardLastFour != null ? ' ****${transaction.cardLastFour}' : ''}

Digital Receipt: $qrData

Thank you for your business!
    ''';
  }
}