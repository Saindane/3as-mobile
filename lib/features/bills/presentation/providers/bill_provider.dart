import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bill_model.dart';
import '../../data/repositories/bill_repository.dart';

// ── Resident: own bills ───────────────────────────────────────────
final myBillsProvider = FutureProvider<List<BillModel>>((ref) =>
    ref.watch(billRepositoryProvider).getMyBills());

// ── Admin/Mgmt: all bills with optional filters ───────────────────
final allBillsProvider = FutureProvider.family<List<BillModel>,
    ({int? month, int? year, String? status})>((ref, params) =>
    ref.watch(billRepositoryProvider).getAllBills(
      month: params.month, year: params.year, status: params.status));

// ── Single bill by ID ────────────────────────────────────────────
final billByIdProvider = FutureProvider.family<BillModel, int>((ref, billId) =>
    ref.watch(billRepositoryProvider).getBill(billId));

// ── Collection summary ────────────────────────────────────────────
final collectionSummaryProvider =
    FutureProvider.family<CollectionSummary, ({int month, int year})>(
        (ref, p) => ref.watch(billRepositoryProvider)
            .getCollectionSummary(p.month, p.year));

// ── Penalty previews ──────────────────────────────────────────────
final penaltyPreviewProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) =>
        ref.watch(billRepositoryProvider).getPenaltyPreviews());

// ── Generate bills state ──────────────────────────────────────────
class GenerateBillsState {
  final bool isLoading;
  final Map<String, dynamic>? result;
  final String? error;
  const GenerateBillsState({this.isLoading = false, this.result, this.error});
  GenerateBillsState copyWith({bool? isLoading, Map<String,dynamic>? result, String? error}) =>
      GenerateBillsState(
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
        error: error,
      );
}

class GenerateBillsNotifier extends StateNotifier<GenerateBillsState> {
  final BillRepository _repo;
  GenerateBillsNotifier(this._repo) : super(const GenerateBillsState());

  Future<void> generate({
    required int month, required int year,
    required double maintenance, required String dueDate,
    bool includepenalty = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.generateBills(
        month: month, year: year, maintenance: maintenance,
        dueDate: dueDate, includepenalty: includepenalty,
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const GenerateBillsState();
}

final generateBillsProvider =
    StateNotifierProvider<GenerateBillsNotifier, GenerateBillsState>((ref) =>
        GenerateBillsNotifier(ref.watch(billRepositoryProvider)));
