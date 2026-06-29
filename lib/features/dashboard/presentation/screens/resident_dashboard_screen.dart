import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';

class ResidentDashboardScreen extends ConsumerWidget {
  const ResidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final propAsync    = ref.watch(myPropertyProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(myPropertyProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Welcome banner ───────────────────────────────
          profileAsync.when(
            loading: () => const _WelcomeSkeleton(),
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
                  Text('Good morning,', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(profile.name, style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  propAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (prop) => prop != null
                        ? Text('Unit ${prop.unitNo} · Floor ${prop.floor}',
                            style: AppTextStyles.caption.copyWith(color: Colors.white70))
                        : const SizedBox(),
                  ),
                ])),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // ── Quick stats ──────────────────────────────────
          const SectionHeader(title: 'This month'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.6, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: const [
              StatCard(label: 'Amount due',     value: '₹2,450', color: AppColors.error,   icon: Icons.receipt_long_outlined, subtitle: 'Overdue'),
              StatCard(label: 'Months paid',    value: '4',      color: AppColors.success,  icon: Icons.check_circle_outline),
              StatCard(label: 'Open complaint', value: '1',      color: AppColors.warning,  icon: Icons.build_circle_outlined),
              StatCard(label: 'New notices',    value: '2',      color: AppColors.primary,  icon: Icons.campaign_outlined),
            ],
          ),

          const SizedBox(height: 20),

          // ── Overdue bill alert ───────────────────────────
          AppCard(
            borderColor: AppColors.error,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('June 2025 bill', style: AppTextStyles.bodyBold),
                const AppBadge(label: 'Overdue', color: AppColors.error),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _MiniStat(label: 'Maintenance', value: '₹2,000')),
                Expanded(child: _MiniStat(label: 'Penalty', value: '₹450', valueColor: AppColors.error)),
                Expanded(child: _MiniStat(label: 'Total', value: '₹2,450', valueColor: AppColors.error)),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'Penalty = ₹2,000 × 0.05% × 45 days = ₹450',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF7DD3FC)),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Pay now'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                )),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('View bill'),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Quick actions ────────────────────────────────
          const SectionHeader(title: 'Quick actions'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _ActionTile(icon: Icons.qr_code_scanner, label: 'Pay now',      color: AppColors.success,  onTap: () {})),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(icon: Icons.build_circle_outlined, label: 'Raise issue', color: AppColors.warning, onTap: () {})),
            const SizedBox(width: 10),
            Expanded(child: _ActionTile(icon: Icons.campaign_outlined, label: 'Notices',    color: AppColors.primary,  onTap: () {})),
          ]),

          const SizedBox(height: 20),

          // ── Recent activity ──────────────────────────────
          const SectionHeader(title: 'Recent activity'),
          const SizedBox(height: 10),
          AppCard(child: Column(children: [
            _ActivityRow(icon: Icons.warning_amber_rounded, color: AppColors.error,
                title: 'Bill generated — June 2025', sub: '₹2,450 due · 3 days ago'),
            const Divider(height: 1),
            _ActivityRow(icon: Icons.check_circle_outline, color: AppColors.success,
                title: 'Payment verified — May 2025', sub: '₹2,000 confirmed · 12 days ago'),
            const Divider(height: 1),
            _ActivityRow(icon: Icons.build_circle_outlined, color: AppColors.warning,
                title: 'Complaint #038 assigned', sub: 'Plumbing team · 7 days ago'),
            const Divider(height: 1),
            _ActivityRow(icon: Icons.campaign_outlined, color: AppColors.primary,
                title: 'Notice: AGM June 28', sub: 'Community hall 6 PM · 5 days ago'),
          ])),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _WelcomeSkeleton extends StatelessWidget {
  const _WelcomeSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 80, decoration: BoxDecoration(
      color: AppColors.slate100, borderRadius: BorderRadius.circular(14)));
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _MiniStat({required this.label, required this.value, this.valueColor = AppColors.text});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor)),
    Text(label, style: AppTextStyles.caption),
  ]);
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        border: Border.all(color: color.withOpacity(.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  const _ActivityRow({required this.icon, required this.color, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(color: color.withOpacity(.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 17)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        Text(sub, style: AppTextStyles.caption),
      ])),
    ]),
  );
}
