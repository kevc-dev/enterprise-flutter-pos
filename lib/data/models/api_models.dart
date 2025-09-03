import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_models.freezed.dart';
part 'api_models.g.dart';

// Authorization Models
@freezed
class AuthorizationRequest with _$AuthorizationRequest {
  const factory AuthorizationRequest({
    required double amount,
    required String currency,
    required String paymentMethod,
    required String terminalId,
    required String merchantId,
    Map<String, dynamic>? cardData,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) = _AuthorizationRequest;

  factory AuthorizationRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthorizationRequestFromJson(json);
}

@freezed
class AuthorizationResponse with _$AuthorizationResponse {
  const factory AuthorizationResponse({
    required String transactionId,
    required String authCode,
    required String status,
    required String responseMessage,
    String? referenceNumber,
    DateTime? timestamp,
  }) = _AuthorizationResponse;

  factory AuthorizationResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthorizationResponseFromJson(json);
}

// Capture Models
@freezed
class CaptureRequest with _$CaptureRequest {
  const factory CaptureRequest({
    double? amount,
    required double finalAmount,
    String? metadata,
  }) = _CaptureRequest;

  factory CaptureRequest.fromJson(Map<String, dynamic> json) =>
      _$CaptureRequestFromJson(json);
}

@freezed
class CaptureResponse with _$CaptureResponse {
  const factory CaptureResponse({
    required String captureId,
    required String status,
    required double settledAmount,
    DateTime? timestamp,
  }) = _CaptureResponse;

  factory CaptureResponse.fromJson(Map<String, dynamic> json) =>
      _$CaptureResponseFromJson(json);
}

// Void Response
@freezed
class VoidResponse with _$VoidResponse {
  const factory VoidResponse({
    required String voidId,
    required String status,
    required String responseMessage,
    DateTime? timestamp,
  }) = _VoidResponse;

  factory VoidResponse.fromJson(Map<String, dynamic> json) =>
      _$VoidResponseFromJson(json);
}

// Refund Models
@freezed
class RefundRequest with _$RefundRequest {
  const factory RefundRequest({
    required String originalTransactionId,
    required double amount,
    required String reason,
    String? merchantId,
  }) = _RefundRequest;

  factory RefundRequest.fromJson(Map<String, dynamic> json) =>
      _$RefundRequestFromJson(json);
}

@freezed
class RefundResponse with _$RefundResponse {
  const factory RefundResponse({
    required String refundId,
    required String status,
    required double refundAmount,
    String? responseMessage,
    DateTime? timestamp,
  }) = _RefundResponse;

  factory RefundResponse.fromJson(Map<String, dynamic> json) =>
      _$RefundResponseFromJson(json);
}

// Transaction Status
@freezed
class TransactionStatusResponse with _$TransactionStatusResponse {
  const factory TransactionStatusResponse({
    required String transactionId,
    required String status,
    required double amount,
    required DateTime timestamp,
    required String paymentMethod,
    String? authCode,
    String? referenceNumber,
    Map<String, dynamic>? metadata,
  }) = _TransactionStatusResponse;

  factory TransactionStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionStatusResponseFromJson(json);
}

// Batch Models
@freezed
class BatchCloseRequest with _$BatchCloseRequest {
  const factory BatchCloseRequest({
    required String terminalId,
    required String batchId,
    String? merchantId,
  }) = _BatchCloseRequest;

  factory BatchCloseRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchCloseRequestFromJson(json);
}

@freezed
class BatchCloseResponse with _$BatchCloseResponse {
  const factory BatchCloseResponse({
    required String batchId,
    required int transactionCount,
    required double totalAmount,
    required String status,
    DateTime? closedAt,
  }) = _BatchCloseResponse;

  factory BatchCloseResponse.fromJson(Map<String, dynamic> json) =>
      _$BatchCloseResponseFromJson(json);
}

// Reporting Models
@freezed
class TransactionReportResponse with _$TransactionReportResponse {
  const factory TransactionReportResponse({
    required List<TransactionReportItem> transactions,
    required int totalCount,
    required double totalAmount,
    required Map<String, dynamic> summary,
  }) = _TransactionReportResponse;

  factory TransactionReportResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionReportResponseFromJson(json);
}

@freezed
class TransactionReportItem with _$TransactionReportItem {
  const factory TransactionReportItem({
    required String transactionId,
    required double amount,
    required String status,
    required String paymentMethod,
    required DateTime timestamp,
    double? fees,
    String? customerName,
  }) = _TransactionReportItem;

  factory TransactionReportItem.fromJson(Map<String, dynamic> json) =>
      _$TransactionReportItemFromJson(json);
}

@freezed
class SettlementReportResponse with _$SettlementReportResponse {
  const factory SettlementReportResponse({
    required List<SettlementItem> settlements,
    required double totalSettled,
    required double totalFees,
    required double netAmount,
  }) = _SettlementReportResponse;

  factory SettlementReportResponse.fromJson(Map<String, dynamic> json) =>
      _$SettlementReportResponseFromJson(json);
}

@freezed
class SettlementItem with _$SettlementItem {
  const factory SettlementItem({
    required String batchId,
    required double grossAmount,
    required double fees,
    required double netAmount,
    required String status,
    required DateTime settlementDate,
  }) = _SettlementItem;

  factory SettlementItem.fromJson(Map<String, dynamic> json) =>
      _$SettlementItemFromJson(json);
}

@freezed
class DashboardAnalyticsResponse with _$DashboardAnalyticsResponse {
  const factory DashboardAnalyticsResponse({
    required Map<String, dynamic> kpis,
    required List<TrendData> trends,
    required Map<String, dynamic> performanceMetrics,
    required DateTime lastUpdated,
  }) = _DashboardAnalyticsResponse;

  factory DashboardAnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      _$DashboardAnalyticsResponseFromJson(json);
}

@freezed
class TrendData with _$TrendData {
  const factory TrendData({
    required String period,
    required double value,
    required String metric,
    double? percentageChange,
  }) = _TrendData;

  factory TrendData.fromJson(Map<String, dynamic> json) =>
      _$TrendDataFromJson(json);
}

@freezed
class ReconciliationReportResponse with _$ReconciliationReportResponse {
  const factory ReconciliationReportResponse({
    required List<ReconciliationItem> items,
    required double totalSettled,
    required double totalPending,
    required int reconciledCount,
    required int pendingCount,
  }) = _ReconciliationReportResponse;

  factory ReconciliationReportResponse.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationReportResponseFromJson(json);
}

@freezed
class ReconciliationItem with _$ReconciliationItem {
  const factory ReconciliationItem({
    required String transactionId,
    required double amount,
    required String status,
    required DateTime transactionDate,
    DateTime? settlementDate,
    String? batchId,
  }) = _ReconciliationItem;

  factory ReconciliationItem.fromJson(Map<String, dynamic> json) =>
      _$ReconciliationItemFromJson(json);
}

// Settings Models
@freezed
class MerchantSettingsResponse with _$MerchantSettingsResponse {
  const factory MerchantSettingsResponse({
    required String merchantId,
    required String businessName,
    required Map<String, dynamic> contactInfo,
    required Map<String, dynamic> taxSettings,
    required Map<String, dynamic> paymentSettings,
  }) = _MerchantSettingsResponse;

  factory MerchantSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$MerchantSettingsResponseFromJson(json);
}

@freezed
class MerchantSettingsRequest with _$MerchantSettingsRequest {
  const factory MerchantSettingsRequest({
    String? businessName,
    Map<String, dynamic>? contactInfo,
    Map<String, dynamic>? taxSettings,
    Map<String, dynamic>? paymentSettings,
  }) = _MerchantSettingsRequest;

  factory MerchantSettingsRequest.fromJson(Map<String, dynamic> json) =>
      _$MerchantSettingsRequestFromJson(json);
}

@freezed
class TerminalSettingsResponse with _$TerminalSettingsResponse {
  const factory TerminalSettingsResponse({
    required String terminalId,
    required Map<String, dynamic> configuration,
    required List<String> enabledPaymentMethods,
    required Map<String, double> limits,
    required Map<String, double> taxRates,
  }) = _TerminalSettingsResponse;

  factory TerminalSettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$TerminalSettingsResponseFromJson(json);
}

@freezed
class TerminalSettingsRequest with _$TerminalSettingsRequest {
  const factory TerminalSettingsRequest({
    Map<String, dynamic>? configuration,
    List<String>? enabledPaymentMethods,
    Map<String, double>? limits,
    Map<String, double>? taxRates,
  }) = _TerminalSettingsRequest;

  factory TerminalSettingsRequest.fromJson(Map<String, dynamic> json) =>
      _$TerminalSettingsRequestFromJson(json);
}

@freezed
class PaymentMethodsResponse with _$PaymentMethodsResponse {
  const factory PaymentMethodsResponse({
    required List<PaymentMethodConfig> methods,
    required Map<String, dynamic> processingRules,
    required Map<String, double> limits,
  }) = _PaymentMethodsResponse;

  factory PaymentMethodsResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodsResponseFromJson(json);
}

@freezed
class PaymentMethodConfig with _$PaymentMethodConfig {
  const factory PaymentMethodConfig({
    required String methodId,
    required String displayName,
    required bool enabled,
    required Map<String, dynamic> configuration,
    double? minimumAmount,
    double? maximumAmount,
  }) = _PaymentMethodConfig;

  factory PaymentMethodConfig.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodConfigFromJson(json);
}

@freezed
class PaymentMethodsRequest with _$PaymentMethodsRequest {
  const factory PaymentMethodsRequest({
    required List<PaymentMethodConfig> methods,
    Map<String, dynamic>? processingRules,
    Map<String, double>? limits,
  }) = _PaymentMethodsRequest;

  factory PaymentMethodsRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodsRequestFromJson(json);
}