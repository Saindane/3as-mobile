import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/payment_provider.dart';

class VerifyPaymentsScreen extends ConsumerWidget {
  const VerifyPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(pendingPaymentsProvider);

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (payments) {
        if (payments.isEmpty) {
          return const EmptyState(
            icon: Icons.verified_outlined,
            title: 'No pending payments',
            subtitle: 'All submitted payments have been processed.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingPaymentsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _VerifyCard(
              payment: payments[i],
              onVerify: (action) async {
                await ref.read(verifyPaymentProvider.notifier)
                    .verify(payments[i].paymentId, action);
                ref.invalidate(pendingPaymentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(action == 'verify'
                        ? '✓ Payment verified — resident notified'
                        : '✗ Payment rejected — resident notified'),
                    backgroundColor: action == 'verify'
                        ? AppColors.success : AppColors.error,
                  ));
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _VerifyCard extends StatelessWidget {
  final dynamic payment;
  final Future<void> Function(String action) onVerify;

  const _VerifyCard({required this.payment, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              payment.unitNo != null ? 'Unit ${payment.unitNo}' : 'Payment #${payment.paymentId}',
              style: AppTextStyles.bodyBold,
            ),
            Text('Bill #${payment.billId}', style: AppTextStyles.caption),
          ]),
          AppBadge(label: 'Pending verify', color: AppColors.warning),
        ]),

        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),

        // Details row
        Row(children: [
          _DetailItem(label: 'Amount',  value: '₹${payment.amount.toStringAsFixed(0)}'),
          _DetailItem(label: 'Mode',    value: payment.mode.toString().toUpperCase()),
          _DetailItem(label: 'Submitted', value: _formatDate(payment.createdAt)),
        ]),

        if (payment.utr != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.tag, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('UTR: ${payment.utr}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12,
                      color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],

        const SizedBox(height: 12),

        // Action buttons
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onVerify('verify'),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Verify'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(0, 40),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onVerify('reject'),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(0, 40),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }
}

class _DetailItem extends StatelessWidget {
  final String label, value;
  const _DetailItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.caption),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
    ]),
  );
}
