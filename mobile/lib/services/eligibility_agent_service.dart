import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/eligibility_agent_model.dart';

class EligibilityAgentService {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5119/api/eligibilityagent';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5119/api/eligibilityagent';
    }
    return 'http://localhost:5119/api/eligibilityagent';
  }

  static Future<EligibilityAgentResponse> evaluateEligibility({
    required String serviceName,
    int? serviceId,
    int age = 25,
    String citizenshipStatus = 'Sri Lankan',
    double annualIncome = 0,
    String employmentStatus = 'Employed',
    List<String>? providedDocuments,
    String? planSummary,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/evaluate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'serviceName': serviceName,
        'serviceId': serviceId,
        'age': age,
        'citizenshipStatus': citizenshipStatus,
        'annualIncome': annualIncome,
        'employmentStatus': employmentStatus,
        'providedDocuments': providedDocuments ?? [],
        'planSummary': planSummary,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return EligibilityAgentResponse.fromJson(data);
    } else {
      throw Exception('Failed to evaluate eligibility: ${response.statusCode}');
    }
  }
}
