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
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<UserProfile> getMe() async {
    try {
      // Use /auth/me — simpler response, no created_at issues
      final res = await _client.get(ApiEndpoints.me);
      final data = res.data as Map<String, dynamic>;
      return UserProfile(
        userId:   data['user_id']   as int,
        name:     data['name']      as String,
        mobile:   data['mobile']    as String,
        email:    data['email']     as String?,
        role:     data['role']      as String,
        isActive: data['is_active'] as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<PropertyInfo?> getMyProperty() async {
    try {
      final res = await _client.get('${ApiEndpoints.properties}/my');
      if (res.data == null) return null;
      return PropertyInfo.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
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
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> listProperties() async {
    try {
      final res = await _client.get(ApiEndpoints.properties);
      return List<Map<String, dynamic>>.from(res.data['items'] as List);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}
