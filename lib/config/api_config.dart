import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend base URL for API calls.
///
/// - Android emulator: 10.0.2.2 → host machine localhost
/// - iOS simulator / desktop: 127.0.0.1
/// - Physical phone on Wi‑Fi: set [hostOverride] to your PC LAN IP (e.g. 192.168.1.42)
class ApiConfig {
  /// Uncomment and set when testing on a real phone (same network as the PC running Node).
  // static const String? hostOverride = '192.168.1.42';
  static const String? hostOverride = null;

  static String get baseUrl {
    if (hostOverride != null && hostOverride!.isNotEmpty) {
      return 'http://$hostOverride:3000';
    }
    if (kIsWeb) return 'http://localhost:3000';
    //change this to pc's local wifi address "192.168.100.7"
    // if (Platform.isAndroid) return 'http://10.0.2.2:3000';
     if (Platform.isAndroid) return 'https://gestionpiecederechange-production.up.railway.app';
    // if (Platform.isAndroid) return 'http://192.168.100.7:3000';
    return 'http://127.0.0.1:3000';
  }

  static String url(String path) {
    if (!path.startsWith('/')) path = '/$path';
    return '$baseUrl$path';
  }

  static String uploadUrl(String filename) => url('/uploads/$filename');
}
