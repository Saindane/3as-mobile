import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/new_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../constants/app_constants.dart';
import '../network/dio_client.dart';

// ── Session key — increment to bust ALL provider caches ──────────
final sessionKeyProvider = StateProvider<int>((ref) => 0);

class AuthNotifier extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  final Ref _ref;
  bool _isLoggedIn = false;

  AuthNotifier(this._storage, this._ref) {
    _init();
  }

  bool get isLoggedIn => _isLoggedIn;

  Future<void> _init() async {
    // Set global logout callback so DioClient can force logout on 401
    onForceLogout = () => logout();

    final token   = await _storage.read(key: AppConstants.kAccessToken);
    final refresh = await _storage.read(key: AppConstants.kRefreshToken);
    final userId  = await _storage.read(key: AppConstants.kUserId);
    final name    = await _storage.read(key: AppConstants.kUserName);
    final role    = await _storage.read(key: AppConstants.kUserRole);
    final mobile  = await _storage.read(key: AppConstants.kUserMobile);

    if (token != null && userId != null && name != null && role != null) {
      // Restore TokenStore from storage on app restart
      if (refresh != null) TokenStore.set(token, refresh);
      TokenStore.setProfile(
        id:         int.parse(userId),
        userName:   name,
        userRole:   role,
        userMobile: mobile ?? '',
      );
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
    }
    notifyListeners();
  }

  /// Called after successful login
  /// TokenStore.setProfile() is already called inside auth_repository.login()
  /// so profile is guaranteed to be in memory before this runs
  Future<void> setLoggedIn(bool value) async {
    if (value) {
      // Verify TokenStore has profile before navigating
      // If not ready (shouldn't happen), wait up to 500ms
      int attempts = 0;
      while (!TokenStore.hasProfile && attempts < 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      // Bust all provider caches so they reload for the new user
      _ref.read(sessionKeyProvider.notifier).state++;
    }
    _isLoggedIn = value;
    notifyListeners();
  }

  /// Called on logout
  Future<void> logout() async {
    // Clear memory FIRST before anything else
    TokenStore.clear();
    // Then clear storage
    await _storage.deleteAll();
    // Bust all provider caches
    _ref.read(sessionKeyProvider.notifier).state++;
    _isLoggedIn = false;
    notifyListeners();
  }
}

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(const FlutterSecureStorage(), ref);
});

// ── Router ────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn  = authNotifier.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                          state.matchedLocation.startsWith('/otp') ||
                          state.matchedLocation.startsWith('/new-password');
      if (isLoggedIn && isAuthRoute)   return '/dashboard';
      if (!isLoggedIn && !isAuthRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return OtpScreen(
            mobile:  extra['mobile']  ?? '',
            purpose: extra['purpose'] ?? 'password_reset',
          );
        },
      ),
      GoRoute(
        path: '/new-password',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return NewPasswordScreen(
            mobile:     extra['mobile']      ?? '',
            resetToken: extra['reset_token'] ?? '',
          );
        },
      ),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
});
