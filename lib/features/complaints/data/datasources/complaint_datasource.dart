import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/complaint_model.dart';

class ComplaintDatasource {
  final DioClient _client;
  ComplaintDatasource(this._client);

  Future<List<ComplaintModel>> getComplaints({String? status}) async {
    try {
      final res = await _client.get(ApiEndpoints.complaints,
          queryParameters: {if (status != null) 'status': status});
      return (res.data['items'] as List)
          .map((j) => ComplaintModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ComplaintModel> raise_({
    required String title,
    required String category,
    required String priority,
    String? description,
  }) async {
    try {
      final res = await _client.post(ApiEndpoints.complaints, data: {
        'title':       title,
        'category':    category,
        'priority':    priority,
        'description': description,
      });
      return ComplaintModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ComplaintModel> update(int id, Map<String, dynamic> data) async {
    try {
      final res = await _client.patch('${ApiEndpoints.complaints}/$id', data: data);
      return ComplaintModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
