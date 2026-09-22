import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/refund.dart';

class RefundService {
  final String _token;

  RefundService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  /// POST /api/refunds
  Future<RefundRequest> submitRefund({
    required String paymentId,
    required double refundAmount,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/refunds'),
      headers: _headers,
      body: jsonEncode({
        'paymentId': int.tryParse(paymentId) ?? paymentId,
        'refundAmount': refundAmount,
        'reason': reason,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return RefundRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Submit refund failed (${response.statusCode})');
  }

  /// GET /api/refunds
  Future<List<RefundRequest>> getAllRefunds({String? status}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/refunds').replace(
      queryParameters: status != null && status.isNotEmpty
          ? {'status': status}
          : null,
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => RefundRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load all refunds (${response.statusCode})');
  }

  /// GET /api/refunds/{id}
  Future<RefundRequest> getRefund(String id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/refunds/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return RefundRequest.fromJson(
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
      final statusVal = data['status'] ?? data['Status'];
      if (statusVal is int) {
        return RefundStatus.fromInt(statusVal);
      } else if (statusVal is num) {
        return RefundStatus.fromInt(statusVal.toInt());
      }
      return RefundStatus.pending;
    }
    throw Exception('Failed to load refund status (${response.statusCode})');
  }

  /// GET /api/refunds/mine
  Future<List<RefundRequest>> myRefunds() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/refunds/mine'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => RefundRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load refunds (${response.statusCode})');
  }

  /// POST /api/refunds/{id}/approve
  Future<RefundRequest> approveRefund(String id, {String? note}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/refunds/$id/approve'),
      headers: _headers,
      body: jsonEncode({'note': note ?? ''}),
    );
    if (response.statusCode == 200) {
      return RefundRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to approve refund (${response.statusCode})');
  }

  /// POST /api/refunds/{id}/reject
  Future<RefundRequest> rejectRefund(String id, {String? note}) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/refunds/$id/reject'),
      headers: _headers,
      body: jsonEncode({'note': note ?? ''}),
    );
    if (response.statusCode == 200) {
      return RefundRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to reject refund (${response.statusCode})');
  }

  /// POST /api/refunds/{id}/process
  Future<RefundRequest> processRefund(
    String id, {
    required String transactionRef,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/refunds/$id/process'),
      headers: _headers,
      body: jsonEncode({'transactionRef': transactionRef}),
    );
    if (response.statusCode == 200) {
      return RefundRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to process refund (${response.statusCode})');
  }

  /// POST /api/refunds/{id}/complete
  Future<RefundRequest> completeRefund(String id) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/refunds/$id/complete'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return RefundRequest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to complete refund (${response.statusCode})');
  }
}

