import 'package:flutter_test/flutter_test.dart';
import 'package:three_as_complex/features/bills/data/models/bill_model.dart';

void main() {
  group('BillModel', () {
    test('parses from JSON correctly', () {
      final json = {
        'bill_id': 1,
        'property_id': 10,
        'unit_no': '4B',
        'month': 6,
        'year': 2025,
        'maintenance': 2000.0,
        'penalty': 450.0,
        'total': 2450.0,
        'due_date': '2025-06-10',
        'status': 'overdue',
        'created_at': '2025-06-01T00:00:00Z',
      };

      final bill = BillModel.fromJson(json);

      expect(bill.billId, 1);
      expect(bill.unitNo, '4B');
      expect(bill.monthName, 'June');
      expect(bill.total, 2450.0);
      expect(bill.isOverdue, true);
      expect(bill.isPaid, false);
      expect(bill.haspenalty, true);
    });

    test('isPaid is true for paid status', () {
      final bill = BillModel.fromJson({
        'bill_id': 2, 'property_id': 11, 'unit_no': '2A',
        'month': 5, 'year': 2025, 'maintenance': 2000.0,
        'penalty': 0.0, 'total': 2000.0, 'due_date': '2025-05-10',
        'status': 'paid', 'created_at': '2025-05-01T00:00:00Z',
      });
      expect(bill.isPaid, true);
      expect(bill.haspenalty, false);
    });

    test('monthName maps correctly for all months', () {
      for (int m = 1; m <= 12; m++) {
        final bill = BillModel.fromJson({
          'bill_id': m, 'property_id': 1, 'month': m, 'year': 2025,
          'maintenance': 1000.0, 'penalty': 0.0, 'total': 1000.0,
          'status': 'pending', 'created_at': '2025-01-01T00:00:00Z',
        });
        expect(bill.monthName, isNotEmpty);
      }
    });
  });

  group('CollectionSummary', () {
    test('parses from JSON correctly', () {
      final summary = CollectionSummary.fromJson({
        'month': 6, 'year': 2025, 'total_bills': 48,
        'paid_count': 36, 'pending_count': 9, 'overdue_count': 3,
        'paid_amount': 72000.0, 'pending_amount': 24000.0,
        'collection_pct': 75.0,
      });

      expect(summary.totalBills, 48);
      expect(summary.collectionPct, 75.0);
      expect(summary.paidAmount, 72000.0);
    });
  });
}
