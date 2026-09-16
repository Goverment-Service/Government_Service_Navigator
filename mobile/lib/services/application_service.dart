import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/application.dart';
import 'session_store.dart';

class ApplicationApiException implements Exception {
  final String message;
  ApplicationApiException(this.message);
  @override
  String toString() => message;
}

class ApplicationService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await SessionStore.getToken();
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  /// The set of ServiceProcedure ids a Verifying Officer has actually built
  /// an active application form (Template) for. Only these are real,
  /// submittable applications - a raw Service Catalog entry with no
  /// template attached isn't something a citizen can fill in and submit yet.
  Future<Set<int>> fetchServiceIdsWithActiveTemplate() async {
    final response = await http.get(Uri.parse('$baseUrl/templates/all'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApplicationApiException('Could not load available applications (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    final ids = <int>{};
    for (final entry in decoded) {
      final map = entry as Map<String, dynamic>;
      final serviceProcedureId = map['serviceProcedureId'];
      if (map['status'] == 'Active' && serviceProcedureId != null) {
        ids.add(serviceProcedureId as int);
      }
    }
    return ids;
  }

  /// Returns null if the service has no application template configured.
  Future<ApplicationTemplate?> fetchTemplateForService(int serviceProcedureId) async {
    final response = await http.get(Uri.parse('$baseUrl/templates/by-service/$serviceProcedureId'));
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApplicationApiException('Could not load the application form (${response.statusCode}).');
    }
    return ApplicationTemplate.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ServiceApplication> submitApplication({
    required int serviceProcedureId,
    required Map<String, String> answers,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/applications'),
      headers: {'Content-Type': 'application/json', ...headers},
      body: jsonEncode({'serviceProcedureId': serviceProcedureId, 'answers': answers}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _tryDecode(response.body);
      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'] as String
          : 'Could not submit your application (${response.statusCode}).';
      throw ApplicationApiException(message);
    }
    return ServiceApplication.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<ServiceApplication>> fetchMyApplications() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/applications/my'), headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApplicationApiException('Could not load your applications (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.map((e) => ServiceApplication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ServiceApplication> fetchApplicationById(int id) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/applications/$id'), headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApplicationApiException('Could not refresh this application (${response.statusCode}).');
    }
    return ServiceApplication.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Only allowed by the backend while the application is Pending or
  /// Rejected - throws ApplicationApiException (with the server's message)
  /// otherwise.
  Future<void> deleteApplication(int id) async {
    final headers = await _authHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/applications/$id'), headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _tryDecode(response.body);
      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'] as String
          : 'Could not delete this application (${response.statusCode}).';
      throw ApplicationApiException(message);
    }
  }

  Future<void> uploadDocument({
    required int applicationId,
    required int? documentRequirementId,
    required String documentName,
    required File file,
  }) async {
    final headers = await _authHeaders();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/applications/$applicationId/documents'))
      ..headers.addAll(headers)
      ..fields['documentName'] = documentName;
    if (documentRequirementId != null) {
      request.fields['documentRequirementId'] = documentRequirementId.toString();
    }
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _tryDecode(response.body);
      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'] as String
          : 'Could not upload "$documentName" (${response.statusCode}).';
      throw ApplicationApiException(message);
    }
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
