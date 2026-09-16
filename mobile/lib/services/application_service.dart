import 'dart:convert';
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

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
