class BillModel {
  final int     billId;
  final int     propertyId;
  final String? unitNo;
  final int     month;
  final int     year;
  final double  maintenance;
  final double  penalty;
  final double  total;
  final String? dueDate;
  final String  status;
  final String  createdAt;

  const BillModel({
    required this.billId,
    required this.propertyId,
    this.unitNo,
    required this.month,
    required this.year,
    required this.maintenance,
    required this.penalty,
    required this.total,
    this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory BillModel.fromJson(Map<String, dynamic> j) => BillModel(
        billId:      j['bill_id']      as int,
        propertyId:  j['property_id']  as int,
        unitNo:      j['unit_no']      as String?,
        month:       j['month']        as int,
        year:        j['year']         as int,
        maintenance: (j['maintenance'] as num).toDouble(),
        penalty:     (j['penalty']     as num).toDouble(),
        total:       (j['total']       as num).toDouble(),
        dueDate:     j['due_date']     as String?,
        status:      j['status']       as String,
        createdAt:   j['created_at']   as String,
      );

  bool get isOverdue  => status.toUpperCase() == 'OVERDUE';
  bool get isPaid     => status.toUpperCase() == 'PAID';
  bool get isPending  => status.toUpperCase() == 'PENDING';
  bool get isWaived   => status.toUpperCase() == 'WAIVED';
  bool get haspenalty => penalty > 0;

  String get monthName => const [
    '', 'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ][month];

  String get penaltyFormula =>
      '₹${maintenance.toStringAsFixed(0)} × 0.05% × days overdue = ₹${penalty.toStringAsFixed(2)}';
}

class CollectionSummary {
  final int    month;
  final int    year;
  final int    totalBills;
  final int    paidCount;
  final int    pendingCount;
  final int    overdueCount;
  final double paidAmount;
  final double pendingAmount;
  final double collectionPct;

  const CollectionSummary({
    required this.month,
    required this.year,
    required this.totalBills,
    required this.paidCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.collectionPct,
  });

  factory CollectionSummary.fromJson(Map<String, dynamic> j) => CollectionSummary(
        month:         j['month']           as int,
        year:          j['year']            as int,
        totalBills:    j['total_bills']     as int,
        paidCount:     j['paid_count']      as int,
        pendingCount:  j['pending_count']   as int,
        overdueCount:  j['overdue_count']   as int,
        paidAmount:    (j['paid_amount']    as num).toDouble(),
        pendingAmount: (j['pending_amount'] as num).toDouble(),
        collectionPct: (j['collection_pct'] as num).toDouble(),
      );
}
