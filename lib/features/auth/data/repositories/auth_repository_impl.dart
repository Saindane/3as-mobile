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
    await _persistSession(
      accessToken:  model.accessToken,
      refreshToken: model.refreshToken,
      userId:       model.userId,
      name:         model.name,
      role:         model.role,
      mobile:       mobile,
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

  // ── Session ────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.kAccessToken);
    return token != null;
  }

  Future<void> logout() async {
    TokenStore.clear();
    await _storage.deleteAll();
  }

  Future<String?> getRole() => _storage.read(key: AppConstants.kUserRole);
  Future<String?> getName() => _storage.read(key: AppConstants.kUserName);
  Future<String?> getUserId() => _storage.read(key: AppConstants.kUserId);

  // ── FCM ────────────────────────────────────────────────
  Future<void> updateFcmToken(String token) => _remote.updateFcmToken(token);

  // ── Private ────────────────────────────────────────────
  Future<void> _persistSession({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String name,
    required String role,
    required String mobile,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.kAccessToken,  value: accessToken),
      _storage.write(key: AppConstants.kRefreshToken, value: refreshToken),
      _storage.write(key: AppConstants.kUserId,       value: userId.toString()),
      _storage.write(key: AppConstants.kUserName,     value: name),
      _storage.write(key: AppConstants.kUserRole,     value: role),
      _storage.write(key: AppConstants.kUserMobile,   value: mobile),
    ]);
    // Cache token in memory for immediate use — avoids async read race condition
    TokenStore.set(accessToken, refreshToken);
  }
}
