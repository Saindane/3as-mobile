import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';
import '../../../bills/presentation/providers/bill_provider.dart';
import '../../../bills/data/models/bill_model.dart';
import '../../../complaints/presentation/providers/complaint_provider.dart';
import '../../../notices/presentation/providers/notice_provider.dart';

class ResidentDashboardScreen extends ConsumerWidget {
  const ResidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync   = ref.watch(userProfileProvider);
    final propAsync      = ref.watch(myPropertyProvider);
    final billsAsync     = ref.watch(myBillsProvider);
    final complaintsAsync = ref.watch(complaintsProvider);
    final noticesAsync   = ref.watch(noticesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(myPropertyProvider);
        ref.invalidate(myBillsProvider);
        ref.invalidate(complaintsProvider);
        ref.invalidate(noticesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Welcome banner ────────────────────────────────
          profileAsync.when(
            loading: () => const _Skeleton(height: 90),
            error:   (e, _) => const SizedBox(),
            data: (profile) => Container(
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
                  Text('Welcome back,',
                      style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(profile.name,
                      style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  propAsync.when(
                    loading: () => const SizedBox(),
                    error:   (_, __) => const SizedBox(),
                    data: (prop) => prop != null
                        ? Text('Unit ${prop.unitNo} · Floor ${prop.floor}',
                            style: AppTextStyles.caption.copyWith(color: Colors.white70))
                        : Text('No property assigned',
                            style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                  ),
                ])),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Stats from real data ──────────────────────────
          const SectionHeader(title: 'Overview'),
          const SizedBox(height: 10),
          billsAsync.when(
            loading: () => const _Skeleton(height: 100),
            error:   (_, __) => const SizedBox(),
            data: (bills) {
              final pending = bills.where((b) =>
                  b.status.toUpperCase() == 'PENDING' ||
                  b.status.toUpperCase() == 'OVERDUE').toList();
              final paid   = bills.where((b) =>
                  b.status.toUpperCase() == 'PAID').toList();
              final totalDue = pending.fold(0.0, (sum, b) => sum + b.total);

              return GridView.count(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                childAspectRatio: 1.6, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    label: 'Amount due',
                    value: totalDue > 0 ? '₹${totalDue.toStringAsFixed(0)}' : '₹0',
                    color: totalDue > 0 ? AppColors.error : AppColors.success,
                    icon: Icons.receipt_long_outlined,
                    subtitle: pending.isNotEmpty ? 'Unpaid bills' : 'All clear',
                  ),
                  StatCard(
                    label: 'Bills paid',
                    value: '${paid.length}',
                    color: AppColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                  complaintsAsync.when(
                    loading: () => const StatCard(
                        label: 'Complaints', value: '-',
                        color: AppColors.warning, icon: Icons.build_circle_outlined),
                    error: (_, __) => const StatCard(
                        label: 'Complaints', value: '-',
                        color: AppColors.warning, icon: Icons.build_circle_outlined),
                    data: (complaints) => StatCard(
                      label: 'Open complaints',
                      value: '${complaints.where((c) => c.status.toUpperCase() != 'RESOLVED' && c.status.toUpperCase() != 'CLOSED').length}',
                      color: AppColors.warning,
                      icon: Icons.build_circle_outlined,
                    ),
                  ),
                  noticesAsync.when(
                    loading: () => const StatCard(
                        label: 'Notices', value: '-',
                        color: AppColors.primary, icon: Icons.campaign_outlined),
                    error: (_, __) => const StatCard(
                        label: 'Notices', value: '-',
                        color: AppColors.primary, icon: Icons.campaign_outlined),
                    data: (notices) => StatCard(
                      label: 'Notices',
                      value: '${notices.length}',
                      color: AppColors.primary,
                      icon: Icons.campaign_outlined,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Pending bills ─────────────────────────────────
          billsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (bills) {
              final pending = bills.where((b) =>
                  b.status.toUpperCase() == 'PENDING' ||
                  b.status.toUpperCase() == 'OVERDUE').toList();
              if (pending.isEmpty) return const SizedBox();

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Pending bills'),
                const SizedBox(height: 10),
                ...pending.map((bill) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    borderColor: bill.status.toUpperCase() == 'OVERDUE'
                        ? AppColors.error : AppColors.warning,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${_monthName(bill.month)} ${bill.year}',
                            style: AppTextStyles.bodyBold),
                        AppBadge(
                          label: bill.status[0].toUpperCase() +
                              bill.status.substring(1).toLowerCase(),
                          color: bill.status.toUpperCase() == 'OVERDUE'
                              ? AppColors.error : AppColors.warning,
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _MiniStat(
                            label: 'Maintenance',
                            value: '₹${bill.maintenance.toStringAsFixed(0)}')),
                        if (bill.penalty > 0)
                          Expanded(child: _MiniStat(
                              label: 'Penalty',
                              value: '₹${bill.penalty.toStringAsFixed(0)}',
                              valueColor: AppColors.error)),
                        Expanded(child: _MiniStat(
                            label: 'Total',
                            value: '₹${bill.total.toStringAsFixed(0)}',
                            valueColor: AppColors.error)),
                      ]),
                    ]),
                  ),
                )),
              ]);
            },
          ),

          const SizedBox(height: 20),

          // ── Recent complaints ─────────────────────────────
          complaintsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (complaints) {
              if (complaints.isEmpty) return const SizedBox();
              final recent = complaints.take(3).toList();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Recent complaints'),
                const SizedBox(height: 10),
                AppCard(child: Column(children: [
                  ...recent.asMap().entries.map((e) => Column(children: [
                    if (e.key > 0) const Divider(height: 1),
                    _ActivityRow(
                      icon: Icons.build_circle_outlined,
                      color: AppColors.warning,
                      title: e.value.title,
                      sub: e.value.status[0].toUpperCase() +
                          e.value.status.substring(1).toLowerCase(),
                    ),
                  ])),
                ])),
              ]);
            },
          ),

          const SizedBox(height: 20),

          // ── Recent notices ────────────────────────────────
          noticesAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (notices) {
              if (notices.isEmpty) return const SizedBox();
              final recent = notices.take(3).toList();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Recent notices'),
                const SizedBox(height: 10),
                AppCard(child: Column(children: [
                  ...recent.asMap().entries.map((e) => Column(children: [
                    if (e.key > 0) const Divider(height: 1),
                    _ActivityRow(
                      icon: Icons.campaign_outlined,
                      color: AppColors.primary,
                      title: e.value.title,
                      sub: e.value.category ?? 'General',
                    ),
                  ])),
                ])),
              ]);
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _monthName(int m) => [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.slate100, borderRadius: BorderRadius.circular(14)),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _MiniStat({required this.label, required this.value,
      this.valueColor = AppColors.text});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
            color: valueColor)),
    Text(label, style: AppTextStyles.caption),
  ]);
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  const _ActivityRow({required this.icon, required this.color,
      required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(
            color: color.withOpacity(.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 17)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        Text(sub, style: AppTextStyles.caption),
      ])),
    ]),
  );
}
