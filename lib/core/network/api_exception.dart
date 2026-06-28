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
        return const ApiException(message: 'Connection timed out. Check your network.');
      case DioExceptionType.connectionError:
        return const ApiException(message: 'Cannot reach server. Check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final detail = e.response?.data?['detail'];
        final msg = detail is String
            ? detail
            : detail is List
                ? (detail.first['msg'] ?? 'Request failed')
                : 'Request failed';
        return ApiException(message: msg, statusCode: statusCode);
      default:
        return ApiException(message: e.message ?? 'Something went wrong');
    }
  }

  @override
  String toString() => message;
}
