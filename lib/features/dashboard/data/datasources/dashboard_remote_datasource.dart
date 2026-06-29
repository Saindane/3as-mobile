import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/dashboard_model.dart';

class DashboardRemoteDatasource {
  final DioClient _client;
  DashboardRemoteDatasource(this._client);

  Future<DashboardStats> getDashboardStats() async {
    try {
      final res = await _client.get('${ApiEndpoints.properties}/dashboard');
      return DashboardStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserProfile> getMe() async {
    try {
      final res = await _client.get('${ApiEndpoints.users}/me');
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PropertyInfo?> getMyProperty() async {
    try {
      final res = await _client.get('${ApiEndpoints.properties}/my');
      if (res.data == null) return null;
      return PropertyInfo.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> listUsers({String? role, bool? isActive}) async {
    try {
      final res = await _client.get(ApiEndpoints.users, queryParameters: {
        if (role != null)     'role':      role,
        if (isActive != null) 'is_active': isActive,
      });
      return List<Map<String, dynamic>>.from(res.data['items'] as List);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> listProperties() async {
    try {
      final res = await _client.get(ApiEndpoints.properties);
      return List<Map<String, dynamic>>.from(res.data['items'] as List);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
