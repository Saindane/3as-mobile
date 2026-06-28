import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../constants/api_endpoints.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

class DioClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      PrettyDioLogger(requestHeader: false, requestBody: true, responseBody: true, error: true),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postFormData(String path, FormData data) =>
      _dio.post(path, data: data);
}

// ── Auth interceptor: attach token + handle 401 refresh ──────────
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for public endpoints
    final skipAuth = [
      ApiEndpoints.login,
      ApiEndpoints.refresh,
      ApiEndpoints.otpSend,
      ApiEndpoints.otpVerify,
      ApiEndpoints.passwordReset,
    ];
    if (!skipAuth.any((e) => options.path.contains(e))) {
      final token = await _storage.read(key: AppConstants.kAccessToken);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refreshing token
      final refreshToken = await _storage.read(key: AppConstants.kRefreshToken);
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            ApiEndpoints.refresh,
            data: {'refresh_token': refreshToken},
          );
          final newToken = response.data['access_token'];
          await _storage.write(key: AppConstants.kAccessToken, value: newToken);

          // Retry original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retried = await _dio.fetch(err.requestOptions);
          return handler.resolve(retried);
        } catch (_) {
          // Refresh failed — clear tokens (force re-login)
          await _storage.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}
