import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';
import '../../../bills/presentation/providers/bill_provider.dart';
import '../../../bills/data/models/bill_model.dart';
import '../../../complaints/presentation/providers/complaint_provider.dart';
import '../../../notices/presentation/providers/notice_provider.dart';
import '../../../payments/presentation/providers/payment_provider.dart';

class ResidentDashboardScreen extends ConsumerWidget {
  const ResidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync    = ref.watch(userProfileProvider);
    final propAsync       = ref.watch(myPropertyProvider);
    final billsAsync      = ref.watch(myBillsProvider);
    final paymentsAsync   = ref.watch(myPaymentsProvider);
    final complaintsAsync = ref.watch(complaintsProvider);
    final noticesAsync    = ref.watch(noticesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(myPropertyProvider);
        ref.invalidate(myBillsProvider);
        ref.invalidate(myPaymentsProvider);
        ref.invalidate(complaintsProvider);
        ref.invalidate(noticesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Greeting banner ───────────────────────────────
          profileAsync.when(
            loading: () => const _Skeleton(height: 100),
            error:   (_, __) => const SizedBox(),
            data: (profile) => propAsync.when(
              loading: () => const _Skeleton(height: 100),
              error:   (_, __) => _GreetingBanner(name: profile.name, unit: null),
              data: (prop) => _GreetingBanner(name: profile.name, unit: prop),
            ),
          ),

          const SizedBox(height: 16),

          // ── Stats row ─────────────────────────────────────
          billsAsync.when(
            loading: () => const _Skeleton(height: 90),
            error:   (_, __) => const SizedBox(),
            data: (bills) {
              final pendingBillIds = paymentsAsync.whenData((p) =>
                p.where((x) => x.status.toUpperCase() == 'PENDING')
                 .map((x) => x.billId).toSet()
              ).valueOrNull ?? <int>{};

              final unpaid    = bills.where((b) => !b.isPaid && !b.isWaived).toList();
              final paid      = bills.where((b) => b.isPaid).length;
              final totalDue  = unpaid.fold(0.0, (s, b) => s + b.total);
              final overdue   = unpaid.where((b) => b.isOverdue).length;
              final verifying = pendingBillIds.length;

              return Row(children: [
                Expanded(child: _StatTile(
                  icon: Icons.receipt_long_outlined,
                  iconColor: totalDue > 0 ? AppColors.error : AppColors.success,
                  label: 'Amount due',
                  value: totalDue > 0 ? '₹${totalDue.toStringAsFixed(0)}' : '₹0',
                  sub: overdue > 0 ? '$overdue overdue' : verifying > 0 ? 'Verifying' : 'All clear',
                  subColor: overdue > 0 ? AppColors.error : AppColors.success,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.success,
                  label: 'Months paid',
                  value: '$paid',
                  sub: paid > 0 ? 'This year' : 'None yet',
                  subColor: AppColors.textMuted,
                )),
                const SizedBox(width: 10),
                Expanded(child: complaintsAsync.when(
                  loading: () => const _StatTile(icon: Icons.build_circle_outlined,
                      iconColor: AppColors.warning, label: 'Complaints', value: '-', sub: ''),
                  error:   (_, __) => const _StatTile(icon: Icons.build_circle_outlined,
                      iconColor: AppColors.warning, label: 'Complaints', value: '-', sub: ''),
                  data: (complaints) {
                    final open = complaints.where((c) =>
                        c.status.toUpperCase() != 'RESOLVED' &&
                        c.status.toUpperCase() != 'CLOSED').length;
                    return _StatTile(
                      icon: Icons.build_circle_outlined,
                      iconColor: AppColors.warning,
                      label: 'Complaints',
                      value: '$open',
                      sub: open > 0 ? 'Open' : 'All resolved',
                      subColor: open > 0 ? AppColors.warning : AppColors.success,
                    );
                  },
                )),
              ]);
            },
          ),

          const SizedBox(height: 16),

          // ── Bills section ─────────────────────────────────
          billsAsync.when(
            loading: () => const _Skeleton(height: 130),
            error:   (_, __) => const SizedBox(),
            data: (bills) {
              final pendingBillIds = paymentsAsync.whenData((p) =>
                p.where((x) => x.status.toUpperCase() == 'PENDING')
                 .map((x) => x.billId).toSet()
              ).valueOrNull ?? <int>{};

              final unpaid = bills.where((b) => !b.isPaid && !b.isWaived).toList();
              if (unpaid.isEmpty) {
                return AppCard(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 36),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('All bills paid!', style: AppTextStyles.bodyBold),
                      Text('Great job staying on time 🎉',
                          style: AppTextStyles.caption),
                    ]),
                  ]),
                ));
              }

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Bills'),
                const SizedBox(height: 10),
                ...unpaid.map((bill) {
                  final hasSubmitted = pendingBillIds.contains(bill.billId);
                  final isOverdue    = bill.isOverdue;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      borderColor: isOverdue
                          ? AppColors.error.withOpacity(.5)
                          : hasSubmitted
                              ? AppColors.warning.withOpacity(.5)
                              : AppColors.primary.withOpacity(.3),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Header row
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${_monthName(bill.month)} ${bill.year}',
                                style: AppTextStyles.bodyBold),
                            Text(
                              hasSubmitted
                                  ? 'Payment submitted — awaiting verification'
                                  : isOverdue
                                      ? 'Overdue — penalty accruing daily'
                                      : bill.dueDate != null ? 'Due by ${bill.dueDate}' : 'Payment pending',
                              style: AppTextStyles.caption.copyWith(
                                color: hasSubmitted
                                    ? AppColors.warning
                                    : isOverdue
                                        ? AppColors.error
                                        : AppColors.textMuted,
                              ),
                            ),
                          ])),
                          AppBadge(
                            label: hasSubmitted
                                ? 'Verifying'
                                : isOverdue ? 'Overdue' : 'Pending',
                            color: hasSubmitted
                                ? AppColors.warning
                                : isOverdue ? AppColors.error : AppColors.warning,
                          ),
                        ]),

                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),

                        // Amount breakdown
                        Row(children: [
                          Expanded(child: _AmountItem(
                              label: 'Maintenance',
                              value: '₹${bill.maintenance.toStringAsFixed(0)}')),
                          if (bill.penalty > 0) ...[
                            Expanded(child: _AmountItem(
                                label: 'Penalty',
                                value: '₹${bill.penalty.toStringAsFixed(0)}',
                                valueColor: AppColors.error)),
                          ],
                          Expanded(child: _AmountItem(
                              label: 'Total due',
                              value: '₹${bill.total.toStringAsFixed(0)}',
                              valueColor: AppColors.error,
                              bold: true)),
                        ]),

                        if (!hasSubmitted) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                // Switch to Pay now tab (index 2 for resident)
                // This is handled by AppShell via bottom nav
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Tap "Pay now" in the menu to make payment'),
                  duration: Duration(seconds: 2),
                ));
              },
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('Pay now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOverdue
                                    ? AppColors.error : AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  );
                }),
              ]);
            },
          ),

          const SizedBox(height: 16),

          // ── Recent activity ───────────────────────────────
          _buildRecentActivity(complaintsAsync, noticesAsync, paymentsAsync),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(
    AsyncValue complaintsAsync,
    AsyncValue noticesAsync,
    AsyncValue paymentsAsync,
  ) {
    final items = <_ActivityItem>[];

    // Add payment activities
    if (paymentsAsync is AsyncData) {
      final payments = (paymentsAsync as AsyncData).value as List;
      for (final p in payments.take(2)) {
        items.add(_ActivityItem(
          icon: p.status.toString().toUpperCase() == 'VERIFIED'
              ? Icons.check_circle_outline : Icons.pending_outlined,
          color: p.status.toString().toUpperCase() == 'VERIFIED'
              ? AppColors.success : AppColors.warning,
          title: p.status.toString().toUpperCase() == 'VERIFIED'
              ? 'Payment verified'
              : 'Payment submitted — awaiting verification',
          sub: '₹${p.amount.toStringAsFixed(0)} · UTR: ${p.utr ?? "-"}',
          date: p.createdAt,
        ));
      }
    }

    // Add complaint activities
    if (complaintsAsync is AsyncData) {
      final complaints = (complaintsAsync as AsyncData).value as List;
      for (final c in complaints.take(2)) {
        items.add(_ActivityItem(
          icon: Icons.build_circle_outlined,
          color: AppColors.warning,
          title: c.title as String,
          sub: c.status.toString()[0].toUpperCase() +
              c.status.toString().substring(1).toLowerCase(),
          date: c.createdAt as String,
        ));
      }
    }

    // Add notice activities
    if (noticesAsync is AsyncData) {
      final notices = (noticesAsync as AsyncData).value as List;
      for (final n in notices.take(2)) {
        items.add(_ActivityItem(
          icon: Icons.campaign_outlined,
          color: AppColors.primary,
          title: n.title as String,
          sub: n.category as String? ?? 'Notice',
          date: n.createdAt as String,
        ));
      }
    }

    if (items.isEmpty) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader(title: 'Recent activity'),
      const SizedBox(height: 10),
      AppCard(child: Column(
        children: items.asMap().entries.map((e) {
          final i    = e.key;
          final item = e.value;
          return Column(children: [
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: item.color.withOpacity(.1), shape: BoxShape.circle),
                  child: Icon(item.icon, color: item.color, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(item.sub, style: AppTextStyles.caption),
                ])),
                Text(_relativeDate(item.date),
                    style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ]),
            ),
          ]);
        }).toList(),
      )),
    ]);
  }

  String _monthName(int m) => [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ][m];

  String _relativeDate(String iso) {
    try {
      final dt   = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7)  return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────

class _GreetingBanner extends StatelessWidget {
  final String name;
  final dynamic unit;
  const _GreetingBanner({required this.name, this.unit});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$_greeting 👋',
            style: AppTextStyles.caption.copyWith(color: Colors.white70)),
        const SizedBox(height: 2),
        Text(name,
            style: AppTextStyles.heading2.copyWith(color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        if (unit != null) ...[
          const SizedBox(height: 4),
          Text('Unit ${unit.unitNo} · Floor ${unit.floor}',
              style: AppTextStyles.caption.copyWith(color: Colors.white60)),
        ],
      ])),
      CircleAvatar(
        radius: 22, backgroundColor: Colors.white24,
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    ]),
  );
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value, sub;
  final Color subColor;
  const _StatTile({
    required this.icon, required this.iconColor,
    required this.label, required this.value,
    required this.sub, this.subColor = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: iconColor, size: 22),
      const SizedBox(height: 8),
      Text(value, style: AppTextStyles.heading2.copyWith(fontSize: 20)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
      const SizedBox(height: 2),
      Text(sub, style: AppTextStyles.caption.copyWith(
          color: subColor, fontSize: 10)),
    ]),
  );
}

class _AmountItem extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final bool bold;
  const _AmountItem({
    required this.label, required this.value,
    this.valueColor = AppColors.text, this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(
          fontSize: bold ? 15 : 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          color: valueColor)),
    ],
  );
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
        color: AppColors.slate100, borderRadius: BorderRadius.circular(12)),
  );
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title, sub, date;
  const _ActivityItem({
    required this.icon, required this.color,
    required this.title, required this.sub, required this.date,
  });
}
