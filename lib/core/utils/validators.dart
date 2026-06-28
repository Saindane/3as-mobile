class Validators {
  Validators._();

  static String? mobile(String? value) {
    if (value == null || value.trim().isEmpty) return 'Mobile number is required';
    final digits = value.replaceAll(' ', '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (!RegExp(r'^\d{4,6}$').hasMatch(value)) return 'Enter a valid OTP';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }
}
