import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ServiceApiClient {
  // Use 10.0.2.2 for Android Emulator, or localhost for iOS simulator/web
  static String get baseUrl => '${AppConfig.baseUrl}/services';

  static Future<List<dynamic>> fetchServices() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load services');
    }
  }

  static Future<Map<String, dynamic>> fetchServiceDetails(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load service details');
    }
  }

  static Future<Map<String, dynamic>> evaluateEligibility(int serviceId, int age, String citizenship) async {
    final response = await http.post(
      Uri.parse('$baseUrl/eligibility-score'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'serviceId': serviceId,
        'citizenProfile': {
          'age': age,
          'citizenship': citizenship,
        }
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to evaluate eligibility');
    }
  }

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Admin-built application form for a service, or null if none is published yet.
  static Future<Map<String, dynamic>?> fetchApplicationForm(int serviceId, String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/applications/form/$serviceId'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 404) return null;
    throw Exception('Failed to load application form');
  }

  /// Submits the citizen's answers (keyed by field label). Returns the created application reference.
  static Future<Map<String, dynamic>> submitApplication({
    required int serviceId,
    required String? templateId,
    required Map<String, String> answers,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/applications/submit'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'serviceProcedureId': serviceId,
        'templateId': templateId,
        'answers': answers,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);

    String message = 'Failed to submit application';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) message = body['message'].toString();
      if (body is Map && body['missingFields'] is List) {
        message = '$message ${(body['missingFields'] as List).join(', ')}';
      }
    } catch (_) {}
    throw Exception(message);
  }
}
