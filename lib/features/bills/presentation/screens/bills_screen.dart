import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../data/models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../widgets/bill_card.dart';
import 'bill_detail_screen.dart';
import 'generate_bills_screen.dart';

class BillsScreen extends ConsumerStatefulWidget {
  final bool isAdmin;
  const BillsScreen({super.key, this.isAdmin = false});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.isAdmin ? 3 : 2, vsync: this);
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
        // ── Header ──────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Bills', style: AppTextStyles.heading2),
              if (widget.isAdmin)
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GenerateBillsScreen())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Generate'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                const Tab(text: 'All'),
                const Tab(text: 'Overdue'),
                if (widget.isAdmin) const Tab(text: 'Summary'),
              ],
            ),
          ]),
        ),

        // ── Tab content ──────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _BillsList(filter: null,       isAdmin: widget.isAdmin),
              _BillsList(filter: 'overdue',  isAdmin: widget.isAdmin),
              if (widget.isAdmin) const _CollectionSummaryTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Bills list tab ────────────────────────────────────────────────
class _BillsList extends ConsumerWidget {
  final String? filter;
  final bool isAdmin;
  const _BillsList({this.filter, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = isAdmin
        ? ref.watch(allBillsProvider((month: null, year: null, status: filter)))
        : ref.watch(myBillsProvider);

    return billsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => _ErrorView(e.toString()),
      data:    (bills) {
        final filtered = filter != null
            ? bills.where((b) => b.status.toUpperCase() == filter!.toUpperCase()).toList()
            : bills;

        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: filter == 'overdue' ? 'No overdue bills' : 'No bills yet',
            subtitle: filter == 'overdue'
                ? 'All payments are up to date.'
                : 'Bills will appear here once generated.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myBillsProvider);
            ref.invalidate(allBillsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => BillCard(
              bill: filtered[i],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => BillDetailScreen(billId: filtered[i].billId),
              )),
            ),
          ),
        );
      },
    );
  }
}

// ── Collection summary tab (admin) ────────────────────────────────
class _CollectionSummaryTab extends ConsumerWidget {
  const _CollectionSummaryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now     = DateTime.now();
    final summary = ref.watch(collectionSummaryProvider(
        (month: now.month, year: now.year)));

    return summary.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => _ErrorView(e.toString()),
      data:    (s) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month header
          Row(children: [
            Text('${s.month}/${s.year}', style: AppTextStyles.heading2),
            const SizedBox(width: 8),
            AppBadge(
              label: '${s.collectionPct.toStringAsFixed(1)}% collected',
              color: s.collectionPct >= 80 ? AppColors.success : AppColors.warning,
            ),
          ]),
          const SizedBox(height: 14),

          // Progress bar
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Collection progress', style: AppTextStyles.bodyBold),
              Text('₹${_fmt(s.paidAmount)} / ₹${_fmt(s.paidAmount + s.pendingAmount)}',
                  style: AppTextStyles.caption),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (s.paidAmount + s.pendingAmount) > 0
                    ? s.paidAmount / (s.paidAmount + s.pendingAmount) : 0,
                minHeight: 10,
                backgroundColor: AppColors.slate100,
                color: AppColors.primary,
              ),
            ),
          ])),
          const SizedBox(height: 12),

          // Stat cards
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.6, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(label: 'Total bills',   value: '${s.totalBills}', color: AppColors.primary, icon: Icons.receipt_long_outlined),
              StatCard(label: 'Paid',          value: '${s.paidCount}',  color: AppColors.success,  icon: Icons.check_circle_outline),
              StatCard(label: 'Pending',       value: '${s.pendingCount}', color: AppColors.warning, icon: Icons.pending_outlined),
              StatCard(label: 'Overdue',       value: '${s.overdueCount}', color: AppColors.error,   icon: Icons.warning_amber_outlined),
            ],
          ),
          const SizedBox(height: 12),

          // Amounts
          AppCard(child: Column(children: [
            _AmountRow(label: 'Collected',  amount: s.paidAmount,    color: AppColors.success),
            const Divider(height: 1),
            _AmountRow(label: 'Pending',    amount: s.pendingAmount, color: AppColors.error),
            const Divider(height: 1),
            _AmountRow(
              label: 'Total expected',
              amount: s.paidAmount + s.pendingAmount,
              color: AppColors.primary, bold: true,
            ),
          ])),

          const SizedBox(height: 16),

          // Penalty preview
          const SectionHeader(title: 'Penalty previews'),
          const SizedBox(height: 8),
          _PenaltyPreviewList(),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v >= 100000 ? '${(v/100000).toStringAsFixed(1)}L' : v.toStringAsFixed(0);
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;
  const _AmountRow({required this.label, required this.amount,
      required this.color, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(children: [
      Text(label, style: bold ? AppTextStyles.bodyBold : AppTextStyles.body),
      const Spacer(),
      Text('₹${amount.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color)),
    ]),
  );
}

class _PenaltyPreviewList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(penaltyPreviewProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (_, __) => const SizedBox(),
      data:    (previews) {
        if (previews.isEmpty) {
          return AppCard(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text('No overdue bills — no penalties to apply',
                  style: AppTextStyles.body.copyWith(color: AppColors.success)),
            ]),
          ));
        }
        return Column(children: previews.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Unit ${p['unit_no']}', style: AppTextStyles.bodyBold),
              Text('₹${(p['penalty_amount'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
              child: Text(p['formula'] as String,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11,
                      color: Color(0xFF7DD3FC))),
            ),
          ])),
        )).toList());
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView(this.message);
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 40, color: AppColors.error),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
      ])));
}
