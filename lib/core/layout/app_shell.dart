import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../layout/responsive.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../router/app_router.dart';
import '../../features/notices/presentation/providers/notice_provider.dart';
import '../../features/notices/data/models/notice_model.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}

// ── Resident nav: 6 items (index 0–5) ────────────────────────────
const _residentNav = [
  NavItem(icon: Icons.home_outlined,         activeIcon: Icons.home,          label: 'Home',       index: 0),
  NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,  label: 'Bills',      index: 1),
  NavItem(icon: Icons.payment_outlined,      activeIcon: Icons.payment,       label: 'Pay now',    index: 2),
  NavItem(icon: Icons.build_circle_outlined, activeIcon: Icons.build_circle,  label: 'Complaints', index: 3),
  NavItem(icon: Icons.campaign_outlined,     activeIcon: Icons.campaign,      label: 'Notices',    index: 4),
  NavItem(icon: Icons.person_outline,        activeIcon: Icons.person,        label: 'Profile',    index: 5),
];

// ── Management nav: 8 items (index 0–7, no Settings) ────────────
const _managementNav = [
  NavItem(icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard,     label: 'Dashboard',   index: 0),
  NavItem(icon: Icons.people_outline,        activeIcon: Icons.people,        label: 'Users',       index: 1),
  NavItem(icon: Icons.apartment_outlined,    activeIcon: Icons.apartment,     label: 'Properties',  index: 2),
  NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,  label: 'Billing',     index: 3),
  NavItem(icon: Icons.verified_outlined,     activeIcon: Icons.verified,      label: 'Payments',    index: 4),
  NavItem(icon: Icons.build_circle_outlined, activeIcon: Icons.build_circle,  label: 'Complaints',  index: 5),
  NavItem(icon: Icons.campaign_outlined,     activeIcon: Icons.campaign,      label: 'Notices',     index: 6),
  NavItem(icon: Icons.bar_chart_outlined,    activeIcon: Icons.bar_chart,     label: 'Reports',     index: 7),
];

// ── Admin nav: 9 items (index 0–8) ───────────────────────────────
const _adminNav = [
  NavItem(icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard,     label: 'Dashboard',   index: 0),
  NavItem(icon: Icons.people_outline,        activeIcon: Icons.people,        label: 'Users',       index: 1),
  NavItem(icon: Icons.apartment_outlined,    activeIcon: Icons.apartment,     label: 'Properties',  index: 2),
  NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,  label: 'Billing',     index: 3),
  NavItem(icon: Icons.verified_outlined,     activeIcon: Icons.verified,      label: 'Payments',    index: 4),
  NavItem(icon: Icons.build_circle_outlined, activeIcon: Icons.build_circle,  label: 'Complaints',  index: 5),
  NavItem(icon: Icons.campaign_outlined,     activeIcon: Icons.campaign,      label: 'Notices',     index: 6),
  NavItem(icon: Icons.bar_chart_outlined,    activeIcon: Icons.bar_chart,     label: 'Reports',     index: 7),
  NavItem(icon: Icons.settings_outlined,     activeIcon: Icons.settings,      label: 'Settings',    index: 8),
];

class AppShell extends ConsumerStatefulWidget {
  final List<Widget> pages;
  final bool isPrivileged;
  final String userName;
  final String userRole;

  const AppShell({
    super.key,
    required this.pages,
    required this.isPrivileged,
    required this.userName,
    required this.userRole,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  List<NavItem> get _navItems =>
      widget.userRole.toUpperCase() == 'ADMIN' ? _adminNav
          : widget.isPrivileged ? _managementNav
          : _residentNav;

  Color get _roleColor => switch (widget.userRole.toUpperCase()) {
        'ADMIN'      => AppColors.error,
        'MANAGEMENT' => AppColors.warning,
        _            => AppColors.primary,
      };

  String get _roleLabel => switch (widget.userRole.toUpperCase()) {
        'ADMIN'      => 'Administrator',
        'MANAGEMENT' => 'Management',
        _            => 'Resident',
      };

  Widget get _currentPage {
    if (_selectedIndex < widget.pages.length) {
      return widget.pages[_selectedIndex];
    }
    return const Center(child: Text('Coming soon'));
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile:  _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // ── Desktop sidebar layout ────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(children: [
        // Sidebar
        Container(
          width: 240,
          color: AppColors.surface,
          child: Column(children: [
            // Brand
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.apartment, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('3As Complex',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  Text('Management System',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ]),
              ]),
            ),

            // User chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _roleColor.withOpacity(.15),
                  child: Text(
                    widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                    style: TextStyle(color: _roleColor, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.userName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.text), overflow: TextOverflow.ellipsis),
                  Text(_roleLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ])),
              ]),
            ),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Text('MENU', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: .8)),
                  ),
                  ..._navItems.map((item) => _SidebarItem(
                    item:     item,
                    selected: _selectedIndex == item.index,
                    onTap:    () => setState(() => _selectedIndex = item.index),
                  )),
                ],
              ),
            ),

            // Sign out
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.logout, color: AppColors.error, size: 18),
                title: const Text('Sign out', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w500, color: AppColors.error)),
                onTap: _signOut,
              ),
            ),
          ]),
        ),

        Container(width: 1, color: AppColors.border),

        // Main content
        Expanded(
          child: Column(children: [
            // Top bar
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(children: [
                Text(
                  _navItems.firstWhere((n) => n.index == _selectedIndex,
                      orElse: () => _navItems.first).label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.text),
                ),
                const Spacer(),
                _RoleSwitcher(currentRole: widget.userRole),
                const SizedBox(width: 8),
                Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () => _showNotifications(context),
                  ),
                  Positioned(top: 8, right: 8,
                    child: Container(width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.error, shape: BoxShape.circle))),
                ]),
              ]),
            ),
            Expanded(child: _currentPage),
          ]),
        ),
      ]),
    );
  }

  // ── Mobile bottom nav layout ──────────────────────────────────
  Widget _buildMobileLayout() {
    // Mobile shows max 5 nav items
    final mobileItems = _navItems.take(5).toList();
    final clampedIndex = _selectedIndex.clamp(0, mobileItems.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.apartment, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          const Text('3As Complex'),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _roleColor.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
            child: Text(_roleLabel,
                style: TextStyle(color: _roleColor, fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
          Stack(children: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => _showNotifications(context)),
            Positioned(top: 8, right: 8,
              child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle))),
          ]),
        ],
      ),
      body: _currentPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: clampedIndex,
        onTap: (i) => setState(() => _selectedIndex = mobileItems[i].index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: mobileItems.map((item) => BottomNavigationBarItem(
          icon:       Icon(item.icon),
          activeIcon: Icon(item.activeIcon),
          label:      item.label,
        )).toList(),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _NotificationsSheet(),
    );
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider).logout();
  }
}

// ── Sidebar nav item ──────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    selected: selected,
    selectedTileColor: AppColors.primaryLight,
    selectedColor: AppColors.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    leading: Icon(selected ? item.activeIcon : item.icon, size: 18,
        color: selected ? AppColors.primary : AppColors.textSecondary),
    title: Text(item.label, style: TextStyle(
      fontSize: 13,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      color: selected ? AppColors.primary : AppColors.textSecondary,
    )),
    onTap: onTap,
  );
}

// ── Role switcher ─────────────────────────────────────────────────
class _RoleSwitcher extends StatelessWidget {
  final String currentRole;
  const _RoleSwitcher({required this.currentRole});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _RoleBtn(label: 'Resident',   active: currentRole == 'RESIDENT'),
        _RoleBtn(label: 'Management', active: currentRole == 'MANAGEMENT'),
        _RoleBtn(label: 'Admin',      active: currentRole == 'ADMIN'),
      ]),
    );
  }
}

class _RoleBtn extends StatelessWidget {
  final String label;
  final bool active;
  const _RoleBtn({required this.label, required this.active});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(.08),
          blurRadius: 4, offset: const Offset(0, 1))] : [],
    ),
    child: Text(label, style: TextStyle(
      fontSize: 12,
      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      color: active ? AppColors.primary : AppColors.textMuted,
    )),
  );
}

// ── Notifications sheet ───────────────────────────────────────────
class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Notices', style: AppTextStyles.heading3),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: noticesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline,
                        size: 36, color: AppColors.error),
                    const SizedBox(height: 8),
                    Text(e.toString(), textAlign: TextAlign.center,
                        style: AppTextStyles.body),
                  ]),
                ),
              ),
              data: (notices) {
                if (notices.isEmpty) {
                  return const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.notifications_none_outlined,
                          size: 48, color: AppColors.textMuted),
                      SizedBox(height: 10),
                      Text('No notices yet',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ]),
                  );
                }
                return ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: notices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _NoticeItem(notice: notices[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeItem extends StatelessWidget {
  final NoticeModel notice;
  const _NoticeItem({required this.notice});

  Color get _priorityColor => switch (notice.priority.toLowerCase()) {
        'urgent' => AppColors.error,
        'high'   => AppColors.warning,
        _        => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _priorityColor.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.campaign_outlined,
                color: _priorityColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notice.title,
                    style: AppTextStyles.bodyBold
                        .copyWith(fontSize: 13)),
                const SizedBox(height: 3),
                Text(notice.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Row(children: [
                  if (notice.authorName != null) ...[
                    Text(notice.authorName!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary)),
                    const Text(' · ',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                  Text(_formatDate(notice.createdAt),
                      style: AppTextStyles.caption),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt  = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0)    return 'Today';
      if (diff.inDays == 1)    return 'Yesterday';
      if (diff.inDays < 7)     return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }
}
