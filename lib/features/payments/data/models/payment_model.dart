class PaymentModel {
  final int     paymentId;
  final int     billId;
  final double  amount;
  final String? utr;
  final String? screenshot;
  final String  mode;
  final String  status;
  final int?    verifiedBy;
  final String? verifiedAt;
  final String  createdAt;
  final String? unitNo;

  const PaymentModel({
    required this.paymentId,
    required this.billId,
    required this.amount,
    this.utr,
    this.screenshot,
    required this.mode,
    required this.status,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    this.unitNo,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
        paymentId:  j['payment_id']  as int,
        billId:     j['bill_id']     as int,
        amount:     (j['amount']     as num).toDouble(),
        utr:        j['utr']         as String?,
        screenshot: j['screenshot']  as String?,
        mode:       j['mode']        as String,
        status:     j['status']      as String,
        verifiedBy: j['verified_by'] as int?,
        verifiedAt: j['verified_at'] as String?,
        createdAt:  j['created_at']  as String,
        unitNo:     j['unit_no']     as String?,
      );

  bool get isPending  => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isRejected => status == 'rejected';
}
