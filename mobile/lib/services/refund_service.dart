import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/refund.dart';

class RefundService {
  final String _token;

  RefundService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  /// POST /api/refunds
  Future<Refund> submitRefund({
    required String paymentId,
    required double refundAmount,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/refunds'),
      headers: _headers,
      body: jsonEncode({
        'paymentId': paymentId,
        'refundAmount': refundAmount,
        'reason': reason,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Refund.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Submit refund failed (${response.statusCode})');
  }

  /// GET /api/refunds/{id}
  Future<Refund> getRefund(String id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/refunds/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Refund.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load refund (${response.statusCode})');
  }

  /// GET /api/refunds/{id}/status → { id, status }
  Future<RefundStatus> getRefundStatus(String id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/refunds/$id/status'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RefundStatus.fromInt((data['status'] as num?)?.toInt() ?? 0);
    }
    throw Exception('Failed to load refund status (${response.statusCode})');
  }

  /// GET /api/refunds/mine
  Future<List<Refund>> myRefunds() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/refunds/mine'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => Refund.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load refunds (${response.statusCode})');
  }
}
