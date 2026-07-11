import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_router.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  ref.watch(sessionKeyProvider); // re-runs on login AND logout
  return ref.read(dashboardRepositoryProvider).getMe();
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  ref.watch(sessionKeyProvider);
  try {
    final profile = await ref.watch(userProfileProvider.future);
    if (profile.role == 'RESIDENT') return DashboardStats.empty();
    return ref.read(dashboardRepositoryProvider).getStats();
  } catch (_) {
    return DashboardStats.empty();
  }
});

final myPropertyProvider = FutureProvider<PropertyInfo?>((ref) async {
  ref.watch(sessionKeyProvider);
  try {
    return await ref.read(dashboardRepositoryProvider).getMyProperty();
  } catch (_) {
    return null;
  }
});

final usersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(sessionKeyProvider);
  try {
    return await ref.read(dashboardRepositoryProvider).listUsers();
  } catch (_) {
    return [];
  }
});

final propertiesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(sessionKeyProvider);
  try {
    return await ref.read(dashboardRepositoryProvider).listProperties();
  } catch (_) {
    return [];
  }
});
