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
        month: DateTime.now().month,
        year:  DateTime.now().year,
        status: null)));

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

          // ── Welcome banner ─────────────────────────────────
          profileAsync.when(
            loading: () => const _Skeleton(height: 90),
            error:   (_, __) => const SizedBox(),
            data: (profile) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: profile.role.toUpperCase() == 'ADMIN'
                      ? [const Color(0xFF7C3AED), const Color(0xFF4C1D95)]
                      : [AppColors.warning, const Color(0xFF92400E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_greeting()}, ${profile.name.split(' ').first} 👋',
                      style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('${_monthName(DateTime.now().month)} ${DateTime.now().year} overview',
                      style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      profile.role.toUpperCase() == 'ADMIN'
                          ? 'Administrator' : 'Management Committee',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ])),
                CircleAvatar(
                  radius: 24, backgroundColor: Colors.white24,
                  child: Text(profile.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── KPI grid ────────────────────────────────────────
          statsAsync.when(
            loading: () => const _Skeleton(height: 200),
            error:   (e, _) => _ErrorCard(message: e.toString()),
            data: (stats) => Column(children: [
              // Row 1
              Row(children: [
                Expanded(child: _KpiTile(
                  icon: Icons.apartment_outlined,
                  color: AppColors.primary,
                  label: 'Total units',
                  value: '${stats.totalUnits}',
                  sub: '${stats.activeUsers} active residents',
                )),
                const SizedBox(width: 10),
                Expanded(child: _KpiTile(
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  label: 'Bills paid',
                  value: '${stats.billsPaid}',
                  sub: stats.totalUnits > 0
                      ? '${(stats.billsPaid / stats.totalUnits * 100).toStringAsFixed(0)}% collection'
                      : '0% collection',
                )),
              ]),
              const SizedBox(height: 10),
              // Row 2
              Row(children: [
                Expanded(child: _KpiTile(
                  icon: Icons.pending_outlined,
                  color: AppColors.error,
                  label: 'Pending bills',
                  value: '${stats.billsPending}',
                  sub: '₹${_fmt(stats.pendingAmount)} outstanding',
                )),
                const SizedBox(width: 10),
                Expanded(child: _KpiTile(
                  icon: Icons.build_circle_outlined,
                  color: AppColors.warning,
                  label: 'Open complaints',
                  value: '${stats.openComplaints}',
                  sub: 'Needs attention',
                )),
              ]),
              const SizedBox(height: 16),

              // ── Collection progress ──────────────────────
              AppCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Collection — ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                      style: AppTextStyles.bodyBold),
                  Text(
                    stats.collectionAmount + stats.pendingAmount > 0
                        ? '${(stats.collectionAmount / (stats.collectionAmount + stats.pendingAmount) * 100).toStringAsFixed(0)}%'
                        : '0%',
                    style: AppTextStyles.bodyBold
                        .copyWith(color: AppColors.primary),
                  ),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stats.collectionAmount + stats.pendingAmount > 0
                        ? stats.collectionAmount /
                            (stats.collectionAmount + stats.pendingAmount)
                        : 0,
                    minHeight: 10,
                    backgroundColor: AppColors.slate100,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _AmountLabel(
                      dot: AppColors.success,
                      label: 'Collected',
                      value: '₹${_fmt(stats.collectionAmount)}')),
                  Expanded(child: _AmountLabel(
                      dot: AppColors.error,
                      label: 'Pending',
                      value: '₹${_fmt(stats.pendingAmount)}')),
                  Expanded(child: _AmountLabel(
                      dot: AppColors.primary,
                      label: 'Target',
                      value: '₹${_fmt(stats.collectionAmount + stats.pendingAmount)}')),
                ]),
              ])),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Pending actions ──────────────────────────────
          paymentsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (payments) {
              final pending = payments
                  .where((p) => p.status.toUpperCase() == 'PENDING').length;
              if (pending == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActionAlert(
                  icon: Icons.verified_outlined,
                  color: AppColors.warning,
                  title: '$pending payment${pending > 1 ? 's' : ''} awaiting verification',
                  sub: 'Review UTR and confirm payments',
                  buttonLabel: 'Review',
                ),
              );
            },
          ),

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
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActionAlert(
                  icon: Icons.build_circle_outlined,
                  color: AppColors.error,
                  title: '$open open complaint${open > 1 ? 's' : ''}',
                  sub: high > 0
                      ? '$high high-priority need immediate attention'
                      : 'Tap to manage and assign',
                  buttonLabel: 'Manage',
                ),
              );
            },
          ),

          billsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (bills) {
              if (bills.isNotEmpty) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActionAlert(
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  title:
                      '${_monthName(DateTime.now().month)} ${DateTime.now().year} bills not generated',
                  sub: 'Generate maintenance bills for all units',
                  buttonLabel: 'Generate',
                ),
              );
            },
          ),

          const SizedBox(height: 6),

          // ── Defaulters ───────────────────────────────────
          billsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (bills) {
              final overdue = bills
                  .where((b) => b.status.toUpperCase() == 'OVERDUE')
                  .toList();
              if (overdue.isEmpty) return const SizedBox();
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Defaulters this month'),
                const SizedBox(height: 10),
                AppCard(child: Column(children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Row(children: [
                      const Expanded(flex: 2, child: Text('Unit / Owner',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted))),
                      const Expanded(child: Text('Amount',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted),
                          textAlign: TextAlign.right)),
                      const Expanded(child: Text('Penalty',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted),
                          textAlign: TextAlign.right)),
                    ]),
                  ),
                  const Divider(height: 1),
                  ...overdue.take(5).map((bill) => Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 2, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Unit ${bill.unitNo ?? '-'}',
                              style: AppTextStyles.bodyBold
                                  .copyWith(fontSize: 13)),
                          Text('₹${bill.total.toStringAsFixed(0)} due',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.error)),
                        ])),
                        Expanded(child: Text(
                            '₹${bill.maintenance.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right)),
                        Expanded(child: Text(
                            bill.penalty > 0
                                ? '₹${bill.penalty.toStringAsFixed(0)}'
                                : '—',
                            style: TextStyle(
                                fontSize: 12,
                                color: bill.penalty > 0
                                    ? AppColors.error
                                    : AppColors.textMuted),
                            textAlign: TextAlign.right)),
                      ]),
                    ),
                    const Divider(height: 1),
                  ])),
                  if (overdue.length > 5)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('+${overdue.length - 5} more defaulters',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center),
                    ),
                ])),
                const SizedBox(height: 16),
              ]);
            },
          ),

          // ── Complaint breakdown ──────────────────────────
          complaintsAsync.when(
            loading: () => const SizedBox(),
            error:   (_, __) => const SizedBox(),
            data: (complaints) {
              if (complaints.isEmpty) return const SizedBox();
              final cats = <String, Map<String, int>>{};
              for (final c in complaints) {
                final cat = c.category.isEmpty ? 'Other'
                    : c.category[0].toUpperCase() +
                        c.category.substring(1).toLowerCase();
                cats.putIfAbsent(cat, () => {'open': 0, 'total': 0});
                cats[cat]!['total'] = cats[cat]!['total']! + 1;
                if (c.status.toUpperCase() != 'RESOLVED' &&
                    c.status.toUpperCase() != 'CLOSED') {
                  cats[cat]!['open'] = cats[cat]!['open']! + 1;
                }
              }
              final colors = [
                AppColors.warning, AppColors.primary, AppColors.error,
                AppColors.success, const Color(0xFF7C3AED),
              ];
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Complaint breakdown'),
                const SizedBox(height: 10),
                AppCard(child: Column(children: [
                  // Table header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Row(children: [
                      const Expanded(flex: 3, child: Text('Category',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted))),
                      const Expanded(child: Text('Total',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted),
                          textAlign: TextAlign.center)),
                      const Expanded(child: Text('Open',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted),
                          textAlign: TextAlign.center)),
                      const Expanded(child: Text('Resolved',
                          style: TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted),
                          textAlign: TextAlign.center)),
                    ]),
                  ),
                  const Divider(height: 1),
                  ...cats.entries.toList().asMap().entries.map((e) {
                    final idx  = e.key;
                    final cat  = e.value.key;
                    final data = e.value.value;
                    final total    = data['total']!;
                    final open     = data['open']!;
                    final resolved = total - open;
                    final color    = colors[idx % colors.length];
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Expanded(flex: 3, child: Row(children: [
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(cat, style: AppTextStyles.bodyBold
                                  .copyWith(fontSize: 13)),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: total > 0 ? resolved / total : 0,
                                  minHeight: 3,
                                  backgroundColor: AppColors.slate100,
                                  color: color,
                                ),
                              ),
                            ])),
                          ])),
                          Expanded(child: Text('$total',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center)),
                          Expanded(child: Text('$open',
                              style: TextStyle(fontSize: 12,
                                  color: open > 0
                                      ? AppColors.error
                                      : AppColors.textMuted,
                                  fontWeight: open > 0
                                      ? FontWeight.w700 : FontWeight.normal),
                              textAlign: TextAlign.center)),
                          Expanded(child: Text('$resolved',
                              style: TextStyle(fontSize: 12,
                                  color: resolved > 0
                                      ? AppColors.success
                                      : AppColors.textMuted),
                              textAlign: TextAlign.center)),
                        ]),
                      ),
                      if (idx < cats.length - 1) const Divider(height: 1),
                    ]);
                  }),
                ])),
                const SizedBox(height: 16),
              ]);
            },
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
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

// ── Widgets ───────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value, sub;
  const _KpiTile({required this.icon, required this.color,
      required this.label, required this.value, required this.sub});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(width: 40, height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AppTextStyles.heading2.copyWith(fontSize: 22)),
        Text(label, style: AppTextStyles.caption),
        Text(sub, style: AppTextStyles.caption.copyWith(
            color: color, fontSize: 10)),
      ])),
    ]),
  );
}

class _AmountLabel extends StatelessWidget {
  final Color dot;
  final String label, value;
  const _AmountLabel({required this.dot, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption),
    ]),
    const SizedBox(height: 2),
    Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
  ]);
}

class _ActionAlert extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title, sub, buttonLabel;
  const _ActionAlert({required this.color, required this.icon,
      required this.title, required this.sub, required this.buttonLabel});
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
        Text(title, style: AppTextStyles.bodyBold
            .copyWith(fontSize: 13, color: color)),
        Text(sub, style: AppTextStyles.caption),
      ])),
      ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(buttonLabel),
      ),
    ]),
  );
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12)),
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
      Expanded(child: Text(message,
          style: AppTextStyles.body.copyWith(color: AppColors.error))),
    ]),
  );
}
