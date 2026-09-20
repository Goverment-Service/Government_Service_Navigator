import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/installment_plan.dart';

class InstallmentService {
  final String _token;

  InstallmentService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

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
    throw Exception(
        'Failed to load installment plan (${response.statusCode})');
  }
}
