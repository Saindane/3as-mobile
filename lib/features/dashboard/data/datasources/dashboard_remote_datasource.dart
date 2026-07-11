import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/dashboard_model.dart';

class DashboardRemoteDatasource {
  final DioClient _client;
  final _storage = const FlutterSecureStorage();

  DashboardRemoteDatasource(this._client);

  /// Build UserProfile — reads from TokenStore (set during login)
  /// Retries up to 3 times with 300ms delay if profile not ready yet
  Future<UserProfile> getMe() async {
    // Try TokenStore first (set synchronously during login)
    for (int attempt = 0; attempt < 3; attempt++) {
      if (TokenStore.hasProfile) {
        return UserProfile(
          userId:   TokenStore.userId!,
          name:     TokenStore.name!,
          mobile:   TokenStore.mobile ?? '',
          email:    null,
          role:     TokenStore.role!,
          isActive: true,
        );
      }
      // Wait a bit and retry — login storage write may still be in progress
      if (attempt < 2) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // Fallback: read from storage (app restart case)
    try {
      final userId = await _storage.read(key: AppConstants.kUserId);
      final name   = await _storage.read(key: AppConstants.kUserName);
      final role   = await _storage.read(key: AppConstants.kUserRole);
      final mobile = await _storage.read(key: AppConstants.kUserMobile);

      if (userId == null || name == null || role == null) {
        throw ApiException(message: 'Session expired. Please login again.');
      }

      // Populate TokenStore for future calls
      TokenStore.setProfile(
        id:         int.parse(userId),
        userName:   name,
        userRole:   role,
        userMobile: mobile ?? '',
      );

      return UserProfile(
        userId:   int.parse(userId),
        name:     name,
        mobile:   mobile ?? '',
        email:    null,
        role:     role,
        isActive: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

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

  Future<PropertyInfo?> getMyProperty() async {
    try {
      final res = await _client.get('${ApiEndpoints.properties}/my');
      if (res.data == null) return null;
      return PropertyInfo.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (_) {
      return null;
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
