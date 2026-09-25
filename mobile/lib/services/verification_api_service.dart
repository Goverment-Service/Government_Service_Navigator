import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/verification_models.dart';

class VerificationApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5119/api/verification';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5119/api/verification';
      }
    } catch (_) {}
    return 'http://localhost:5119/api/verification';
  }

  /// Fetches citizen applications from the backend verification tasks
  static Future<List<ApplicationItemModel>> fetchApplications({String? token}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final pendingResponse = await http
          .get(Uri.parse('$baseUrl/tasks/pending'), headers: headers)
          .timeout(const Duration(seconds: 4));

      final verifiedResponse = await http
          .get(Uri.parse('$baseUrl/tasks/verified'), headers: headers)
          .timeout(const Duration(seconds: 4));

      List<dynamic> backendTasks = [];

      if (pendingResponse.statusCode == 200) {
        final data = jsonDecode(pendingResponse.body);
        if (data is List) backendTasks.addAll(data);
      }
      if (verifiedResponse.statusCode == 200) {
        final data = jsonDecode(verifiedResponse.body);
        if (data is List) backendTasks.addAll(data);
      }

      return backendTasks
          .whereType<Map<String, dynamic>>()
          .map(_applicationFromTask)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('VerificationApiService: Failed to load applications: $e');
      }
    }

    return [];
  }

  static ApplicationItemModel _applicationFromTask(Map<String, dynamic> json) {
    final task = VerificationTaskModel.fromJson(json);
    return ApplicationItemModel(
      applicationId: task.applicationId,
      referenceNumber: json['referenceNumber']?.toString() ?? 'APP-${task.applicationId}',
      serviceName: json['serviceName']?.toString() ?? 'Application #${task.applicationId}',
      category: json['category']?.toString() ?? '',
      submittedDate: task.createdDate,
      status: task.status,
      applicantName: json['applicantName']?.toString(),
      verificationTask: task,
    );
  }

  /// Fetches audit logs for a specific application from the backend
  static Future<List<AuditLogModel>> fetchAuditLogs(int applicationId, {String? token}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(Uri.parse('$baseUrl/audit-logs?applicationId=$applicationId'), headers: headers)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AuditLogModel.fromJson(json)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Citizen resubmission for an application marked "Revised".
  /// The backend does not expose a resubmission endpoint yet, so this reports failure.
  static Future<bool> submitRevision({
    required int applicationId,
    required String notes,
    required String documentAttachmentName,
  }) async {
    return false;
  }
}
