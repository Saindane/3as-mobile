import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../data/models/payment_model.dart';
import '../providers/payment_provider.dart';
import 'pay_now_screen.dart';
import 'verify_payments_screen.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  final bool isAdmin;
  const PaymentsScreen({super.key, this.isAdmin = false});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.isAdmin ? 2 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Payments', style: AppTextStyles.heading2),
              if (!widget.isAdmin)
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PayNowScreen())),
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Pay now'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: widget.isAdmin
                  ? const [Tab(text: 'Pending verify'), Tab(text: 'All payments')]
                  : const [Tab(text: 'My payments'),   Tab(text: 'Pay now')],
            ),
          ]),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: widget.isAdmin
                ? [const VerifyPaymentsScreen(), _AllPaymentsList()]
                : [_MyPaymentsList(), const PayNowScreen()],
          ),
        ),
      ]),
    );
  }
}

// ── My payments list ─────────────────────────────────────────────
class _MyPaymentsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(myPaymentsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (payments) {
        if (payments.isEmpty) {
          return const EmptyState(
            icon: Icons.payment_outlined,
            title: 'No payments yet',
            subtitle: 'Your submitted payments will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myPaymentsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _PaymentCard(payment: payments[i]),
          ),
        );
      },
    );
  }
}

// ── All payments (admin view) ─────────────────────────────────────
class _AllPaymentsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(myPaymentsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (payments) => payments.isEmpty
          ? const EmptyState(icon: Icons.payment_outlined,
              title: 'No payments found', subtitle: '')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _PaymentCard(payment: payments[i], showUnit: true),
            ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final bool showUnit;
  const _PaymentCard({required this.payment, this.showUnit = false});

  Color get _statusColor => switch (payment.status.toUpperCase()) {
        'VERIFIED' => AppColors.success,
        'REJECTED' => AppColors.error,
        _          => AppColors.warning,
      };

  IconData get _statusIcon => switch (payment.status.toUpperCase()) {
        'VERIFIED' => Icons.check_circle_outline,
        'REJECTED' => Icons.cancel_outlined,
        _          => Icons.pending_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: _statusColor.withOpacity(.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_statusIcon, color: _statusColor, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('₹${payment.amount.toStringAsFixed(0)}',
              style: AppTextStyles.bodyBold),
          const SizedBox(width: 6),
          Text('· ${payment.mode.toUpperCase()}',
              style: AppTextStyles.caption),
        ]),
        if (payment.utr != null)
          Text('UTR: ${payment.utr}', style: AppTextStyles.caption),
        if (showUnit && payment.unitNo != null)
          Text('Unit ${payment.unitNo}',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
      ])),
      AppBadge(
        label: payment.status[0].toUpperCase() + payment.status.substring(1).toLowerCase(),
        color: _statusColor,
      ),
    ]));
  }
}
