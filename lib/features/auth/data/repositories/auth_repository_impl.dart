import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../datasources/auth_remote_datasource.dart';

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthRepositoryImpl(AuthRemoteDatasource(client));
});

class AuthRepositoryImpl {
  final AuthRemoteDatasource _remote;
  final _storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this._remote);

  // ── Login ──────────────────────────────────────────────
  Future<void> login({required String mobile, required String password}) async {
    final model = await _remote.login(mobile: mobile, password: password);

    // Save to storage
    await Future.wait([
      _storage.write(key: AppConstants.kAccessToken,  value: model.accessToken),
      _storage.write(key: AppConstants.kRefreshToken, value: model.refreshToken),
      _storage.write(key: AppConstants.kUserId,       value: model.userId.toString()),
      _storage.write(key: AppConstants.kUserName,     value: model.name),
      _storage.write(key: AppConstants.kUserRole,     value: model.role),
      _storage.write(key: AppConstants.kUserMobile,   value: mobile),
    ]);

    // Cache token + profile in memory for immediate use
    TokenStore.set(model.accessToken, model.refreshToken);
    TokenStore.setProfile(
      id:         model.userId,
      userName:   model.name,
      userRole:   model.role,
      userMobile: mobile,
    );
  }

  // ── OTP ────────────────────────────────────────────────
  Future<void> sendOtp({required String mobile, required String purpose}) =>
      _remote.sendOtp(mobile: mobile, purpose: purpose);

  Future<String> verifyOtp({
    required String mobile,
    required String otp,
    required String purpose,
  }) async {
    final result = await _remote.verifyOtp(mobile: mobile, otp: otp, purpose: purpose);
    if (!result.verified || result.resetToken == null) {
      throw Exception('OTP verification failed');
    }
    return result.resetToken!;
  }

  // ── Password reset ─────────────────────────────────────
  Future<void> resetPassword({
    required String mobile,
    required String resetToken,
    required String newPassword,
  }) => _remote.resetPassword(mobile: mobile, resetToken: resetToken, newPassword: newPassword);

  // ── Logout ─────────────────────────────────────────────
  Future<void> logout() async {
    TokenStore.clear();
    await _storage.deleteAll();
  }

  // ── FCM ────────────────────────────────────────────────
  Future<void> updateFcmToken(String token) => _remote.updateFcmToken(token);
}
