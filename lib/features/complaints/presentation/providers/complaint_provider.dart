import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/complaint_model.dart';
import '../../data/repositories/complaint_repository.dart';

final complaintsProvider = FutureProvider<List<ComplaintModel>>(
    (ref) => ref.watch(complaintRepositoryProvider).getComplaints());

final openComplaintsProvider = FutureProvider<List<ComplaintModel>>(
    (ref) => ref.watch(complaintRepositoryProvider).getComplaints(status: 'new'));

// ── Raise complaint state ─────────────────────────────────────────
class RaiseComplaintState {
  final bool isLoading;
  final bool success;
  final String? error;
  const RaiseComplaintState({this.isLoading = false, this.success = false, this.error});
  RaiseComplaintState copyWith({bool? isLoading, bool? success, String? error}) =>
      RaiseComplaintState(
        isLoading: isLoading ?? this.isLoading,
        success:   success   ?? this.success,
        error:     error,
      );
}

class RaiseComplaintNotifier extends StateNotifier<RaiseComplaintState> {
  final ComplaintRepository _repo;
  RaiseComplaintNotifier(this._repo) : super(const RaiseComplaintState());

  Future<void> raise_({
    required String title,    required String category,
    required String priority, String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.raise_(title: title, category: category,
          priority: priority, description: description);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const RaiseComplaintState();
}

final raiseComplaintProvider =
    StateNotifierProvider<RaiseComplaintNotifier, RaiseComplaintState>(
        (ref) => RaiseComplaintNotifier(ref.watch(complaintRepositoryProvider)));
