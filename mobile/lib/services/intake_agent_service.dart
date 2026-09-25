import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/intake_plan_model.dart';

class IntakeAgentService {
  // Resolves localhost safely across Web, iOS Simulator, and Android Emulator
  static String get _backendUrl {
    if (kIsWeb) {
      // Safe fallback for Chrome/Web
      return 'http://localhost:5119/api/intakeagent/ask';
    }

    // It is now safe to check the OS because we know we aren't on the web
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5119/api/intakeagent/ask';
    }

    // macOS Desktop or iOS Simulator
    return 'http://localhost:5119/api/intakeagent/ask';
  }

  /// Sends the citizen's plain-language need to the intake agent and returns the matched plan.
  static Future<IntakePlanModel> ask(String text) async {
    final response = await http.post(
      Uri.parse(_backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return IntakePlanModel.fromJson(data);
    }
    throw Exception('Server error: ${response.statusCode}');
  }
}
