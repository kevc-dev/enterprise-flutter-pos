import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PCIComplianceManager {
  static const String _encryptionKeyAlias = 'pos_encryption_key';
  static const String _sessionKeyAlias = 'pos_session_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'pos_secure_prefs',
      preferencesKeyPrefix: 'pos_',
    ),
    iOptions: IOSOptions(
      accountName: 'BankOfAmericaPOS',
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// PCI DSS Requirement 3: Protect stored cardholder data
  /// Never store sensitive authentication data (CAV2/CVC2/CID, PIN, etc.)
  static Map<String, dynamic> sanitizeCardData(Map<String, dynamic> cardData) {
    final sanitized = Map<String, dynamic>.from(cardData);
    
    // Remove prohibited data elements per PCI DSS
    sanitized.remove('cvv');
    sanitized.remove('cvc');
    sanitized.remove('cid');
    sanitized.remove('cvv2');
    sanitized.remove('cvc2');
    sanitized.remove('pin');
    sanitized.remove('pin_block');
    sanitized.remove('track_data');
    sanitized.remove('magnetic_stripe');
    
    // Mask PAN if present (should use tokenization instead)
    if (sanitized.containsKey('card_number')) {
      final cardNumber = sanitized['card_number'].toString();
      if (cardNumber.length >= 4) {
        sanitized['card_number_last_four'] = cardNumber.substring(cardNumber.length - 4);
      }
      sanitized.remove('card_number'); // Never store full PAN
    }
    
    return sanitized;
  }

  /// PCI DSS Requirement 4: Encrypt transmission of cardholder data
  static Future<String> encryptSensitiveData(String data) async {
    try {
      final key = await _getOrCreateEncryptionKey();
      final keyBytes = base64.decode(key);
      
      // Use AES-256-GCM for encryption (industry standard)
      final plainBytes = utf8.encode(data);
      final digest = sha256.convert(keyBytes + plainBytes);
      
      // In production, use proper AES-GCM encryption
      // This is a simplified example
      final encrypted = base64.encode(digest.bytes + plainBytes);
      
      return encrypted;
    } catch (e) {
      throw SecurityException('Failed to encrypt sensitive data: $e');
    }
  }

  /// Decrypt data encrypted with encryptSensitiveData
  static Future<String> decryptSensitiveData(String encryptedData) async {
    try {
      final key = await _getOrCreateEncryptionKey();
      final keyBytes = base64.decode(key);
      final encryptedBytes = base64.decode(encryptedData);
      
      // Extract original data (simplified - use proper AES-GCM in production)
      final originalData = encryptedBytes.sublist(32); // Skip hash
      
      return utf8.decode(originalData);
    } catch (e) {
      throw SecurityException('Failed to decrypt sensitive data: $e');
    }
  }

  /// Generate or retrieve encryption key
  static Future<String> _getOrCreateEncryptionKey() async {
    String? key = await _secureStorage.read(key: _encryptionKeyAlias);
    
    if (key == null) {
      // Generate 256-bit key
      final keyBytes = List<int>.generate(32, (i) => 
        DateTime.now().millisecondsSinceEpoch.hashCode + i);
      key = base64.encode(keyBytes);
      
      await _secureStorage.write(key: _encryptionKeyAlias, value: key);
    }
    
    return key;
  }

  /// PCI DSS Requirement 8: Identify and authenticate access to system components
  static Future<void> createSecureSession(String userId, String terminalId) async {
    final sessionToken = _generateSessionToken(userId, terminalId);
    final expiry = DateTime.now().add(const Duration(hours: 8));
    
    final sessionData = {
      'user_id': userId,
      'terminal_id': terminalId,
      'token': sessionToken,
      'expires_at': expiry.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    
    await _secureStorage.write(
      key: _sessionKeyAlias,
      value: jsonEncode(sessionData),
    );
  }

  /// Validate current session
  static Future<bool> validateSession() async {
    try {
      final sessionJson = await _secureStorage.read(key: _sessionKeyAlias);
      if (sessionJson == null) return false;
      
      final sessionData = jsonDecode(sessionJson);
      final expiresAt = DateTime.parse(sessionData['expires_at']);
      
      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
      return false;
    }
  }

  /// End current session
  static Future<void> endSession() async {
    await _secureStorage.delete(key: _sessionKeyAlias);
  }

  /// Generate secure session token
  static String _generateSessionToken(String userId, String terminalId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final combined = '$userId:$terminalId:$timestamp';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    
    return base64.encode(digest.bytes);
  }

  /// PCI DSS Requirement 10: Track and monitor all access to network resources
  static Future<void> logSecurityEvent({
    required String eventType,
    required String userId,
    required String terminalId,
    String? details,
    SecurityLevel level = SecurityLevel.info,
  }) async {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'event_type': eventType,
      'user_id': userId,
      'terminal_id': terminalId,
      'level': level.name,
      'details': details,
      'source_ip': 'local', // Would be actual IP in production
    };
    
    // In production, send to centralized logging system
    print('SECURITY_LOG: ${jsonEncode(logEntry)}');
  }

  /// Validate transaction amount to prevent tampering
  static bool validateTransactionIntegrity({
    required double amount,
    required double taxAmount,
    required double tipAmount,
    required double totalAmount,
  }) {
    final calculatedTotal = amount + taxAmount + tipAmount;
    const tolerance = 0.01; // Allow 1 cent tolerance for rounding
    
    return (calculatedTotal - totalAmount).abs() <= tolerance;
  }

  /// Generate tamper-evident hash for transaction
  static String generateTransactionHash({
    required String transactionId,
    required double totalAmount,
    required String merchantId,
    required String terminalId,
    required DateTime timestamp,
  }) {
    final data = '$transactionId:$totalAmount:$merchantId:$terminalId:${timestamp.toIso8601String()}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Validate transaction hash
  static bool validateTransactionHash({
    required String transactionId,
    required double totalAmount,
    required String merchantId,
    required String terminalId,
    required DateTime timestamp,
    required String providedHash,
  }) {
    final calculatedHash = generateTransactionHash(
      transactionId: transactionId,
      totalAmount: totalAmount,
      merchantId: merchantId,
      terminalId: terminalId,
      timestamp: timestamp,
    );
    
    return calculatedHash == providedHash;
  }

  /// PCI DSS Requirement 6: Develop and maintain secure systems
  static Map<String, String> getSecurityHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'Content-Security-Policy': "default-src 'self'",
      'X-Request-ID': _generateRequestId(),
    };
  }

  static String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.toString().substring(0, 8);
    return 'POS-$timestamp-$random';
  }

  /// Clear all sensitive data (for logout/reset)
  static Future<void> clearAllSensitiveData() async {
    await _secureStorage.deleteAll();
  }

  /// Rate limiting for transaction attempts
  static final Map<String, List<DateTime>> _attemptHistory = {};
  
  static bool checkRateLimit(String identifier, {int maxAttempts = 5, Duration window = const Duration(minutes: 15)}) {
    final now = DateTime.now();
    final cutoff = now.subtract(window);
    
    // Clean old attempts
    _attemptHistory[identifier]?.removeWhere((attempt) => attempt.isBefore(cutoff));
    
    // Check current attempts
    final currentAttempts = _attemptHistory[identifier]?.length ?? 0;
    
    if (currentAttempts >= maxAttempts) {
      return false;
    }
    
    // Record this attempt
    _attemptHistory[identifier] ??= [];
    _attemptHistory[identifier]!.add(now);
    
    return true;
  }

  /// Mask sensitive data for logging
  static String maskSensitiveData(String input) {
    // Mask credit card numbers
    input = input.replaceAllMapped(
      RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),
      (match) => '**** **** **** ${match.group(0)!.substring(match.group(0)!.length - 4)}',
    );
    
    // Mask SSNs
    input = input.replaceAllMapped(
      RegExp(r'\b\d{3}[-]?\d{2}[-]?\d{4}\b'),
      (match) => 'XXX-XX-${match.group(0)!.substring(match.group(0)!.length - 4)}',
    );
    
    // Mask email addresses
    input = input.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      (match) {
        final email = match.group(0)!;
        final parts = email.split('@');
        if (parts[0].length > 2) {
          return '${parts[0].substring(0, 2)}***@${parts[1]}';
        }
        return '***@${parts[1]}';
      },
    );
    
    return input;
  }
}

enum SecurityLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class SecurityException implements Exception {
  final String message;
  
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}