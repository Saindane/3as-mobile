import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../datasources/bill_remote_datasource.dart';
import '../models/bill_model.dart';

final billRepositoryProvider = Provider<BillRepository>((ref) =>
    BillRepository(BillRemoteDatasource(ref.watch(dioClientProvider))));

class BillRepository {
  final BillRemoteDatasource _remote;
  BillRepository(this._remote);

  Future<List<BillModel>>     getMyBills()                                  => _remote.getMyBills();
  Future<List<BillModel>>     getAllBills({int? month, int? year, String? status}) =>
      _remote.getAllBills(month: month, year: year, status: status);
  Future<BillModel>           getBill(int id)                               => _remote.getBill(id);
  Future<CollectionSummary>   getCollectionSummary(int month, int year)     => _remote.getCollectionSummary(month, year);
  Future<List<Map<String,dynamic>>> getPenaltyPreviews()                    => _remote.getPenaltyPreviews();
  Future<void>                applyPenalties()                              => _remote.applyPenalties();
  Future<Map<String,dynamic>> generateBills({
    required int month, required int year,
    required double maintenance, required String dueDate,
    bool includepenalty = true,
  }) => _remote.generateBills(
        month: month, year: year, maintenance: maintenance,
        dueDate: dueDate, includepenalty: includepenalty);
}
