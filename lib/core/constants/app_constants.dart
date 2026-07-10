import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────
  // Auto-selects correct URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1'; // Flutter web (Chrome)
    }
    return 'http://10.0.2.2:8000/api/v1';   // Android emulator
    // For iOS simulator use: http://localhost:8000/api/v1
    // For physical device use your machine's local IP e.g.: http://192.168.1.5:8000/api/v1
  }

  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 15000;

  // ── Storage keys ───────────────────────────────────────
  static const String kAccessToken  = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserId       = 'user_id';
  static const String kUserName     = 'user_name';
  static const String kUserRole     = 'user_role';
  static const String kUserMobile   = 'user_mobile';

  // ── App ────────────────────────────────────────────────
  static const String appName    = '3As Complex';
  static const String appVersion = '1.0.0';
}
