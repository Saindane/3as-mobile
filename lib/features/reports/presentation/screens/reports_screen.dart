import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';

// ── Providers ─────────────────────────────────────────────────────

final collectionReportProvider =
    FutureProvider.family<Map<String, dynamic>, ({int month, int year})>(
        (ref, p) async {
  final client = ref.watch(dioClientProvider);
  final res = await client.get('${ApiEndpoints.reports}/collection',
      queryParameters: {'month': p.month, 'year': p.year});
  return res.data as Map<String, dynamic>;
});

final defaulterReportProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final res = await client.get('${ApiEndpoints.reports}/defaulters');
  return res.data as Map<String, dynamic>;
});

final complaintAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final res = await client.get('${ApiEndpoints.reports}/complaints');
  return res.data as Map<String, dynamic>;
});

// ── Screen ────────────────────────────────────────────────────────

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MIS Reports', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabs,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Collection'),
                Tab(text: 'Defaulters'),
                Tab(text: 'Complaints'),
              ],
            ),
          ]),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _CollectionTab(month: _month, year: _year,
                  onMonthYear: (m, y) => setState(() { _month = m; _year = y; })),
              const _DefaultersTab(),
              const _ComplaintAnalyticsTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Collection tab ────────────────────────────────────────────────
class _CollectionTab extends ConsumerWidget {
  final int month, year;
  final void Function(int, int) onMonthYear;
  const _CollectionTab({required this.month, required this.year, required this.onMonthYear});

  static const _months = ['', 'Jan','Feb','Mar','Apr','May','Jun',
                              'Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(collectionReportProvider((month: month, year: year)));

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Month/year selector
      Row(children: [
        Expanded(child: DropdownButtonFormField<int>(
          value: month,
          decoration: const InputDecoration(
            labelText: 'Month',
            filled: true, fillColor: AppColors.slate100,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: List.generate(12, (i) => DropdownMenuItem(
            value: i + 1, child: Text(_months[i + 1]))),
          onChanged: (v) => onMonthYear(v!, year),
        )),
        const SizedBox(width: 10),
        Expanded(child: DropdownButtonFormField<int>(
          value: year,
          decoration: const InputDecoration(
            labelText: 'Year',
            filled: true, fillColor: AppColors.slate100,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [2024, 2025, 2026].map((y) =>
              DropdownMenuItem(value: y, child: Text('$y'))).toList(),
          onChanged: (v) => onMonthYear(month, v!),
        )),
      ]),
      const SizedBox(height: 16),

      reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorCard(e.toString()),
        data: (report) => Column(children: [
          // Progress bar
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_months[month]} $year', style: AppTextStyles.bodyBold),
              Text('${report['collection_pct']}%',
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (report['collection_pct'] as num).toDouble() / 100,
                minHeight: 8,
                backgroundColor: AppColors.slate100,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('₹${report['paid_amount']} collected',
                  style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              Text('₹${report['pending_amount']} pending',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            ]),
          ])),
          const SizedBox(height: 10),

          // Stat cards
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.6, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(label: 'Total bills',  value: '${report['total_bills']}',
                  color: AppColors.primary, icon: Icons.receipt_long_outlined),
              StatCard(label: 'Paid',         value: '${report['paid_count']}',
                  color: AppColors.success,  icon: Icons.check_circle_outline),
              StatCard(label: 'Pending',      value: '${report['pending_count']}',
                  color: AppColors.warning,  icon: Icons.pending_outlined),
              StatCard(label: 'Overdue',      value: '${report['overdue_count']}',
                  color: AppColors.error,    icon: Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: 10),

          // Bill list
          if ((report['bills'] as List).isNotEmpty)
            AppCard(child: Column(
              children: (report['bills'] as List).take(10).map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Unit ${b['unit_no']}', style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                    Text(b['owner'] as String, style: AppTextStyles.caption),
                  ])),
                  Text('₹${b['total']}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  AppBadge(
                    label: (b['status'] as String)[0].toUpperCase() +
                           (b['status'] as String).substring(1),
                    color: b['status'] == 'paid' ? AppColors.success
                         : b['status'] == 'overdue' ? AppColors.error
                         : AppColors.warning,
                  ),
                ]),
              )).toList(),
            )),
        ]),
      ),
    ]);
  }
}

// ── Defaulters tab ────────────────────────────────────────────────
class _DefaultersTab extends ConsumerWidget {
  const _DefaultersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(defaulterReportProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: _ErrorCard(e.toString())),
      data: (report) {
        final defaulters = report['defaulters'] as List;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(child: StatCard(
              label: 'Total defaulters',
              value: '${report['total_defaulters']}',
              color: AppColors.error, icon: Icons.warning_amber_outlined,
            )),
            const SizedBox(width: 10),
            Expanded(child: StatCard(
              label: 'Total outstanding',
              value: '₹${report['total_outstanding']}',
              color: AppColors.error, icon: Icons.payments_outlined,
            )),
          ]),
          const SizedBox(height: 14),
          if (defaulters.isEmpty)
            const EmptyState(icon: Icons.check_circle_outline,
                title: 'No defaulters', subtitle: 'All bills are paid!')
          else
            ...defaulters.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Unit ${d['unit_no']}', style: AppTextStyles.bodyBold),
                    Text(d['owner'] as String, style: AppTextStyles.caption),
                    Text('+91 ${d['mobile']}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${d['total']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.error)),
                    Text('${d['month']}/${d['year']}', style: AppTextStyles.caption),
                    AppBadge(label: d['status'] as String, color: AppColors.error),
                  ]),
                ]),
                if ((d['penalty'] as num) > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight, borderRadius: BorderRadius.circular(6)),
                    child: Text('Penalty: ₹${d['penalty']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ])),
            )),
        ]);
      },
    );
  }
}

// ── Complaint analytics tab ───────────────────────────────────────
class _ComplaintAnalyticsTab extends ConsumerWidget {
  const _ComplaintAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(complaintAnalyticsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: _ErrorCard(e.toString())),
      data: (report) {
        final categories = report['by_category'] as List;
        return ListView(padding: const EdgeInsets.all(16), children: [
          GridView.count(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: 1.2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(label: 'Total',    value: '${report['total']}',
                  color: AppColors.primary, icon: Icons.list_alt_outlined),
              StatCard(label: 'Open',     value: '${report['open']}',
                  color: AppColors.warning, icon: Icons.pending_outlined),
              StatCard(label: 'Resolved', value: '${report['resolved']}',
                  color: AppColors.success, icon: Icons.check_circle_outline),
            ],
          ),
          const SizedBox(height: 14),
          const SectionHeader(title: 'By category'),
          const SizedBox(height: 8),
          AppCard(child: Column(
            children: categories.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    (c['category'] as String).replaceAll('_', ' ').toUpperCase(),
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 12),
                  ),
                  Text('${c['resolved']}/${c['total']} resolved',
                      style: AppTextStyles.caption),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c['total'] > 0
                        ? (c['resolved'] as num) / (c['total'] as num)
                        : 0,
                    minHeight: 6,
                    backgroundColor: AppColors.slate100,
                    color: AppColors.primary,
                  ),
                ),
              ]),
            )).toList(),
          )),
        ]);
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.errorLight, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.error),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: const TextStyle(color: AppColors.error, fontSize: 13))),
    ]),
  );
}
