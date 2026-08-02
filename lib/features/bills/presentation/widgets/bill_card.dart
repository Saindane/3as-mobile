import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../data/models/bill_model.dart';

class BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback? onTap;
  final String? paymentStatus; // 'PENDING', 'REJECTED', or null

  const BillCard({super.key, required this.bill, this.onTap, this.paymentStatus});

  Color get _statusColor {
    if (paymentStatus == 'REJECTED') return AppColors.error;
    if (paymentStatus == 'PENDING')  return AppColors.warning;
    return switch (bill.status.toUpperCase()) {
      'PAID'    => AppColors.success,
      'OVERDUE' => AppColors.error,
      'WAIVED'  => AppColors.textMuted,
      _         => AppColors.warning,
    };
  }

  IconData get _statusIcon {
    if (paymentStatus == 'REJECTED') return Icons.cancel_outlined;
    if (paymentStatus == 'PENDING')  return Icons.pending_outlined;
    return switch (bill.status.toUpperCase()) {
      'PAID'    => Icons.check_circle_outline,
      'OVERDUE' => Icons.warning_amber_outlined,
      'WAIVED'  => Icons.do_disturb_alt_outlined,
      _         => Icons.pending_outlined,
    };
  }

  String get _badgeLabel {
    if (paymentStatus == 'REJECTED') return 'Rejected';
    if (paymentStatus == 'PENDING')  return 'Verifying';
    final s = bill.status.toUpperCase();
    return s[0] + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: bill.isOverdue ? AppColors.error.withOpacity(.4) : null,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${bill.monthName} ${bill.year}', style: AppTextStyles.bodyBold),
            if (bill.unitNo != null)
              Text('Unit ${bill.unitNo}', style: AppTextStyles.caption),
          ])),
          AppBadge(
            label: _badgeLabel,
            color: _statusColor,
          ),
        ]),

        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),

        // Amount breakdown
        Row(children: [
          _AmtCol(label: 'Maintenance', value: '₹${bill.maintenance.toStringAsFixed(0)}'),
          _AmtCol(
            label: 'Penalty',
            value: '₹${bill.penalty.toStringAsFixed(0)}',
            color: bill.penalty > 0 ? AppColors.error : null,
          ),
          _AmtCol(
            label: 'Total due',
            value: '₹${bill.total.toStringAsFixed(0)}',
            bold: true,
            color: bill.isOverdue ? AppColors.error : AppColors.text,
          ),
        ]),

        // Payment status banner
        if (paymentStatus == 'REJECTED') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.error.withOpacity(.3)),
            ),
            child: const Row(children: [
              Icon(Icons.cancel_outlined, size: 13, color: AppColors.error),
              SizedBox(width: 6),
              Text('Payment rejected — please resubmit',
                  style: TextStyle(fontSize: 11, color: AppColors.error)),
            ]),
          ),
        ] else if (paymentStatus == 'PENDING') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.warning.withOpacity(.3)),
            ),
            child: const Row(children: [
              Icon(Icons.pending_outlined, size: 13, color: AppColors.warning),
              SizedBox(width: 6),
              Text('Payment submitted — awaiting verification',
                  style: TextStyle(fontSize: 11, color: AppColors.warning)),
            ]),
          ),
        ],

        // Penalty formula banner
        if (bill.haspenalty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(children: [
              const Icon(Icons.calculate_outlined, color: Color(0xFF7DD3FC), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bill.penaltyFormula,
                  style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 11, color: Color(0xFF7DD3FC)),
                ),
              ),
            ]),
          ),
        ],

        // Due date
        if (bill.dueDate != null) ...[
          const SizedBox(height: 8),
          Text('Due: ${bill.dueDate}',
              style: AppTextStyles.caption.copyWith(
                  color: bill.isOverdue ? AppColors.error : AppColors.textMuted)),
        ],
      ]),
    );
  }
}

class _AmtCol extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _AmtCol({required this.label, required this.value, this.bold = false, this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.caption),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(
        fontSize: 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        color: color ?? AppColors.text,
      )),
    ]),
  );
}
