import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

// ── Current user profile ──────────────────────────────────────────
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getMe();
});

// ── Dashboard stats (admin/mgmt only — residents get empty stats) ─
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  try {
    final profile = await ref.watch(userProfileProvider.future);
    // Only fetch stats for admin/management — residents get empty stats
    if (profile.role == 'resident') {
      return DashboardStats.empty();
    }
    return ref.watch(dashboardRepositoryProvider).getStats();
  } catch (_) {
    return DashboardStats.empty();
  }
});

// ── Resident's property ───────────────────────────────────────────
final myPropertyProvider = FutureProvider<PropertyInfo?>((ref) async {
  try {
    return await ref.watch(dashboardRepositoryProvider).getMyProperty();
  } catch (_) {
    return null;
  }
});

// ── Users list ────────────────────────────────────────────────────
final usersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.watch(dashboardRepositoryProvider).listUsers();
  } catch (_) {
    return [];
  }
});

// ── Properties list ───────────────────────────────────────────────
final propertiesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.watch(dashboardRepositoryProvider).listProperties();
  } catch (_) {
    return [];
  }
});
