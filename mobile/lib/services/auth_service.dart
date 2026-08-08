import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String? token;
  final String? errorMessage;
  final Map<String, dynamic>? user;

  const AuthResult({
    required this.success,
    this.token,
    this.errorMessage,
    this.user,
  });
}

class AuthService {
  // IMPORTANT: If you are running the app on a PHYSICAL device (not an emulator),
  // you must change '10.0.2.2' to your computer's local Wi-Fi IPv4 address (e.g., '192.168.1.50').
  static const String baseUrl = 'http://10.0.2.2:5119/api';

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return AuthResult(
        success: data['success'] == true,
        token: data['token'],
        errorMessage: data['errorMessage'],
        user: data['user'],
      );
    } catch (e, stackTrace) {
      // Print the exact network error to the Flutter console for debugging
      print('--- LOGIN NETWORK ERROR ---');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      print('---------------------------');

      return const AuthResult(
        success: false,
        errorMessage: 'Could not reach the server. Check your connection.',
      );
    }
  }

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String nicNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'nicNumber': nicNumber,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return AuthResult(
        success: data['success'] == true,
        token: data['token'],
        errorMessage: data['errorMessage'],
        user: data['user'],
      );
    } catch (e, stackTrace) {
      // Print the exact network error to the Flutter console for debugging
      print('--- SIGNUP NETWORK ERROR ---');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      print('----------------------------');

      return const AuthResult(
        success: false,
        errorMessage: 'Could not reach the server. Check your connection.',
      );
    }
  }
}