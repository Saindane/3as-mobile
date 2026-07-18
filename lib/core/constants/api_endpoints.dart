class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login         = '/auth/login';
  static const String branding       = '/auth/branding';
  static const String refresh       = '/auth/refresh';
  static const String me            = '/auth/me';
  static const String otpSend       = '/auth/otp/send';
  static const String otpVerify     = '/auth/otp/verify';
  static const String passwordReset = '/auth/password/reset';
  static const String fcmToken      = '/auth/fcm-token';

  // Users
  static const String users         = '/users';

  // Properties
  static const String properties    = '/properties';

  // Bills
  static const String bills         = '/bills';
  static const String myBills        = '/bills/my';
  static const String generateBills = '/bills/generate';

  // Payments
  static const String payments      = '/payments';

  // Complaints
  static const String complaints    = '/complaints';

  // Notices
  static const String notices       = '/notices';

  // Reports
  static const String reports       = '/reports';

  // Settings
  static const String settings      = '/settings';
}
