import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../data/models/notice_model.dart';
import '../providers/notice_provider.dart';
import '../../data/repositories/notice_repository.dart';
import '../../../../core/constants/api_endpoints.dart';

class NoticesScreen extends ConsumerStatefulWidget {
  final bool isAdmin;
  const NoticesScreen({super.key, this.isAdmin = false});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notices', style: AppTextStyles.heading2),
                if (widget.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _showPublishSheet(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Publish'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────
          Expanded(
            child: noticesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 40, color: AppColors.error),
                      const SizedBox(height: 10),
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(noticesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (notices) {
                if (notices.isEmpty) {
                  return const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No notices yet',
                    subtitle: 'Society announcements will appear here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(noticesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notices.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _NoticeCard(
                      notice: notices[i],
                      isAdmin: widget.isAdmin,
                      currentUserId: TokenStore.userId,
                      onRefresh: () => ref.invalidate(noticesProvider),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPublishSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _PublishNoticeSheet(),
    ).then((_) => ref.invalidate(noticesProvider));
  }
}

// ── Notice card ───────────────────────────────────────────────────
class _NoticeCard extends ConsumerWidget {
  final NoticeModel notice;
  final bool isAdmin;
  final int? currentUserId;
  final VoidCallback onRefresh;

  const _NoticeCard({
    required this.notice,
    required this.onRefresh,
    this.isAdmin = false,
    this.currentUserId,
  });

  Color get _priorityColor => switch (notice.priority.toLowerCase()) {
        'urgent' => AppColors.error,
        'high'   => AppColors.warning,
        _        => AppColors.primary,
      };

  // Show 3-dot menu only to admin OR the notice creator
  bool get _canModify =>
      isAdmin || (currentUserId != null && currentUserId == notice.createdBy);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored stripe
            Container(width: 4, color: _priorityColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: AppTextStyles.bodyBold,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppBadge(
                          label: notice.priority[0].toUpperCase() +
                              notice.priority.substring(1),
                          color: _priorityColor,
                        ),
                        // 3-dot menu for admin/creator only
                        if (_canModify)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                size: 18, color: AppColors.textMuted),
                            onSelected: (action) => _handleAction(
                                context, ref, action),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined,
                                      size: 16, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline,
                                      size: 16, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(
                                          color: AppColors.error)),
                                ]),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Body
                    Text(
                      notice.body,
                      style: AppTextStyles.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Footer
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(notice.authorName ?? 'Admin',
                            style: AppTextStyles.caption),
                        const Spacer(),
                        if (notice.category != null) ...[
                          AppBadge(
                              label: notice.category!,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                        ],
                        Text(_formatDate(notice.createdAt),
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    if (action == 'edit') {
      showDialog(
        context: context,
        builder: (_) => _EditNoticeDialog(
          notice: notice,
          onSuccess: onRefresh,
        ),
      );
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete notice'),
          content:
              Text('Delete "${notice.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirm == true && context.mounted) {
        try {
          await ref
              .read(noticeRepositoryProvider)
              .deleteNotice(notice.noticeId);
          onRefresh();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Notice deleted'),
              backgroundColor: AppColors.error,
            ));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ));
          }
        }
      }
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }
}

// ── Edit Notice Dialog ────────────────────────────────────────────
class _EditNoticeDialog extends ConsumerStatefulWidget {
  final NoticeModel notice;
  final VoidCallback onSuccess;
  const _EditNoticeDialog({required this.notice, required this.onSuccess});

  @override
  ConsumerState<_EditNoticeDialog> createState() =>
      _EditNoticeDialogState();
}

class _EditNoticeDialogState extends ConsumerState<_EditNoticeDialog> {
  late final TextEditingController _titleCtr;
  late final TextEditingController _bodyCtr;
  late String _priority;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtr = TextEditingController(text: widget.notice.title);
    _bodyCtr  = TextEditingController(text: widget.notice.body);
    _priority = widget.notice.priority;
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _bodyCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtr.text.trim().isEmpty || _bodyCtr.text.trim().isEmpty) {
      setState(() => _error = 'Title and body are required');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final client = ref.read(dioClientProvider);
      await client.patch(
        '${ApiEndpoints.notices}/${widget.notice.noticeId}',
        data: {
          'title':    _titleCtr.text.trim(),
          'body':     _bodyCtr.text.trim(),
          'priority': _priority,
        },
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Notice updated'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit notice',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
    content: SizedBox(
      width: 400,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Color(0xFFDC2626))),
              ),
            TextField(
              controller: _titleCtr,
              decoration: const InputDecoration(
                  labelText: 'Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtr,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Body', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                  labelText: 'Priority', border: OutlineInputBorder()),
              items: ['normal', 'high', 'urgent']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text('Save'),
      ),
    ],
  );
}

// ── Publish notice sheet ──────────────────────────────────────────
class _PublishNoticeSheet extends ConsumerStatefulWidget {
  const _PublishNoticeSheet();
  @override
  ConsumerState<_PublishNoticeSheet> createState() =>
      _PublishNoticeSheetState();
}

class _PublishNoticeSheetState extends ConsumerState<_PublishNoticeSheet> {
  final _titleCtr  = TextEditingController();
  final _bodyCtr   = TextEditingController();
  String _category = 'general';
  String _priority = 'normal';

  @override
  void dispose() {
    _titleCtr.dispose();
    _bodyCtr.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_titleCtr.text.trim().isEmpty || _bodyCtr.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill title and body'),
          backgroundColor: AppColors.error));
      return;
    }
    await ref.read(publishNoticeProvider.notifier).publish(
          title:    _titleCtr.text.trim(),
          body:     _bodyCtr.text.trim(),
          category: _category,
          priority: _priority,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publishNoticeProvider);

    ref.listen(publishNoticeProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Notice published'),
            backgroundColor: AppColors.success));
        Navigator.pop(context);
        ref.read(publishNoticeProvider.notifier).reset();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error));
      }
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Publish notice', style: AppTextStyles.heading3),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtr,
            decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bodyCtr,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Body', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder()),
                  items: [
                    'general', 'maintenance', 'finance',
                    'security', 'emergency',
                  ]
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder()),
                  items: ['normal', 'high', 'urgent']
                      .map((p) =>
                          DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _priority = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: state.isLoading ? null : _publish,
            icon: state.isLoading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, size: 16),
            label: Text(
                state.isLoading ? 'Publishing...' : 'Publish & notify all'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
          ),
        ],
      ),
    );
  }
}
