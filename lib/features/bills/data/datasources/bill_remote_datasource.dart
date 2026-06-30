import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/bill_model.dart';

class BillRemoteDatasource {
  final DioClient _client;
  BillRemoteDatasource(this._client);

  Future<List<BillModel>> getMyBills() async {
    try {
      final res = await _client.get(ApiEndpoints.bills);
      final items = res.data['items'] as List;
      return items.map((j) => BillModel.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<BillModel>> getAllBills({
    int? month, int? year, String? status,
  }) async {
    try {
      final res = await _client.get(ApiEndpoints.bills, queryParameters: {
        if (month  != null) 'month':  month,
        if (year   != null) 'year':   year,
        if (status != null) 'status': status,
      });
      final items = res.data['items'] as List;
      return items.map((j) => BillModel.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BillModel> getBill(int billId) async {
    try {
      final res = await _client.get('${ApiEndpoints.bills}/$billId');
      return BillModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> generateBills({
    required int month, required int year,
    required double maintenance, required String dueDate,
    bool includepenalty = true,
  }) async {
    try {
      final res = await _client.post(ApiEndpoints.generateBills, data: {
        'month': month, 'year': year,
        'maintenance': maintenance, 'due_date': dueDate,
        'include_penalty': includepenalty,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CollectionSummary> getCollectionSummary(int month, int year) async {
    try {
      final res = await _client.get(
        '${ApiEndpoints.bills}/summary',
        queryParameters: {'month': month, 'year': year},
      );
      return CollectionSummary.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPenaltyPreviews() async {
    try {
      final res = await _client.get('${ApiEndpoints.bills}/penalties/preview');
      return List<Map<String, dynamic>>.from(res.data as List);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> applyPenalties() async {
    try {
      await _client.post('${ApiEndpoints.bills}/penalties/apply');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
