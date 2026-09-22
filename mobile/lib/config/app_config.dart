/// Single source of truth for the backend base URL.
///
/// Switch the active line to match your run target:
///   • Android emulator  → 'http://10.0.2.2:5119/api'
///   • iOS simulator     → 'http://localhost:5119/api'
///   • Real device (LAN) → 'http://192.168.x.x:5119/api'
class AppConfig {
  AppConfig._();

  static const String baseUrl = 'http://10.0.2.2:5119/api';
}
