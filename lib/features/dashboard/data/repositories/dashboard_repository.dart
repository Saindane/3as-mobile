import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(DashboardRemoteDatasource(ref.watch(dioClientProvider)));
});

class DashboardRepository {
  final DashboardRemoteDatasource _remote;
  DashboardRepository(this._remote);

  Future<DashboardStats> getStats()         => _remote.getDashboardStats();
  Future<UserProfile>    getMe()            => _remote.getMe();
  Future<PropertyInfo?>  getMyProperty()    => _remote.getMyProperty();
  Future<List<Map<String,dynamic>>> listUsers({String? role, bool? isActive}) =>
      _remote.listUsers(role: role, isActive: isActive);
  Future<List<Map<String,dynamic>>> listProperties() => _remote.listProperties();
}
