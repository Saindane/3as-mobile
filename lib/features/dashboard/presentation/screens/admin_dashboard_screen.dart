import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';
import '../../../complaints/presentation/providers/complaint_provider.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../../../bills/presentation/providers/bill_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync      = ref.watch(dashboardStatsProvider);
    final profileAsync    = ref.watch(userProfileProvider);
    final complaintsAsync = ref.watch(complaintsProvider);
    final paymentsAsync   = ref.watch(pendingPaymentsProvider);
    final billsAsync      = ref.watch(allBillsProvider((
        month: DateTime.now().month, year: DateTime.now().year)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(complaintsProvider);
        ref.invalidate(pendingPaymentsProvider);
        ref.invalidate(allBillsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Welcome banner ─────────────────────────────
          profileAsync.when(
            loading: () => const SizedBox(height: 80),
            error:   (e, _) => const SizedBox(),
            data: (profile) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: profile.role == 'ADMIN'
                      ? [const Color(0xFF7C3AED), const Color(0xFF4C1D95)]
                      : [AppColors.warning, const Color(0xFF92400E)],
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      profile.role == 'ADMIN' ? 'Administrator' : 'Management Committee',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ])),
                CircleAvatar(
                  radius: 24, backgroundColor: Colors.white24,
                  child: Text(profile.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── KPI stats ──────────────────────────────────
          SectionHeader(
              title: '${_monthName(DateTime.now().month)} ${DateTime.now().year} overview'),
          const SizedBox(height: 10),
          statsAsync.when(
            loading: () => const _StatsGridSkeleton(),
            error:   (e, _) => _ErrorCard(
                message: 'Could not load stats. ${e.toString()}'),
            data: (stats) => Column(children: [
              GridView.count(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                childAspectRatio: 1.55, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(label: 'Total units',
                      value: '${stats.totalUnits}',
                      color: AppColors.primary,
                      icon: Icons.apartment_outlined),
                  StatCard(label: 'Active users',
                      value: '${stats.activeUsers}',
                      color: AppColors.success,
                      icon: Icons.people_outline),
                  StatCard(label: 'Bills pending',
                      value: '${stats.billsPending}',
                      color: AppColors.error,
                      icon: Icons.receipt_long_outlined,
                      subtitle: 'Unpaid'),
                  StatCard(label: 'Open complaints',
                      value: '${stats.openComplaints}',
                      color: AppColors.warning,
                      icon: Icons.build_circle_outlined),
                ],
              ),

              const SizedBox(height: 12),

              // Collection bar — real data
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    'Collection — ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                    style: AppTextStyles.bodyBold,
                  ),
                  Text(
                    '${stats.collectionAmount > 0 && (stats.collectionAmount + stats.pendingAmount) > 0
                        ? (stats.collectionAmount / (stats.collectionAmount + stats.pendingAmount) * 100).toStringAsFixed(0)
                        : 0}%',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                  ),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.collectionAmount > 0 &&
                            (stats.collectionAmount + stats.pendingAmount) > 0
                        ? stats.collectionAmount /
                            (stats.collectionAmount + stats.pendingAmount)
                        : 0,
                    minHeight: 8,
                    backgroundColor: AppColors.slate100,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('₹${_fmt(stats.collectionAmount)} collected',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success)),
                  Text('₹${_fmt(stats.pendingAmount)} pending',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error)),
                ]),
              ])),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Pending actions — real data ─────────────────
          const SectionHeader(title: 'Pending actions'),
          const SizedBox(height: 10),

          // Payments awaiting verification
          paymentsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (payments) {
              final pending = payments
                  .where((p) => p['status']?.toString().toUpperCase() == 'PENDING')
                  .length;
              if (pending == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionAlert(
                  color: AppColors.warning,
                  icon: Icons.verified_outlined,
                  title: '$pending payment${pending > 1 ? 's' : ''} awaiting verification',
                  sub: 'UTR submitted by residents',
                  buttonLabel: 'Review',
                  onTap: () {},
                ),
              );
            },
          ),

          // Open complaints
          complaintsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (complaints) {
              final open = complaints.where((c) =>
                  c.status.toUpperCase() != 'RESOLVED' &&
                  c.status.toUpperCase() != 'CLOSED').length;
              final high = complaints.where((c) =>
                  c.priority.toUpperCase() == 'HIGH' &&
                  c.status.toUpperCase() != 'RESOLVED' &&
                  c.status.toUpperCase() != 'CLOSED').length;
              if (open == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActionAlert(
                  color: AppColors.error,
                  icon: Icons.build_circle_outlined,
                  title: '$open open complaint${open > 1 ? 's' : ''}',
                  sub: high > 0
                      ? '$high high-priority need${high > 1 ? '' : 's'} assignment'
                      : 'Tap to manage',
                  buttonLabel: 'Manage',
                  onTap: () {},
                ),
              );
            },
          ),

          // Bills not generated this month
          billsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (bills) {
              final month = _monthName(DateTime.now().month);
              final year  = DateTime.now().year;
              if (bills.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ActionAlert(
                    color: AppColors.primary,
                    icon: Icons.receipt_long_outlined,
                    title: '$month $year bills not generated',
                    sub: 'Generate maintenance bills for all units',
                    buttonLabel: 'Generate',
                    onTap: () {},
                  ),
                );
              }
              return const SizedBox();
            },
          ),

          const SizedBox(height: 20),

          // ── Complaint breakdown — real data ─────────────
          complaintsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (complaints) {
              if (complaints.isEmpty) return const SizedBox();

              // Group by category
              final categories = <String, Map<String, int>>{};
              for (final c in complaints) {
                final cat = c.category.isNotEmpty
                    ? c.category[0].toUpperCase() +
                        c.category.substring(1).toLowerCase()
                    : 'Other';
                categories.putIfAbsent(cat, () => {'open': 0, 'total': 0});
                categories[cat]!['total'] = categories[cat]!['total']! + 1;
                if (c.status.toUpperCase() != 'RESOLVED' &&
                    c.status.toUpperCase() != 'CLOSED') {
                  categories[cat]!['open'] = categories[cat]!['open']! + 1;
                }
              }

              if (categories.isEmpty) return const SizedBox();

              final colors = [
                AppColors.warning, AppColors.primary, AppColors.error,
                AppColors.success, const Color(0xFF7C3AED),
              ];

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Complaint breakdown'),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    children: categories.entries.toList().asMap().entries.map((e) {
                      final idx      = e.key;
                      final category = e.value.key;
                      final data     = e.value.value;
                      final total    = data['total']!;
                      final open     = data['open']!;
                      final resolved = total - open;
                      final color    = colors[idx % colors.length];
                      return Column(children: [
                        if (idx > 0) const Divider(height: 1),
                        _ComplaintRow(
                          category: category,
                          open:     open,
                          resolved: resolved,
                          total:    total,
                          color:    color,
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ]);
            },
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

String _monthName(int m) => const [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
][m];

// ── Sub-widgets ────────────────────────────────────────────────────

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
    childAspectRatio: 1.55, shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: List.generate(4, (_) => Container(
        decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(12)))),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
      const SizedBox(width: 8),
      Expanded(
          child: Text(message,
              style: AppTextStyles.body.copyWith(color: AppColors.error))),
    ]),
  );
}

class _ActionAlert extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title, sub, buttonLabel;
  final VoidCallback onTap;
  const _ActionAlert({
    required this.color, required this.icon,
    required this.title, required this.sub,
    required this.buttonLabel, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(.06),
      border: Border.all(color: color.withOpacity(.25)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: color)),
        Text(sub, style: AppTextStyles.caption),
      ])),
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(buttonLabel),
      ),
    ]),
  );
}

class _ComplaintRow extends StatelessWidget {
  final String category;
  final int open, resolved, total;
  final Color color;
  const _ComplaintRow({
    required this.category, required this.open,
    required this.resolved, required this.total, required this.color,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(category,
            style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? resolved / total : 0,
            minHeight: 4,
            backgroundColor: AppColors.slate100,
            color: color,
          ),
        ),
      ])),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$resolved/$total',
            style: AppTextStyles.bodyBold
                .copyWith(fontSize: 12, color: color)),
        Text(open > 0 ? '$open open' : 'all resolved',
            style: AppTextStyles.caption),
      ]),
    ]),
  );
}
