import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../constants/api_endpoints.dart';

// ── Global logout callback — set by AuthNotifier ─────────────────
// Called when 401 received and refresh fails → forces logout
void Function()? onForceLogout;

// ── In-memory store — token + user profile ────────────────────────
class TokenStore {
  static String? _accessToken;
  static String? _refreshToken;

  // User profile cached from login response
  static int?    userId;
  static String? name;
  static String? role;
  static String? mobile;

  static void set(String access, String refresh) {
    _accessToken  = access;
    _refreshToken = refresh;
  }

  static void setProfile({
    required int    id,
    required String userName,
    required String userRole,
    required String userMobile,
  }) {
    userId = id;
    name   = userName;
    role   = userRole;
    mobile = userMobile;
  }

  static String? get accessToken  => _accessToken;
  static String? get refreshToken => _refreshToken;
  static bool    get hasProfile   => userId != null && name != null && role != null;

  static void clear() {
    _accessToken  = null;
    _refreshToken = null;
    userId = null;
    name   = null;
    role   = null;
    mobile = null;
  }
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

class DioClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl:        AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      },
    ));
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);
  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);
  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
  Future<Response> postFormData(String path, FormData data) => _dio.post(path, data: data);
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  _AuthInterceptor(this._storage, this._dio);

  static const _publicPaths = [
    '/auth/login', '/auth/refresh',
    '/auth/otp/send', '/auth/otp/verify', '/auth/password/reset',
  ];

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isPublic = _publicPaths.any((p) => options.path.endsWith(p));
    if (!isPublic) {
      final token = TokenStore.accessToken ??
          await _storage.read(key: AppConstants.kAccessToken);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refresh = TokenStore.refreshToken ??
          await _storage.read(key: AppConstants.kRefreshToken);
      if (refresh != null) {
        try {
          final res = await _dio.post(ApiEndpoints.refresh,
              data: {'refresh_token': refresh});
          final newToken = res.data['access_token'] as String;
          TokenStore.set(newToken, refresh);
          await _storage.write(key: AppConstants.kAccessToken, value: newToken);
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          return handler.resolve(await _dio.fetch(err.requestOptions));
        } catch (_) {
          TokenStore.clear();
          await _storage.deleteAll();
          // Force logout — redirect to login screen
          onForceLogout?.call();
        }
      } else {
        // No refresh token — force logout immediately
        TokenStore.clear();
        await _storage.deleteAll();
        onForceLogout?.call();
      }
    }
    handler.next(err);
  }
}
