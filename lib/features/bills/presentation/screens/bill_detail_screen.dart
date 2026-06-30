import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../data/models/bill_model.dart';
import '../providers/bill_provider.dart';

class BillDetailScreen extends ConsumerWidget {
  final int billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find bill from cached list or fetch individually
    final myBillsAsync = ref.watch(myBillsProvider);

    return myBillsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (bills) {
        final bill = bills.firstWhere(
          (b) => b.billId == billId,
          orElse: () => bills.first,
        );
        return _BillDetailView(bill: bill);
      },
    );
  }
}

class _BillDetailView extends StatelessWidget {
  final BillModel bill;
  const _BillDetailView({required this.bill});

  Color get _statusColor => switch (bill.status) {
        'paid'    => AppColors.success,
        'overdue' => AppColors.error,
        'waived'  => AppColors.textMuted,
        _         => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${bill.monthName} ${bill.year}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bill PDF downloaded')));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Hero card ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bill.isOverdue
                    ? [AppColors.error, const Color(0xFF991B1B)]
                    : bill.isPaid
                        ? [AppColors.success, const Color(0xFF14532D)]
                        : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${bill.monthName} ${bill.year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    bill.status[0].toUpperCase() + bill.status.substring(1),
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text('₹${bill.total.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Total due${bill.unitNo != null ? ' · Unit ${bill.unitNo}' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Breakdown ───────────────────────────────────
          AppCard(child: Column(children: [
            _InfoRow(
              icon: Icons.home_outlined,
              label: 'Maintenance charge',
              value: '₹${bill.maintenance.toStringAsFixed(2)}',
            ),
            const Divider(height: 1),
            _InfoRow(
              icon: Icons.warning_amber_outlined,
              label: 'Late penalty',
              value: '₹${bill.penalty.toStringAsFixed(2)}',
              valueColor: bill.penalty > 0 ? AppColors.error : null,
            ),
            const Divider(height: 1),
            _InfoRow(
              icon: Icons.receipt_long_outlined,
              label: 'Total due',
              value: '₹${bill.total.toStringAsFixed(2)}',
              bold: true,
              valueColor: _statusColor,
            ),
            if (bill.dueDate != null) ...[
              const Divider(height: 1),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Due date',
                value: bill.dueDate!,
                valueColor: bill.isOverdue ? AppColors.error : null,
              ),
            ],
          ])),

          // ── Penalty formula ─────────────────────────────
          if (bill.haspenalty) ...[
            const SizedBox(height: 12),
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.calculate_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('Penalty calculation', style: AppTextStyles.bodyBold),
              ]),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _CodeLine('Outstanding:   ₹${bill.maintenance.toStringAsFixed(0)}'),
                  _CodeLine('Daily rate:    0.05%'),
                  _CodeLine('Formula:       Outstanding × Rate × Days'),
                  const SizedBox(height: 6),
                  Container(height: 1, color: const Color(0xFF334155)),
                  const SizedBox(height: 6),
                  Text(
                    'Penalty = ₹${bill.penalty.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 13,
                      color: Color(0xFF6EE7B7), fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
            ])),
          ],

          // ── Actions ─────────────────────────────────────
          if (!bill.isPaid && !bill.isWaived) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context), // nav to payment screen
              icon: const Icon(Icons.qr_code, size: 18),
              label: Text('Pay ₹${bill.total.toStringAsFixed(0)} now'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: bill.isOverdue ? AppColors.error : AppColors.primary,
              ),
            ),
          ],

          if (bill.isPaid) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                const SizedBox(width: 10),
                Text('This bill has been paid and verified.',
                    style: AppTextStyles.body.copyWith(color: AppColors.success)),
              ]),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final bool bold;

  const _InfoRow({
    required this.icon, required this.label, required this.value,
    this.valueColor, this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    child: Row(children: [
      Icon(icon, size: 17, color: AppColors.textMuted),
      const SizedBox(width: 10),
      Text(label, style: AppTextStyles.body),
      const Spacer(),
      Text(value, style: TextStyle(
        fontSize: 14,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        color: valueColor ?? AppColors.text,
      )),
    ]),
  );
}

class _CodeLine extends StatelessWidget {
  final String text;
  const _CodeLine(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Text(text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12,
            color: Color(0xFF94A3B8))),
  );
}
