import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

// ── Login state ────────────────────────────────────────────────────

class LoginState {
  final bool isLoading;
  final String? error;
  final bool success;

  const LoginState({this.isLoading = false, this.error, this.success = false});

  LoginState copyWith({bool? isLoading, String? error, bool? success}) => LoginState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthRepositoryImpl _repo;
  LoginNotifier(this._repo) : super(const LoginState());

  Future<void> login(String mobile, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.login(mobile: mobile, password: password);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref.watch(authRepositoryProvider));
});

// ── OTP state ─────────────────────────────────────────────────────

class OtpState {
  final bool isSending;
  final bool isVerifying;
  final bool sent;
  final String? resetToken;
  final String? error;

  const OtpState({
    this.isSending = false,
    this.isVerifying = false,
    this.sent = false,
    this.resetToken,
    this.error,
  });

  OtpState copyWith({
    bool? isSending, bool? isVerifying, bool? sent, String? resetToken, String? error,
  }) => OtpState(
        isSending:   isSending   ?? this.isSending,
        isVerifying: isVerifying ?? this.isVerifying,
        sent:        sent        ?? this.sent,
        resetToken:  resetToken  ?? this.resetToken,
        error:       error,
      );
}

class OtpNotifier extends StateNotifier<OtpState> {
  final AuthRepositoryImpl _repo;
  OtpNotifier(this._repo) : super(const OtpState());

  Future<void> sendOtp(String mobile, String purpose) async {
    state = state.copyWith(isSending: true, error: null);
    try {
      await _repo.sendOtp(mobile: mobile, purpose: purpose);
      state = state.copyWith(isSending: false, sent: true);
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  Future<void> verifyOtp(String mobile, String otp, String purpose) async {
    state = state.copyWith(isVerifying: true, error: null);
    try {
      final token = await _repo.verifyOtp(mobile: mobile, otp: otp, purpose: purpose);
      state = state.copyWith(isVerifying: false, resetToken: token);
    } catch (e) {
      state = state.copyWith(isVerifying: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final otpProvider = StateNotifierProvider<OtpNotifier, OtpState>((ref) {
  return OtpNotifier(ref.watch(authRepositoryProvider));
});

// ── Password reset state ───────────────────────────────────────────

class ResetPasswordState {
  final bool isLoading;
  final bool success;
  final String? error;

  const ResetPasswordState({this.isLoading = false, this.success = false, this.error});

  ResetPasswordState copyWith({bool? isLoading, bool? success, String? error}) =>
      ResetPasswordState(
        isLoading: isLoading ?? this.isLoading,
        success:   success   ?? this.success,
        error:     error,
      );
}

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  final AuthRepositoryImpl _repo;
  ResetPasswordNotifier(this._repo) : super(const ResetPasswordState());

  Future<void> reset(String mobile, String resetToken, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.resetPassword(
        mobile: mobile,
        resetToken: resetToken,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final resetPasswordProvider =
    StateNotifierProvider<ResetPasswordNotifier, ResetPasswordState>((ref) {
  return ResetPasswordNotifier(ref.watch(authRepositoryProvider));
});
