import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/analytics.dart';

class AnalyticsService {
  final String _token;

  AnalyticsService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  /// GET /api/analytics/approval-likelihood/{serviceProcedureId}
  Future<ApprovalLikelihood> getApprovalLikelihood(
      String serviceProcedureId) async {
    final response = await http.get(
      Uri.parse(
          '${AppConfig.baseUrl}/analytics/approval-likelihood/$serviceProcedureId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return ApprovalLikelihood.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(
        'Failed to load approval likelihood (${response.statusCode})');
  }
}
