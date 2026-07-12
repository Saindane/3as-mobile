import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/notice_model.dart';

class NoticeDatasource {
  final DioClient _client;
  NoticeDatasource(this._client);

  Future<List<NoticeModel>> getNotices({bool activeOnly = true}) async {
    try {
      final res = await _client.get(ApiEndpoints.notices,
          queryParameters: {'active_only': activeOnly});

      // ignore: avoid_print
      print('[Notices] statusCode: ${res.statusCode}');
      // ignore: avoid_print
      print('[Notices] data type: ${res.data.runtimeType}');
      // ignore: avoid_print
      print('[Notices] data: ${res.data}');

      if (res.data == null) return [];

      final data = res.data as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];

      // ignore: avoid_print
      print('[Notices] items count: ${items.length}');

      final result = <NoticeModel>[];
      for (int i = 0; i < items.length; i++) {
        try {
          final model = NoticeModel.fromJson(items[i] as Map<String, dynamic>);
          result.add(model);
          // ignore: avoid_print
          print('[Notices] parsed[$i]: ${model.title}');
        } catch (e) {
          // ignore: avoid_print
          print('[Notices] PARSE ERROR[$i]: $e');
          // ignore: avoid_print
          print('[Notices] raw[$i]: ${items[i]}');
        }
      }
      return result;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[Notices] DioException: $e');
      throw ApiException.fromDioException(e);
    } catch (e) {
      // ignore: avoid_print
      print('[Notices] Exception: $e');
      throw ApiException(message: e.toString());
    }
  }

  Future<NoticeModel> createNotice({
    required String title,
    required String body,
    required String category,
    required String priority,
  }) async {
    try {
      final res = await _client.post(ApiEndpoints.notices, data: {
        'title':    title,
        'body':     body,
        'category': category,
        'priority': priority,
      });
      return NoticeModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteNotice(int noticeId) async {
    try {
      await _client.delete('${ApiEndpoints.notices}/$noticeId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
