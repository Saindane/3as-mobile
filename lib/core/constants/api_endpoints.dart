class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login         = '/auth/login';
  static const String refresh       = '/auth/refresh';
  static const String me            = '/auth/me';
  static const String otpSend       = '/auth/otp/send';
  static const String otpVerify     = '/auth/otp/verify';
  static const String passwordReset = '/auth/password/reset';
  static const String fcmToken      = '/auth/fcm-token';

  // Users (Feature 2)
  static const String users         = '/users';

  // Properties (Feature 2)
  static const String properties    = '/properties';

  // Bills (Feature 3)
  static const String bills         = '/bills';
  static const String generateBills = '/bills/generate';

  // Payments (Feature 4)
  static const String payments      = '/payments';

  // Complaints (Feature 5)
  static const String complaints    = '/complaints';

  // Notices (Feature 6)
  static const String notices       = '/notices';

  // Reports (Feature 7)
  static const String reports       = '/reports';
}
