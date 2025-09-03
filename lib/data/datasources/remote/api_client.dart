import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:retrofit/retrofit.dart';
import 'package:enterprise_flutter_pos/data/models/api_models.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: "https://api.merchant-services.bankofamerica.com/v1")
abstract class BankOfAmericaApiClient {
  factory BankOfAmericaApiClient(Dio dio, {String baseUrl}) = _BankOfAmericaApiClient;

  // Transaction Broker API
  @POST("/healthcareomnichannel/transaction_broker/authorize")
  Future<AuthorizationResponse> authorizeTransaction(
    @Body() AuthorizationRequest request,
  );

  @POST("/healthcareomnichannel/transaction_broker/capture/{transactionId}")
  Future<CaptureResponse> captureTransaction(
    @Path() String transactionId,
    @Body() CaptureRequest request,
  );

  @POST("/healthcareomnichannel/transaction_broker/void/{transactionId}")
  Future<VoidResponse> voidTransaction(
    @Path() String transactionId,
  );

  @POST("/healthcareomnichannel/transaction_broker/refund")
  Future<RefundResponse> refundTransaction(
    @Body() RefundRequest request,
  );

  @GET("/healthcareomnichannel/transaction_broker/status/{transactionId}")
  Future<TransactionStatusResponse> getTransactionStatus(
    @Path() String transactionId,
  );

  @POST("/healthcareomnichannel/transaction_broker/batch/close")
  Future<BatchCloseResponse> closeBatch(
    @Body() BatchCloseRequest request,
  );

  // Reporting API
  @GET("/healthcareomnichannel/reporting/transactions")
  Future<TransactionReportResponse> getTransactionReport(
    @Query("startDate") String startDate,
    @Query("endDate") String endDate,
    @Query("merchantId") String merchantId,
    @Query("status") String? status,
    @Query("paymentMethod") String? paymentMethod,
  );

  @GET("/healthcareomnichannel/reporting/settlements")
  Future<SettlementReportResponse> getSettlementReport(
    @Query("settlementDate") String settlementDate,
    @Query("merchantId") String merchantId,
    @Query("batchId") String? batchId,
  );

  @GET("/healthcareomnichannel/reporting/analytics/dashboard")
  Future<DashboardAnalyticsResponse> getDashboardAnalytics(
    @Query("dateRange") String dateRange,
    @Query("merchantId") String merchantId,
    @Query("granularity") String granularity,
  );

  @GET("/healthcareomnichannel/reporting/reconciliation")
  Future<ReconciliationReportResponse> getReconciliationReport(
    @Query("date") String date,
    @Query("merchantId") String merchantId,
    @Query("transactionType") String? transactionType,
  );

  // Settings API
  @GET("/healthcareomnichannel/settings/merchant/{merchantId}")
  Future<MerchantSettingsResponse> getMerchantSettings(
    @Path() String merchantId,
  );

  @PUT("/healthcareomnichannel/settings/merchant/{merchantId}")
  Future<MerchantSettingsResponse> updateMerchantSettings(
    @Path() String merchantId,
    @Body() MerchantSettingsRequest request,
  );

  @GET("/healthcareomnichannel/settings/terminal/{terminalId}")
  Future<TerminalSettingsResponse> getTerminalSettings(
    @Path() String terminalId,
  );

  @PUT("/healthcareomnichannel/settings/terminal/{terminalId}")
  Future<TerminalSettingsResponse> updateTerminalSettings(
    @Path() String terminalId,
    @Body() TerminalSettingsRequest request,
  );

  @GET("/healthcareomnichannel/settings/payment-methods")
  Future<PaymentMethodsResponse> getPaymentMethods();

  @PUT("/healthcareomnichannel/settings/payment-methods")
  Future<PaymentMethodsResponse> updatePaymentMethods(
    @Body() PaymentMethodsRequest request,
  );
}

class ApiClientFactory {
  static const String _tokenKey = 'boa_access_token';
  static const String _refreshTokenKey = 'boa_refresh_token';
  
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  
  ApiClientFactory({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add required headers
          options.headers['Content-Type'] = 'application/json';
          options.headers['X-Request-ID'] = _generateRequestId();
          
          // Add API Key (should be stored securely)
          options.headers['X-API-Key'] = await _getApiKey();
          
          // Add OAuth token if available
          final token = await _secureStorage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request with new token
              final options = error.requestOptions;
              final token = await _secureStorage.read(key: _tokenKey);
              options.headers['Authorization'] = 'Bearer $token';
              
              try {
                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              } catch (e) {
                handler.next(error);
                return;
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  String _generateRequestId() {
    return 'POS-${DateTime.now().millisecondsSinceEpoch}-${_randomString(8)}';
  }

  String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (index) => chars[DateTime.now().millisecond % chars.length],
    ).join();
  }

  Future<String> _getApiKey() async {
    // In production, this should be stored securely
    // For demo purposes, using a placeholder
    return 'demo-api-key-boa-mbss';
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      // Call OAuth refresh endpoint
      final response = await _dio.post(
        'https://auth.bankofamerica.com/oauth2/token',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': 'pos-client-id',
          'client_secret': await _getClientSecret(),
        },
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await _secureStorage.write(key: _tokenKey, value: newToken);
        await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> _getClientSecret() async {
    // In production, this should be stored securely
    return 'demo-client-secret';
  }

  BankOfAmericaApiClient create() {
    return BankOfAmericaApiClient(_dio);
  }
}