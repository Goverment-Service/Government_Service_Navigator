import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the signed-in citizen's JWT and profile across app restarts.
/// Login and sign-up write here on success; screens that call authenticated
/// endpoints (payments, refunds) read the token from here.
class SessionStore {
  static const _tokenKey = 'citizenToken';
  static const _userKey = 'citizenUser';

  static Future<void> save(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_userKey);
    if (stored == null) return null;
    return jsonDecode(stored) as Map<String, dynamic>;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
