import 'dart:convert';
import 'package:http/http.dart' as http;

class ServiceApiClient {
  // Use 10.0.2.2 for Android Emulator, or localhost for iOS simulator/web
  static const String baseUrl = 'http://localhost:5119/api/services';

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
}
