import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../datasources/payment_datasource.dart';
import '../models/payment_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
    (ref) => PaymentRepository(PaymentDatasource(ref.watch(dioClientProvider))));

class PaymentRepository {
  final PaymentDatasource _ds;
  PaymentRepository(this._ds);

  Future<List<PaymentModel>>     getMyPayments()                         => _ds.getMyPayments();
  Future<List<PaymentModel>>     getPendingPayments()                     => _ds.getPendingPayments();
  Future<Map<String, dynamic>>   verifyPayment(int id, String action)     => _ds.verifyPayment(id, action);
  Future<Map<String, dynamic>>   submitPayment({
    required int billId, required double amount,
    required String utr, required String mode,
  }) => _ds.submitPayment(billId: billId, amount: amount, utr: utr, mode: mode);
}
