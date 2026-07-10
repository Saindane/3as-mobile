import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../datasources/notice_datasource.dart';
import '../models/notice_model.dart';

final noticeRepositoryProvider = Provider<NoticeRepository>(
    (ref) => NoticeRepository(NoticeDatasource(ref.watch(dioClientProvider))));

class NoticeRepository {
  final NoticeDatasource _ds;
  NoticeRepository(this._ds);

  Future<List<NoticeModel>> getNotices({bool activeOnly = true}) =>
      _ds.getNotices(activeOnly: activeOnly);

  Future<NoticeModel> createNotice({
    required String title,   required String body,
    required String category, required String priority,
  }) => _ds.createNotice(title: title, body: body,
        category: category, priority: priority);

  Future<void> deleteNotice(int id) => _ds.deleteNotice(id);
}
