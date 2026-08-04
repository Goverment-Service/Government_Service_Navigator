import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result returned from login/signup calls, mirroring the backend's
/// AuthResponse shape (Success, Token, ErrorMessage, User).
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
  /// Android emulator maps 10.0.2.2 -> your host machine's localhost.
  /// If you're testing on a physical device, replace this with your
  /// computer's actual LAN IP, e.g. http://192.168.1.20:5082
  /// If you're on iOS simulator, localhost works directly instead.
  static const String baseUrl = 'http://10.0.2.2:5275/api';

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
    } catch (e) {
      return AuthResult(
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
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Could not reach the server. Check your connection.',
      );
    }
  }
}