import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notice_model.dart';
import '../../data/repositories/notice_repository.dart';

final noticesProvider = FutureProvider<List<NoticeModel>>(
    (ref) => ref.watch(noticeRepositoryProvider).getNotices());

class PublishNoticeState {
  final bool isLoading;
  final bool success;
  final String? error;
  const PublishNoticeState({this.isLoading = false, this.success = false, this.error});
  PublishNoticeState copyWith({bool? isLoading, bool? success, String? error}) =>
      PublishNoticeState(
        isLoading: isLoading ?? this.isLoading,
        success:   success   ?? this.success,
        error:     error,
      );
}

class PublishNoticeNotifier extends StateNotifier<PublishNoticeState> {
  final NoticeRepository _repo;
  PublishNoticeNotifier(this._repo) : super(const PublishNoticeState());

  Future<void> publish({
    required String title,    required String body,
    required String category, required String priority,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.createNotice(
          title: title, body: body, category: category, priority: priority);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const PublishNoticeState();
}

final publishNoticeProvider =
    StateNotifierProvider<PublishNoticeNotifier, PublishNoticeState>(
        (ref) => PublishNoticeNotifier(ref.watch(noticeRepositoryProvider)));
