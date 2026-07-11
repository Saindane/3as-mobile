class TokenResponseModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int    userId;
  final String name;
  final String role;
  final String mobile;  // optional from backend — defaults to empty

  const TokenResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.userId,
    required this.name,
    required this.role,
    this.mobile = '',
  });

  factory TokenResponseModel.fromJson(Map<String, dynamic> json) => TokenResponseModel(
        accessToken:  json['access_token']  as String,
        refreshToken: json['refresh_token'] as String,
        tokenType:    json['token_type']    as String? ?? 'bearer',
        mobile:       json['mobile']        as String? ?? '',
        userId:       json['user_id'] as int,
        name:         json['name'] as String,
        role:         json['role'] as String,
      );
}

class OtpVerifyResponseModel {
  final bool verified;
  final String? resetToken;

  const OtpVerifyResponseModel({required this.verified, this.resetToken});

  factory OtpVerifyResponseModel.fromJson(Map<String, dynamic> json) => OtpVerifyResponseModel(
        verified:   json['verified'] as bool,
        resetToken: json['reset_token'] as String?,
      );
}

class UserModel {
  final int userId;
  final String name;
  final String mobile;
  final String? email;
  final String role;
  final bool isActive;

  const UserModel({
    required this.userId,
    required this.name,
    required this.mobile,
    this.email,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId:   json['user_id'] as int,
        name:     json['name'] as String,
        mobile:   json['mobile'] as String,
        email:    json['email'] as String?,
        role:     json['role'] as String,
        isActive: json['is_active'] as bool,
      );
}
