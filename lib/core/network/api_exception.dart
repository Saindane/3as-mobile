import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
            message: 'Connection timed out. Make sure the backend is running.');

      case DioExceptionType.connectionError:
        return const ApiException(
            message: 'Cannot reach server. Check that backend is running on localhost:8000.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String msg;
        if (data is Map) {
          final detail = data['detail'];
          if (detail is String) {
            msg = detail;
          } else if (detail is List && detail.isNotEmpty) {
            msg = detail.first['msg']?.toString() ?? 'Request failed';
          } else {
            msg = 'Error $statusCode';
          }
        } else {
          msg = 'Error $statusCode';
        }
        return ApiException(message: msg, statusCode: statusCode);

      case DioExceptionType.cancel:
        return const ApiException(message: 'Request cancelled.');

      case DioExceptionType.badCertificate:
        return const ApiException(message: 'SSL certificate error.');

      default:
        // unknown — usually CORS error or network issue in Chrome
        final msg = e.message ?? 'Unknown error';
        if (msg.toLowerCase().contains('cors') ||
            msg.toLowerCase().contains('xmlhttprequest')) {
          return const ApiException(
              message: 'CORS error — check that ALLOWED_ORIGINS=* is set in backend .env');
        }
        return ApiException(message: 'Network error: $msg');
    }
  }

  @override
  String toString() => message;
}
