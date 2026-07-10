import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';

final myPaymentsProvider = FutureProvider<List<PaymentModel>>(
    (ref) => ref.watch(paymentRepositoryProvider).getMyPayments());

final pendingPaymentsProvider = FutureProvider<List<PaymentModel>>(
    (ref) => ref.watch(paymentRepositoryProvider).getPendingPayments());

// ── Submit payment state ──────────────────────────────────────────
class SubmitPaymentState {
  final bool isLoading;
  final bool success;
  final String? error;
  const SubmitPaymentState({this.isLoading = false, this.success = false, this.error});
  SubmitPaymentState copyWith({bool? isLoading, bool? success, String? error}) =>
      SubmitPaymentState(
        isLoading: isLoading ?? this.isLoading,
        success:   success   ?? this.success,
        error:     error,
      );
}

class SubmitPaymentNotifier extends StateNotifier<SubmitPaymentState> {
  final PaymentRepository _repo;
  SubmitPaymentNotifier(this._repo) : super(const SubmitPaymentState());

  Future<void> submit({
    required int billId, required double amount,
    required String utr, required String mode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.submitPayment(billId: billId, amount: amount, utr: utr, mode: mode);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const SubmitPaymentState();
}

final submitPaymentProvider =
    StateNotifierProvider<SubmitPaymentNotifier, SubmitPaymentState>(
        (ref) => SubmitPaymentNotifier(ref.watch(paymentRepositoryProvider)));

// ── Verify payment state ──────────────────────────────────────────
class VerifyPaymentNotifier extends StateNotifier<AsyncValue<void>> {
  final PaymentRepository _repo;
  VerifyPaymentNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> verify(int paymentId, String action) async {
    state = const AsyncValue.loading();
    try {
      await _repo.verifyPayment(paymentId, action);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final verifyPaymentProvider =
    StateNotifierProvider<VerifyPaymentNotifier, AsyncValue<void>>(
        (ref) => VerifyPaymentNotifier(ref.watch(paymentRepositoryProvider)));
