import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync   = ref.watch(dashboardStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(userProfileProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Welcome banner ───────────────────────────────
          profileAsync.when(
            loading: () => const SizedBox(height: 80),
            error:   (e, _) => const SizedBox(),
            data: (profile) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: profile.role == 'admin'
                      ? [const Color(0xFF7C3AED), const Color(0xFF4C1D95)]
                      : [AppColors.warning, const Color(0xFF92400E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Welcome back,', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(profile.name, style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      profile.role == 'admin' ? 'Administrator' : 'Management Committee',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                ])),
                CircleAvatar(
                  radius: 24, backgroundColor: Colors.white24,
                  child: Text(profile.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── KPI stats ────────────────────────────────────
          const SectionHeader(title: 'June 2025 overview'),
          const SizedBox(height: 10),
          statsAsync.when(
            loading: () => const _StatsGridSkeleton(),
            error:   (e, _) => _ErrorCard(message: e.toString()),
            data: (stats) => Column(children: [
              GridView.count(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                childAspectRatio: 1.55, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(label: 'Total units',    value: '${stats.totalUnits}',      color: AppColors.primary, icon: Icons.apartment_outlined),
                  StatCard(label: 'Active users',   value: '${stats.activeUsers}',     color: AppColors.success, icon: Icons.people_outline),
                  StatCard(label: 'Bills pending',  value: '${stats.billsPending}',    color: AppColors.error,   icon: Icons.receipt_long_outlined, subtitle: 'Unpaid'),
                  StatCard(label: 'Open complaints',value: '${stats.openComplaints}',  color: AppColors.warning, icon: Icons.build_circle_outlined),
                ],
              ),

              const SizedBox(height: 12),

              // Collection bar
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Collection — June 2025', style: AppTextStyles.bodyBold),
                  Text(
                    '${stats.collectionAmount > 0 && (stats.collectionAmount + stats.pendingAmount) > 0
                        ? (stats.collectionAmount / (stats.collectionAmount + stats.pendingAmount) * 100).toStringAsFixed(0)
                        : 75}%',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                  ),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.collectionAmount > 0
                        ? stats.collectionAmount / (stats.collectionAmount + stats.pendingAmount)
                        : 0.75,
                    minHeight: 8,
                    backgroundColor: AppColors.slate100,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('₹${_fmt(stats.collectionAmount)} collected',
                      style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                  Text('₹${_fmt(stats.pendingAmount)} pending',
                      style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                ]),
              ])),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Pending actions ──────────────────────────────
          const SectionHeader(title: 'Pending actions'),
          const SizedBox(height: 10),
          _ActionAlert(
            color: AppColors.warning,
            icon: Icons.verified_outlined,
            title: '3 payments awaiting verification',
            sub: 'UTR submitted by residents',
            buttonLabel: 'Review',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _ActionAlert(
            color: AppColors.error,
            icon: Icons.build_circle_outlined,
            title: '5 open complaints',
            sub: '1 high-priority needs assignment',
            buttonLabel: 'Manage',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _ActionAlert(
            color: AppColors.primary,
            icon: Icons.receipt_long_outlined,
            title: 'July bills not generated',
            sub: 'Generate for all 48 units',
            buttonLabel: 'Generate',
            onTap: () {},
          ),

          const SizedBox(height: 20),

          // ── Quick links ──────────────────────────────────
          const SectionHeader(title: 'Quick links'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: 1.1, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickLink(icon: Icons.file_download_outlined, label: 'Collection\nReport',  color: AppColors.success, onTap: () {}),
              _QuickLink(icon: Icons.warning_amber_outlined, label: 'Defaulter\nList',     color: AppColors.error,   onTap: () {}),
              _QuickLink(icon: Icons.analytics_outlined,    label: 'Complaint\nAnalysis',  color: AppColors.warning, onTap: () {}),
              _QuickLink(icon: Icons.campaign_outlined,     label: 'Post\nNotice',         color: AppColors.primary, onTap: () {}),
              _QuickLink(icon: Icons.person_add_outlined,   label: 'Add\nUser',            color: const Color(0xFF7C3AED), onTap: () {}),
              _QuickLink(icon: Icons.settings_outlined,     label: 'Settings',             color: AppColors.textSecondary, onTap: () {}),
            ],
          ),

          const SizedBox(height: 20),

          // ── Complaint breakdown ───────────────────────────
          const SectionHeader(title: 'Complaint breakdown'),
          const SizedBox(height: 10),
          AppCard(child: Column(children: [
            _ComplaintRow(category: 'Electrical', open: 2, resolved: 6, total: 8,   color: AppColors.warning),
            const Divider(height: 1),
            _ComplaintRow(category: 'Plumbing',   open: 3, resolved: 9, total: 12,  color: AppColors.primary),
            const Divider(height: 1),
            _ComplaintRow(category: 'Civil',      open: 1, resolved: 3, total: 4,   color: AppColors.error),
            const Divider(height: 1),
            _ComplaintRow(category: 'Security',   open: 0, resolved: 5, total: 5,   color: AppColors.success),
            const Divider(height: 1),
            _ComplaintRow(category: 'Housekeeping', open: 1, resolved: 8, total: 9, color: const Color(0xFF7C3AED)),
          ])),

          const SizedBox(height: 20),
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

// ── Sub-widgets ───────────────────────────────────────────────────

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
    childAspectRatio: 1.55, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    children: List.generate(4, (_) => Container(
      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(12)))),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: AppTextStyles.body.copyWith(color: AppColors.error))),
    ]),
  );
}

class _ActionAlert extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title, sub, buttonLabel;
  final VoidCallback onTap;
  const _ActionAlert({required this.color, required this.icon, required this.title,
      required this.sub, required this.buttonLabel, required this.onTap});
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
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(buttonLabel),
      ),
    ]),
  );
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        border: Border.all(color: color.withOpacity(.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

class _ComplaintRow extends StatelessWidget {
  final String category;
  final int open, resolved, total;
  final Color color;
  const _ComplaintRow({required this.category, required this.open,
      required this.resolved, required this.total, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(category, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? resolved / total : 0,
            minHeight: 4, backgroundColor: AppColors.slate100, color: color,
          ),
        ),
      ])),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$resolved/$total', style: AppTextStyles.bodyBold.copyWith(fontSize: 12, color: color)),
        Text(open > 0 ? '$open open' : 'all resolved', style: AppTextStyles.caption),
      ]),
    ]),
  );
}
