import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Single source of truth for the backend base URL.
/// Automatically detects platform:
///   • Web (Chrome)      → 'http://localhost:5119/api'
///   • Android emulator  → 'http://10.0.2.2:5119/api'
///   • Windows / iOS     → 'http://localhost:5119/api'
class AppConfig {
  AppConfig._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5119/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5119/api';
      }
    } catch (_) {}
    return 'http://localhost:5119/api';
  }
}
