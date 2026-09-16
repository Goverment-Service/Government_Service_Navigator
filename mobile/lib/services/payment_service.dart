import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/payment.dart';
import 'session_store.dart';

class BankDetails {
  final String accountName;
  final String bankName;
  final String branchName;
  final String accountNumber;

  BankDetails({
    required this.accountName,
    required this.bankName,
    required this.branchName,
    required this.accountNumber,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) => BankDetails(
        accountName: json['accountName'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        branchName: json['branchName'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
      );
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Talks to the same Payments/Finance API the web app's Finance Officer
/// dashboard uses. Citizens on mobile hit the citizen-facing endpoints under
/// /api/payments; the token is whatever AuthService.login/signUp stored via
/// SessionStore.
class PaymentService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await SessionStore.getToken();
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    final message = decoded is Map && decoded['message'] != null
        ? decoded['message'] as String
        : 'Request failed (${response.statusCode})';
    throw ApiException(message);
  }

  Future<BankDetails> fetchBankDetails() async {
    final response = await http.get(Uri.parse('$baseUrl/payments/bank-details'));
    return BankDetails.fromJson(_decode(response));
  }

  Future<Map<String, dynamic>> fetchStripeConfig() async {
    final response = await http.get(Uri.parse('$baseUrl/payments/stripe/publishable-key'));
    return _decode(response);
  }

  Future<Payment> submitBankTransferPayment({
    String? applicationId,
    required String serviceName,
    required double amount,
    required String bankName,
    required String branchName,
    required String accountNumber,
    required String referenceNumber,
    required DateTime paymentDate,
    required File slip,
  }) async {
    final headers = await _authHeaders();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/payments/bank-transfer'))
      ..headers.addAll(headers)
      ..fields['ServiceName'] = serviceName
      ..fields['Amount'] = amount.toString()
      ..fields['BankName'] = bankName
      ..fields['BranchName'] = branchName
      ..fields['AccountNumber'] = accountNumber
      ..fields['ReferenceNumber'] = referenceNumber
      ..fields['PaymentDate'] = paymentDate.toIso8601String();
    if (applicationId != null && applicationId.isNotEmpty) {
      request.fields['ApplicationId'] = applicationId;
    }
    request.files.add(await http.MultipartFile.fromPath('Slip', slip.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return Payment.fromJson(_decode(response));
  }

  Future<Map<String, dynamic>> createStripeIntent({
    String? applicationId,
    required String serviceName,
    required double amount,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/payments/stripe/create-intent'),
      headers: {'Content-Type': 'application/json', ...headers},
      body: jsonEncode({
        'applicationId': applicationId,
        'serviceName': serviceName,
        'amount': amount,
      }),
    );
    return _decode(response);
  }

  Future<Payment> syncStripePayment(int paymentId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/payments/stripe/$paymentId/sync'),
      headers: headers,
    );
    return Payment.fromJson(_decode(response));
  }

  Future<List<Payment>> fetchMyPayments() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/payments/my'), headers: headers);
    final body = response.body.isEmpty ? '[]' : response.body;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Could not load your payments (${response.statusCode})');
    }
    final decoded = jsonDecode(body) as List<dynamic>;
    return decoded.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RefundInfo> requestRefund(int paymentId, String reason) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/payments/$paymentId/refund-request'),
      headers: {'Content-Type': 'application/json', ...headers},
      body: jsonEncode({'reason': reason}),
    );
    return RefundInfo.fromJson(_decode(response));
  }
}
