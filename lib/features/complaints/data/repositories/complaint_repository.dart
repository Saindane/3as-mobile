import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../datasources/complaint_datasource.dart';
import '../models/complaint_model.dart';

final complaintRepositoryProvider = Provider<ComplaintRepository>(
    (ref) => ComplaintRepository(ComplaintDatasource(ref.watch(dioClientProvider))));

class ComplaintRepository {
  final ComplaintDatasource _ds;
  ComplaintRepository(this._ds);

  Future<List<ComplaintModel>> getComplaints({String? status}) =>
      _ds.getComplaints(status: status);

  Future<ComplaintModel> raise_({
    required String title,    required String category,
    required String priority, String? description,
  }) => _ds.raise_(title: title, category: category,
        priority: priority, description: description);

  Future<ComplaintModel> update(int id, Map<String, dynamic> data) =>
      _ds.update(id, data);
}
