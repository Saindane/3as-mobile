import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/payment_model.dart';

class PaymentDatasource {
  final DioClient _client;
  PaymentDatasource(this._client);

  Future<List<PaymentModel>> getMyPayments() async {
    try {
      final res = await _client.get(ApiEndpoints.payments);
      return (res.data['items'] as List)
          .map((j) => PaymentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<PaymentModel>> getPendingPayments() async {
    try {
      final res = await _client.get('${ApiEndpoints.payments}/pending');
      return (res.data['items'] as List)
          .map((j) => PaymentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> submitPayment({
    required int    billId,
    required double amount,
    required String utr,
    required String mode,
  }) async {
    try {
      final res = await _client.post(ApiEndpoints.payments, data: {
        'bill_id': billId,
        'amount':  amount,
        'utr':     utr,
        'mode':    mode,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> verifyPayment(int paymentId, String action) async {
    try {
      final res = await _client.patch(
        '${ApiEndpoints.payments}/$paymentId/verify',
        data: {'action': action},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
