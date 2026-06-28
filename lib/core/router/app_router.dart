import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/new_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.kAccessToken);
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/otp') ||
          state.matchedLocation.startsWith('/new-password');

      if (token != null && isAuthRoute) return '/dashboard';
      if (token == null && !isAuthRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login',        builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return OtpScreen(mobile: extra['mobile'] ?? '', purpose: extra['purpose'] ?? 'password_reset');
        },
      ),
      GoRoute(
        path: '/new-password',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return NewPasswordScreen(mobile: extra['mobile'] ?? '', resetToken: extra['reset_token'] ?? '');
        },
      ),
      GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
});
