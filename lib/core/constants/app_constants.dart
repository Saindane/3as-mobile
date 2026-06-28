class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator → localhost
  // static const String baseUrl = 'http://localhost:8000/api/v1'; // iOS simulator
  // static const String baseUrl = 'https://api.3ascomplex.in/api/v1'; // Production

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
  static const String appName = '3As Complex';
  static const String appVersion = '1.0.0';
}
