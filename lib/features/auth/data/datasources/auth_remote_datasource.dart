import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/auth_model.dart';

class AuthRemoteDatasource {
  final DioClient _client;
  AuthRemoteDatasource(this._client);

  Future<TokenResponseModel> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.login,
        data: {'mobile': mobile, 'password': password},
      );
      return TokenResponseModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> sendOtp({required String mobile, required String purpose}) async {
    try {
      await _client.post(
        ApiEndpoints.otpSend,
        data: {'mobile': mobile, 'purpose': purpose},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<OtpVerifyResponseModel> verifyOtp({
    required String mobile,
    required String otp,
    required String purpose,
  }) async {
    try {
      final res = await _client.post(
        ApiEndpoints.otpVerify,
        data: {'mobile': mobile, 'otp': otp, 'purpose': purpose},
      );
      return OtpVerifyResponseModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> resetPassword({
    required String mobile,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      await _client.post(
        ApiEndpoints.passwordReset,
        data: {
          'mobile': mobile,
          'reset_token': resetToken,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final res = await _client.get(ApiEndpoints.me);
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _client.post(ApiEndpoints.fcmToken, data: {'fcm_token': fcmToken});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
