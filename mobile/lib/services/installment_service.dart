import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/installment_plan.dart';

class InstallmentService {
  final String _token;

  InstallmentService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  int _cleanIntId(String rawId) {
    final parsed = int.tryParse(rawId);
    if (parsed != null) return parsed;
    final digits = rawId.replaceAll(RegExp(r'[^\d]'), '');
    return int.tryParse(digits) ?? 1;
  }

  /// PUT /api/payments/{id}/installment-plan
  Future<InstallmentPlan> createInstallmentPlan(
    String paymentId, {
    required int numberOfInstallments,
    int intervalDays = 30,
  }) async {
    final cleanPaymentId = _cleanIntId(paymentId);
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/payments/$cleanPaymentId/installment-plan'),
      headers: _headers,
      body: jsonEncode({
        'numberOfInstallments': numberOfInstallments,
        'intervalDays': intervalDays,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return InstallmentPlan.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create installment plan (${response.statusCode})');
  }

  /// GET /api/installment-plans/{id}
  Future<InstallmentPlan> getInstallmentPlan(String id) async {
    final cleanId = _cleanIntId(id);
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/installment-plans/$cleanId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return InstallmentPlan.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load installment plan (${response.statusCode})');
  }

  /// POST /api/installment-plans/installments/{installmentId}/checkout — Stripe Checkout URL for this installment.
  Future<String> startOnlinePayment(String installmentId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/installment-plans/installments/${_cleanIntId(installmentId)}/checkout'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['checkoutUrl']?.toString() ?? '';
    }
    throw Exception(_errorMessage(response, 'Could not start the online payment'));
  }

  /// POST /api/installment-plans/installments/{installmentId}/confirm — verifies the Stripe payment.
  Future<Installment> confirmOnlinePayment(String installmentId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/installment-plans/installments/${_cleanIntId(installmentId)}/confirm'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Installment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_errorMessage(response, 'Could not confirm the payment'));
  }

  /// GET /api/installment-plans/bank-details — the account citizens transfer into.
  Future<Map<String, String>> getBankDetails() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/installment-plans/bank-details'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    throw Exception(_errorMessage(response, 'Could not load the bank details'));
  }

  /// POST /api/installment-plans/installments/{installmentId}/bank-transfer — uploads the transfer receipt.
  Future<Installment> submitBankTransfer(
    String installmentId, {
    required String fileName,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/installment-plans/installments/${_cleanIntId(installmentId)}/bank-transfer'),
    )
      ..headers['Authorization'] = 'Bearer $_token'
      ..files.add(http.MultipartFile.fromBytes('receipt', bytes, filename: fileName));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      return Installment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_errorMessage(response, 'Could not submit the receipt'));
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) return body['message'].toString();
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }

  /// POST /api/installment-plans/{id}/cancel
  Future<InstallmentPlan> cancelInstallmentPlan(String id) async {
    final cleanId = _cleanIntId(id);
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/installment-plans/$cleanId/cancel'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return InstallmentPlan.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to cancel installment plan (${response.statusCode})');
  }
}

