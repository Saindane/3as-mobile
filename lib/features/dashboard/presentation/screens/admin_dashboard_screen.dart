import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';
import '../../../complaints/presentation/providers/complaint_provider.dart';
import '../../../payments/presentation/providers/payment_provider.dart';
import '../../../bills/presentation/providers/bill_provider.dart';
import '../../../bills/data/models/bill_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync      = ref.watch(dashboardStatsProvider);
    final profileAsync    = ref.watch(userProfileProvider);
    final complaintsAsync = ref.watch(complaintsProvider);
    final paymentsAsync   = ref.watch(pendingPaymentsProvider);
    final now             = DateTime.now();

    // Collection summaries for last 6 months
    final summaries = List.generate(6, (i) {
      final dt = DateTime(now.year, now.month - 5 + i);
      return ref.watch(collectionSummaryProvider((month: dt.month, year: dt.year)));
    });

    final billsAsync = ref.watch(allBillsProvider((
        month: now.month, year: now.year, status: null)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(complaintsProvider);
        ref.invalidate(pendingPaymentsProvider);
        ref.invalidate(allBillsProvider);
        ref.invalidate(collectionSummaryProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Header ─────────────────────────────────────────
          profileAsync.when(
            loading: () => const _Skeleton(height: 60),
            error:   (_, __) => const SizedBox(),
            data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_greeting()}, ${profile.name.split(' ').first} 👋',
                  style: AppTextStyles.heading2),
              Text(
                'Full system overview — ${_monthName(now.month)} ${now.year}',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── 4 KPI tiles ────────────────────────────────────
          statsAsync.when(
            loading: () => const _Skeleton(height: 120),
            error:   (e, _) => _ErrorCard(message: e.toString()),
            data: (stats) {
              final collPct = stats.collectionAmount + stats.pendingAmount > 0
                  ? (stats.collectionAmount /
                          (stats.collectionAmount + stats.pendingAmount) *
                          100)
                      .toStringAsFixed(0)
                  : '0';
              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _BigKpiCard(
                    value: '${stats.totalUnits}',
                    label: 'UNITS',
                    sub: '${stats.activeUsers} residents',
                    valueColor: AppColors.text,
                  ),
                  _BigKpiCard(
                    value: '${stats.totalUsers}',
                    label: 'REGISTERED USERS',
                    sub: '${stats.billsPaid} bills paid',
                    valueColor: AppColors.text,
                  ),
                  _BigKpiCard(
                    value: '₹${_fmt(stats.collectionAmount)}',
                    label: 'COLLECTED ${_shortMonth(now.month).toUpperCase()}',
                    sub: '$collPct% of target',
                    valueColor: AppColors.success,
                  ),
                  _BigKpiCard(
                    value: '₹${_fmt(stats.pendingAmount)}',
                    label: 'OUTSTANDING',
                    sub: '${stats.billsPending} units pending',
                    valueColor: AppColors.error,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Collection trend + System health ───────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Monthly collection trend
            Expanded(
              flex: 3,
              child: AppCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Monthly collection trend',
                    style: AppTextStyles.bodyBold),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: _CollectionChart(summaries: summaries, now: now),
                ),
              ])),
            ),

            const SizedBox(width: 12),

            // System health + quick actions
            Expanded(
              flex: 2,
              child: AppCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('System health', style: AppTextStyles.bodyBold),
                const SizedBox(height: 14),
                statsAsync.when(
                  loading: () => const SizedBox(),
                  error:   (_, __) => const SizedBox(),
                  data: (stats) {
                    final collPct = stats.totalUnits > 0
                        ? stats.billsPaid / stats.totalUnits : 0.0;
                    final resPct = complaintsAsync.whenData((c) {
                      if (c.isEmpty) return 1.0;
                      final resolved = c.where((x) =>
                          x.status.toUpperCase() == 'RESOLVED' ||
                          x.status.toUpperCase() == 'CLOSED').length;
                      return resolved / c.length;
                    }).valueOrNull ?? 0.0;
                    final userPct = stats.totalUnits > 0
                        ? (stats.activeUsers / (stats.totalUnits * 1.3))
                            .clamp(0.0, 1.0)
                        : 0.0;
                    return Column(children: [
                      _HealthBar(label: 'Bill collection',
                          value: collPct, color: AppColors.primary),
                      const SizedBox(height: 10),
                      _HealthBar(label: 'Complaint resolution',
                          value: resPct, color: AppColors.warning),
                      const SizedBox(height: 10),
                      _HealthBar(label: 'Residents registered',
                          value: userPct, color: AppColors.success),
                    ]);
                  },
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Generate bills',
                        style: TextStyle(fontSize: 12)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('View reports',
                        style: TextStyle(fontSize: 12)),
                  )),
                ]),
              ])),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Pending actions ───────────────────────────────
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
              if (open == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActionAlert(
                  icon: Icons.build_circle_outlined,
                  color: AppColors.error,
                  title: '$open open complaint${open > 1 ? 's' : ''}',
                  sub: 'Tap to manage and assign',
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
                      '${_monthName(now.month)} ${now.year} bills not generated',
                  sub: 'Generate maintenance bills for all units',
                  buttonLabel: 'Generate',
                ),
              );
            },
          ),

          const SizedBox(height: 6),

          // ── Defaulters table ──────────────────────────────
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
                  _TableHeader(cols: const ['Unit', 'Maintenance', 'Penalty', 'Total']),
                  const Divider(height: 1),
                  ...overdue.take(5).map((bill) => Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Expanded(child: Text('Unit ${bill.unitNo ?? '-'}',
                            style: AppTextStyles.bodyBold.copyWith(fontSize: 13))),
                        Expanded(child: Text(
                            '₹${bill.maintenance.toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12))),
                        Expanded(child: Text(
                            bill.penalty > 0
                                ? '₹${bill.penalty.toStringAsFixed(0)}' : '—',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12,
                                color: bill.penalty > 0
                                    ? AppColors.error : AppColors.textMuted))),
                        Expanded(child: Text(
                            '₹${bill.total.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error))),
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

          // ── Complaint breakdown ────────────────────────────
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
                const SectionHeader(title: 'Complaint analytics'),
                const SizedBox(height: 10),
                AppCard(child: Column(children: [
                  _TableHeader(cols: const ['Category', 'Total', 'Open', 'Resolved']),
                  const Divider(height: 1),
                  ...cats.entries.toList().asMap().entries.map((e) {
                    final idx      = e.key;
                    final cat      = e.value.key;
                    final data     = e.value.value;
                    final total    = data['total']!;
                    final open     = data['open']!;
                    final resolved = total - open;
                    final color    = colors[idx % colors.length];
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Expanded(child: Row(children: [
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(cat,
                                style: AppTextStyles.bodyBold
                                    .copyWith(fontSize: 13))),
                          ])),
                          Expanded(child: Text('$total',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12))),
                          Expanded(child: Text('$open',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12,
                                  color: open > 0
                                      ? AppColors.error : AppColors.textMuted,
                                  fontWeight: open > 0
                                      ? FontWeight.w700 : FontWeight.normal))),
                          Expanded(child: Text('$resolved',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12,
                                  color: resolved > 0
                                      ? AppColors.success
                                      : AppColors.textMuted))),
                        ]),
                      ),
                      if (idx < cats.length - 1) const Divider(height: 1),
                    ]);
                  }),
                ])),
                const SizedBox(height: 20),
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
}

// ── Helpers ───────────────────────────────────────────────────────
String _monthName(int m) => const [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
][m];

String _shortMonth(int m) => const [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
][m];

String _fmt(double v) {
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000)   return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}

// ── Widgets ───────────────────────────────────────────────────────

class _BigKpiCard extends StatelessWidget {
  final String value, label, sub;
  final Color valueColor;
  const _BigKpiCard({required this.value, required this.label,
      required this.sub, required this.valueColor});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w700, color: valueColor)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: AppColors.textMuted, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(sub, style: TextStyle(
          fontSize: 12, color: valueColor == AppColors.text
              ? AppColors.success : valueColor)),
    ]),
  );
}

class _HealthBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _HealthBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.body.copyWith(fontSize: 13)),
      Text('${(value * 100).toStringAsFixed(0)}%',
          style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
    ]),
    const SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: AppColors.slate100,
        color: color,
      ),
    ),
  ]);
}

class _CollectionChart extends StatelessWidget {
  final List<AsyncValue<CollectionSummary>> summaries;
  final DateTime now;
  const _CollectionChart({required this.summaries, required this.now});

  @override
  Widget build(BuildContext context) {
    // Build 6-month data
    final data = <({String label, double pct, bool isCurrent})>[];
    for (int i = 0; i < 6; i++) {
      final dt  = DateTime(now.year, now.month - 5 + i);
      final sum = summaries[i].valueOrNull;
      final pct = sum != null
          ? sum.collectionPct.clamp(0.0, 1.0)
          : 0.0;
      data.add((
        label: _shortMonth(dt.month),
        pct: pct,
        isCurrent: dt.month == now.month && dt.year == now.year,
      ));
    }

    final maxPct = data.fold(0.0, (m, d) => d.pct > m ? d.pct : m);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) => Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (d.pct > 0)
            Text('${(d.pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: d.isCurrent ? AppColors.primary : AppColors.textMuted)),
          const SizedBox(height: 4),
          Expanded(
            child: Align(alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 28,
                height: maxPct > 0
                    ? (d.pct / maxPct * 90).clamp(4, 90)
                    : 4,
                decoration: BoxDecoration(
                  color: d.isCurrent
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(.35),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(d.label, style: TextStyle(
              fontSize: 10,
              color: d.isCurrent ? AppColors.primary : AppColors.textMuted,
              fontWeight: d.isCurrent ? FontWeight.w700 : FontWeight.normal)),
        ]),
      )).toList(),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> cols;
  const _TableHeader({required this.cols});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(children: cols.asMap().entries.map((e) => Expanded(
      child: Text(e.value, textAlign: e.key == 0
          ? TextAlign.left : e.key == cols.length - 1
              ? TextAlign.right : TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.textMuted)),
    )).toList()),
  );
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
        Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: color)),
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
        color: AppColors.slate100, borderRadius: BorderRadius.circular(12)));
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: AppColors.errorLight, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: AppTextStyles.body.copyWith(color: AppColors.error))),
    ]),
  );
}
