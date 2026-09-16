import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend base URL, resolved per-platform.
///
/// The backend listens on localhost:5119 on the development machine, but
/// "localhost" means something different depending on where the app runs:
///  - Android emulator: its own loopback, not the host machine. Android
///    emulators expose the host at the special alias 10.0.2.2 instead.
///  - iOS simulator / desktop / web: shares the host's network, so
///    "localhost" reaches the backend directly.
///  - A physical device (phone/tablet): neither works, since the device is
///    on its own network. Point apiHost at your machine's LAN IP (e.g.
///    192.168.x.x) and make sure the backend and device are on the same
///    network with the backend's port reachable.
class ApiConfig {
  static const String _host = String.fromEnvironment('API_HOST', defaultValue: '');

  static String get apiHost {
    if (_host.isNotEmpty) return _host;
    if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get baseUrl => 'http://$apiHost:5119/api';
}
