import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../data/models/complaint_model.dart';
import '../providers/complaint_provider.dart';
import '../../data/repositories/complaint_repository.dart';
import 'raise_complaint_screen.dart';

class ComplaintsScreen extends ConsumerStatefulWidget {
  final bool isAdmin;
  const ComplaintsScreen({super.key, this.isAdmin = false});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Complaints', style: AppTextStyles.heading2),
              // Only residents can raise complaints
              if (!widget.isAdmin)
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const RaiseComplaintScreen()));
                    ref.invalidate(complaintsProvider);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Raise'),
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
              tabs: const [Tab(text: 'All'), Tab(text: 'Open'), Tab(text: 'Resolved')],
            ),
          ]),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _ComplaintList(filter: null,       isAdmin: widget.isAdmin),
              _ComplaintList(filter: 'OPEN',     isAdmin: widget.isAdmin),
              _ComplaintList(filter: 'RESOLVED', isAdmin: widget.isAdmin),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ComplaintList extends ConsumerWidget {
  final String? filter;
  final bool isAdmin;
  const _ComplaintList({this.filter, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(complaintsProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (complaints) {
        final filtered = filter == null ? complaints
            : filter == 'OPEN'     ? complaints.where((c) => c.isOpen).toList()
            : complaints.where((c) => c.isResolved).toList();

        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.build_circle_outlined,
            title: filter == 'OPEN' ? 'No open complaints' : 'No complaints found',
            subtitle: filter == 'OPEN'
                ? 'All issues have been resolved.'
                : 'Raise a complaint using the button above.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(complaintsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => ComplaintCard(
              complaint: filtered[i],
              isAdmin: isAdmin,
              onUpdate: () => ref.invalidate(complaintsProvider),
            ),
          ),
        );
      },
    );
  }
}

class ComplaintCard extends ConsumerWidget {
  final ComplaintModel complaint;
  final bool isAdmin;
  final VoidCallback? onUpdate;

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.isAdmin = false,
    this.onUpdate,
  });

  Color get _priorityColor => switch (complaint.priority) {
        'high'   => AppColors.error,
        'medium' => AppColors.warning,
        _        => AppColors.success,
      };

  Color get _statusColor => switch (complaint.status) {
        'NEW'         => AppColors.primary,
        'ASSIGNED'    => AppColors.warning,
        'IN_PROGRESS' => AppColors.warning,
        'RESOLVED'    => AppColors.success,
        'CLOSED'      => AppColors.textMuted,
        _             => AppColors.textMuted,
      };

  String get _statusLabel => switch (complaint.status) {
        'NEW'         => 'New',
        'ASSIGNED'    => 'Assigned',
        'IN_PROGRESS' => 'In progress',
        'RESOLVED'    => 'Resolved',
        'CLOSED'      => 'Closed',
        _             => complaint.status,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _priorityColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.build_circle_outlined, color: _priorityColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(complaint.title, style: AppTextStyles.bodyBold,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              '#${complaint.complaintId} · ${complaint.category}'
              '${complaint.unitNo != null ? ' · Unit ${complaint.unitNo}' : ''}',
              style: AppTextStyles.caption,
            ),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AppBadge(label: _statusLabel, color: _statusColor),
            const SizedBox(height: 4),
            AppBadge(
              label: complaint.priority[0].toUpperCase() + complaint.priority.substring(1),
              color: _priorityColor,
            ),
          ]),
        ]),

        // Lifecycle steps
        const SizedBox(height: 10),
        _LifecycleSteps(status: complaint.status),

        if (complaint.description != null) ...[
          const SizedBox(height: 8),
          Text(complaint.description!, style: AppTextStyles.caption,
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],

        // Admin actions
        if (isAdmin && complaint.isOpen) ...[
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(children: [
            if (complaint.status.toUpperCase() == 'NEW')
              Expanded(child: _ActionBtn(
                label: 'Assign',
                color: AppColors.primary,
                icon: Icons.person_add_outlined,
                onTap: () async {
                  await ref.read(complaintRepositoryProvider)
                      .update(complaint.complaintId, {'status': 'ASSIGNED'});
                  onUpdate?.call();
                },
              )),
            if (complaint.status.toUpperCase() == 'ASSIGNED' || complaint.status.toUpperCase() == 'IN_PROGRESS')
              Expanded(child: _ActionBtn(
                label: 'Mark In Progress',
                color: AppColors.warning,
                icon: Icons.engineering_outlined,
                onTap: () async {
                  await ref.read(complaintRepositoryProvider)
                      .update(complaint.complaintId, {'status': 'IN_PROGRESS'});
                  onUpdate?.call();
                },
              )),
            const SizedBox(width: 8),
            Expanded(child: _ActionBtn(
              label: 'Resolve',
              color: AppColors.success,
              icon: Icons.check_circle_outline,
              onTap: () async {
                await ref.read(complaintRepositoryProvider)
                    .update(complaint.complaintId, {'status': 'RESOLVED', 'resolution': 'Issue resolved by maintenance team'});
                onUpdate?.call();
              },
            )),
          ]),
        ],
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color,
      required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 14, color: color),
    label: Text(label, style: TextStyle(fontSize: 11, color: color)),
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: color),
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class _LifecycleSteps extends StatelessWidget {
  final String status;
  const _LifecycleSteps({required this.status});

  static const _steps = ['NEW', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED'];

  int get _currentIdx => _steps.indexOf(status).clamp(0, _steps.length - 1);

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(_steps.length * 2 - 1, (i) {
      if (i.isOdd) {
        final stepIdx = i ~/ 2;
        return Expanded(child: Container(
          height: 2,
          color: stepIdx < _currentIdx ? AppColors.primary : AppColors.border,
        ));
      }
      final stepIdx = i ~/ 2;
      final done    = stepIdx <= _currentIdx;
      return Container(
        width: 18, height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: done ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: done
            ? const Icon(Icons.check, size: 10, color: Colors.white)
            : null,
      );
    }));
  }
}
