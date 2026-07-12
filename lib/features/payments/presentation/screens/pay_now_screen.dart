import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../bills/presentation/providers/bill_provider.dart';
import '../providers/payment_provider.dart';

class PayNowScreen extends ConsumerStatefulWidget {
  final int? billId;
  final double? amount;
  const PayNowScreen({super.key, this.billId, this.amount});

  @override
  ConsumerState<PayNowScreen> createState() => _PayNowScreenState();
}

class _PayNowScreenState extends ConsumerState<PayNowScreen> {
  final _utrCtr  = TextEditingController();
  String _mode   = 'UPI';
  int?   _selectedBillId;
  double _selectedAmount = 0;
  int    _step = 0; // 0: select bill, 1: payment details, 2: success

  @override
  void initState() {
    super.initState();
    if (widget.billId != null) {
      _selectedBillId = widget.billId;
      _selectedAmount = widget.amount ?? 0;
      _step = 1;
    }
  }

  @override
  void dispose() {
    _utrCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_utrCtr.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter the UTR / transaction ID'),
          backgroundColor: AppColors.error));
      return;
    }
    await ref.read(submitPaymentProvider.notifier).submit(
      billId: _selectedBillId!,
      amount: _selectedAmount,
      utr:    _utrCtr.text.trim(),
      mode:   _mode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submitPaymentProvider);

    ref.listen(submitPaymentProvider, (_, next) {
      if (next.success) setState(() => _step = 2);
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.error!), backgroundColor: AppColors.error));
      }
    });

    if (_step == 2) return _SuccessView(onDone: () async {
      ref.read(submitPaymentProvider.notifier).reset();
      // Invalidate and WAIT for providers to refetch before going back to step 0
      // This ensures pendingBillIds is populated before the bill list renders
      ref.invalidate(myPaymentsProvider);
      ref.invalidate(myBillsProvider);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _step           = 0;
          _selectedBillId = null;
          _selectedAmount = 0;
          _utrCtr.clear();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Pay now')),
      body: ListView(padding: const EdgeInsets.all(20), children: [

        // ── Step 0: Select bill ────────────────────────
        if (_step == 0) ...[
          Text('Select bill to pay', style: AppTextStyles.heading3),
          const SizedBox(height: 14),
          ref.watch(myBillsProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Text('Error: $e'),
            data: (bills) {
              if (bills.isEmpty) {
                return const AppCard(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(children: [
                    Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 40),
                    SizedBox(height: 8),
                    Text('No bills found', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ));
              }

              // Get IDs of bills that already have a pending payment submitted
              final myPaymentsAsync = ref.watch(myPaymentsProvider);
              final pendingBillIds = myPaymentsAsync.whenData((payments) =>
                payments.where((p) => p.status.toUpperCase() == 'PENDING')
                        .map((p) => p.billId).toSet()
              ).valueOrNull ?? <int>{};

              if (bills.every((b) => b.isPaid || b.isWaived)) {
                return const AppCard(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 40),
                    SizedBox(height: 8),
                    Text('All bills are paid!',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ));
              }

              return Column(children: bills.map((bill) {
                final hasPendingPayment = pendingBillIds.contains(bill.billId);
                final isSettled = bill.isPaid || bill.isWaived;
                final canPay = !isSettled && !hasPendingPayment;

                final badgeColor = isSettled
                    ? AppColors.success
                    : hasPendingPayment
                        ? AppColors.warning
                        : bill.isOverdue
                            ? AppColors.error
                            : AppColors.warning;

                final badgeLabel = isSettled
                    ? 'Paid'
                    : hasPendingPayment
                        ? 'Verifying'
                        : bill.isOverdue
                            ? 'Overdue'
                            : 'Pending';

                final subText = isSettled
                    ? 'Payment confirmed'
                    : hasPendingPayment
                        ? 'Submitted — awaiting verification'
                        : '₹${bill.total.toStringAsFixed(0)} due';

                final subColor = isSettled
                    ? AppColors.success
                    : hasPendingPayment
                        ? AppColors.warning
                        : bill.isOverdue
                            ? AppColors.error
                            : AppColors.textSecondary;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    borderColor: isSettled
                        ? AppColors.success.withOpacity(.3)
                        : hasPendingPayment
                            ? AppColors.warning.withOpacity(.3)
                            : bill.isOverdue
                                ? AppColors.error.withOpacity(.4)
                                : null,
                    onTap: canPay
                        ? () => setState(() {
                            _selectedBillId = bill.billId;
                            _selectedAmount = bill.total;
                            _step = 1;
                          })
                        : hasPendingPayment
                            ? () {
                                // Show payment details - UTR already submitted
                                final payment = myPaymentsAsync.valueOrNull
                                    ?.firstWhere((p) => p.billId == bill.billId,
                                        orElse: () => myPaymentsAsync.valueOrNull!.first);
                                if (payment != null) {
                                  showDialog(context: context, builder: (_) =>
                                    AlertDialog(
                                      title: const Text('Payment submitted'),
                                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.pending_outlined,
                                            size: 48, color: AppColors.warning),
                                        const SizedBox(height: 12),
                                        _PaymentDetailRow(label: 'Bill', value: '${bill.monthName} ${bill.year}'),
                                        _PaymentDetailRow(label: 'Amount', value: '₹${payment.amount.toStringAsFixed(0)}'),
                                        _PaymentDetailRow(label: 'UTR / Ref No', value: payment.utr ?? '-'),
                                        _PaymentDetailRow(label: 'Mode', value: payment.mode),
                                        _PaymentDetailRow(label: 'Status', value: 'Awaiting verification'),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.warningLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Management will verify your payment within 24 hours.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12, color: AppColors.warning),
                                          ),
                                        ),
                                      ]),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            : null,
                    child: Row(children: [
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${bill.monthName} ${bill.year}',
                            style: AppTextStyles.bodyBold),
                        const SizedBox(height: 2),
                        Text(subText, style: AppTextStyles.caption.copyWith(color: subColor)),
                      ])),
                      AppBadge(label: badgeLabel, color: badgeColor),
                      const SizedBox(width: 6),
                      if (canPay)
                        const Icon(Icons.chevron_right, color: AppColors.textMuted)
                      else
                        const SizedBox(width: 20),
                    ]),
                  ),
                );
              }).toList());
            },
          ),
        ],

        // ── Step 1: Payment details ────────────────────
        if (_step == 1) ...[
          // Amount banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Amount to pay',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text('₹${_selectedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 32, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 20),

          // QR code
          AppCard(child: Column(children: [
            Row(children: [
              // QR placeholder
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2, size: 70, color: AppColors.text),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Scan & pay via UPI', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('UPI ID:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Row(children: [
                  const Text('3ascomplex@upi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: '3ascomplex@upi'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('UPI ID copied')));
                    },
                    child: const Icon(Icons.copy, size: 14, color: AppColors.textMuted),
                  ),
                ]),
                const SizedBox(height: 6),
                const Text('Or use NEFT/RTGS:',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const Text('A/c: 1234 5678 9012\nIFSC: HDFC0001234',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
            ]),
          ])),
          const SizedBox(height: 20),

          // UTR + mode
          Text('Upload payment proof', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('UTR / Transaction ID', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _utrCtr,
              decoration: const InputDecoration(
                hintText: 'e.g. TXN98765432',
                filled: true,
                fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Payment mode', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _mode,
              decoration: const InputDecoration(
                filled: true, fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              items: ['UPI', 'NEFT', 'RTGS', 'CASH', 'CHEQUE']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
                  .toList(),
              onChanged: (v) => setState(() => _mode = v!),
            ),
          ]),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: state.isLoading ? null : _submit,
            icon: state.isLoading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, size: 18),
            label: Text(state.isLoading ? 'Submitting...' : 'Submit for verification'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => setState(() => _step = 0),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Back'),
          ),
        ],
      ]),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Payment submitted')),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 44),
        ),
        const SizedBox(height: 16),
        Text('Payment submitted!', style: AppTextStyles.heading2),
        const SizedBox(height: 8),
        const Text(
          'Your payment has been submitted for verification.\nManagement will confirm within 24 hours.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        // Status steps
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _StepBadge('Submitted', true),
          _Arrow(), _StepBadge('Verifying', true, active: true),
          _Arrow(), _StepBadge('Confirmed', false),
        ]),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
          child: const Text('Done'),
        ),
      ]),
    )),
  );
}

class _StepBadge extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  const _StepBadge(this.label, this.done, {this.active = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active ? AppColors.primaryLight
           : done   ? AppColors.successLight
           : AppColors.slate100,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: active ? AppColors.primary
           : done   ? AppColors.success
           : AppColors.textMuted,
    )),
  );
}

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted));
}

class _PaymentDetailRow extends StatelessWidget {
  final String label, value;
  const _PaymentDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(
            fontSize: 13, color: AppColors.textMuted)),
        Flexible(child: Text(value, textAlign: TextAlign.end,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    ),
  );
}
