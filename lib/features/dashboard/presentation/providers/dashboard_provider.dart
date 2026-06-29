import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

// ── Current user profile ──────────────────────────────────────────
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getMe();
});

// ── Dashboard stats (admin / mgmt) ────────────────────────────────
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getStats();
});

// ── Resident's property ───────────────────────────────────────────
final myPropertyProvider = FutureProvider<PropertyInfo?>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getMyProperty();
});

// ── Users list ────────────────────────────────────────────────────
final usersListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).listUsers();
});

// ── Properties list ───────────────────────────────────────────────
final propertiesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).listProperties();
});
