import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // ── DEPLOYMENT: Update baseUrl to your Railway URL before building ──
  // Example: 'https://3as-backend-production.up.railway.app/api/v1'
  AppConstants._();

  // ── API ────────────────────────────────────────────────
  // Auto-selects correct URL based on platform
  // ── PRODUCTION URL — update before deploying ──────────
  static const String _productionUrl = 'https://3as-backend-production.up.railway.app/api/v1';

  // ── DEVELOPMENT URL ────────────────────────────────────
  static const bool _isProduction = true; // Set to true before building for production

  static String get baseUrl {
    if (_isProduction) {
      return _productionUrl;
    }
    // Development
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1'; // Flutter web (Chrome)
    }
    return 'http://10.0.2.2:8000/api/v1';   // Android emulator
  }

  static const int connectTimeout = 30000; // ms
  static const int receiveTimeout = 30000;  // increased for logo upload

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
