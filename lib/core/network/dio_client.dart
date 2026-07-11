import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../constants/api_endpoints.dart';

// ── In-memory token store — fast, reliable, no async read needed ──
class TokenStore {
  static String? _accessToken;
  static String? _refreshToken;

  static void set(String access, String refresh) {
    _accessToken  = access;
    _refreshToken = refresh;
  }

  static String? get accessToken  => _accessToken;
  static String? get refreshToken => _refreshToken;

  static void clear() {
    _accessToken  = null;
    _refreshToken = null;
  }
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

class DioClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl:        AppConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
        },
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) =>
      _dio.delete(path);

  Future<Response> postFormData(String path, FormData data) =>
      _dio.post(path, data: data);
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  static const _publicPaths = [
    '/auth/login',
    '/auth/refresh',
    '/auth/otp/send',
    '/auth/otp/verify',
    '/auth/password/reset',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = _publicPaths.any((p) => options.path.endsWith(p));
    if (!isPublic) {
      // Use in-memory token first (fast), fall back to storage
      var token = TokenStore.accessToken;
      if (token == null) {
        token = await _storage.read(key: AppConstants.kAccessToken);
        // Cache it for subsequent requests
        final refresh = await _storage.read(key: AppConstants.kRefreshToken);
        if (token != null && refresh != null) {
          TokenStore.set(token, refresh);
        }
      }
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = TokenStore.refreshToken ??
          await _storage.read(key: AppConstants.kRefreshToken);

      if (refreshToken != null) {
        try {
          final res = await _dio.post(
            ApiEndpoints.refresh,
            data: {'refresh_token': refreshToken},
          );
          final newToken  = res.data['access_token'] as String;
          final newRefresh = res.data['refresh_token'] as String? ?? refreshToken;

          // Update both memory cache and storage
          TokenStore.set(newToken, newRefresh);
          await _storage.write(key: AppConstants.kAccessToken,  value: newToken);
          await _storage.write(key: AppConstants.kRefreshToken, value: newRefresh);

          // Retry original request
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retried = await _dio.fetch(err.requestOptions);
          return handler.resolve(retried);
        } catch (_) {
          TokenStore.clear();
          await _storage.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}
