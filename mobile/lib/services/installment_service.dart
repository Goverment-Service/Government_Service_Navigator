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

  /// PUT /api/payments/{id}/installment-plan
  Future<InstallmentPlan> createInstallmentPlan(
    String paymentId, {
    required int numberOfInstallments,
    int intervalDays = 30,
  }) async {
    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/payments/$paymentId/installment-plan'),
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
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/installment-plans/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return InstallmentPlan.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load installment plan (${response.statusCode})');
  }

  /// POST /api/installment-plans/installments/{installmentId}/pay
  Future<Installment> payInstallment(String installmentId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/installment-plans/installments/$installmentId/pay'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Installment.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to pay installment (${response.statusCode})');
  }

  /// POST /api/installment-plans/{id}/cancel
  Future<InstallmentPlan> cancelInstallmentPlan(String id) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/installment-plans/$id/cancel'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return InstallmentPlan.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to cancel installment plan (${response.statusCode})');
  }
}

