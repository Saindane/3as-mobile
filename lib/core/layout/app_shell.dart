import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../layout/responsive.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';

/// Navigation item definition
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

const _residentNav = [
  NavItem(icon: Icons.home_outlined,         activeIcon: Icons.home,          label: 'Dashboard', index: 0),
  NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,  label: 'Bills',     index: 1),
  NavItem(icon: Icons.payment_outlined,      activeIcon: Icons.payment,       label: 'Pay now',   index: 2),
  NavItem(icon: Icons.build_circle_outlined, activeIcon: Icons.build_circle,  label: 'Complaints',index: 3),
  NavItem(icon: Icons.campaign_outlined,     activeIcon: Icons.campaign,      label: 'Notices',   index: 4),
  NavItem(icon: Icons.person_outline,        activeIcon: Icons.person,        label: 'Profile',   index: 5),
];

const _adminNav = [
  NavItem(icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard,     label: 'Dashboard', index: 0),
  NavItem(icon: Icons.people_outline,        activeIcon: Icons.people,        label: 'Users',     index: 1),
  NavItem(icon: Icons.apartment_outlined,    activeIcon: Icons.apartment,     label: 'Properties',index: 2),
  NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,  label: 'Billing',   index: 3),
  NavItem(icon: Icons.verified_outlined,     activeIcon: Icons.verified,      label: 'Payments',  index: 4),
  NavItem(icon: Icons.bar_chart_outlined,    activeIcon: Icons.bar_chart,     label: 'Reports',   index: 5),
  NavItem(icon: Icons.settings_outlined,     activeIcon: Icons.settings,      label: 'Settings',  index: 6),
];

/// The main shell that switches between:
///   - Desktop: persistent left sidebar + content area
///   - Mobile:  app bar + bottom navigation bar
class AppShell extends ConsumerStatefulWidget {
  final List<Widget> pages;
  final bool isPrivileged;      // admin or management
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
      widget.isPrivileged ? _adminNav : _residentNav;

  Color get _roleColor => switch (widget.userRole) {
        'admin'      => AppColors.error,
        'management' => AppColors.warning,
        _            => AppColors.primary,
      };

  String get _roleLabel => switch (widget.userRole) {
        'admin'      => 'Administrator',
        'management' => 'Management',
        _            => 'Resident',
      };

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile:  _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // ── Desktop layout: sidebar + content ────────────────────────────
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────
          Container(
            width: 240,
            color: AppColors.surface,
            child: Column(
              children: [
                // Brand
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.apartment, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('3As Complex',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                      Text('Management System',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ]),
                  ]),
                ),

                // User chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 18, backgroundColor: _roleColor.withOpacity(.15),
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
                        child: Text('MENU', style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.textMuted, letterSpacing: .8)),
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
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: const Icon(Icons.logout, color: AppColors.error, size: 18),
                    title: const Text('Sign out',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                            color: AppColors.error)),
                    onTap: _signOut,
                  ),
                ),
              ],
            ),
          ),

          // ── Vertical divider ─────────────────────────────
          Container(width: 1, color: AppColors.border),

          // ── Main content ─────────────────────────────────
          Expanded(
            child: Column(
              children: [
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
                    // Role switcher (web/desktop only — for demo)
                    _RoleSwitcher(
                      currentRole: widget.userRole,
                      onRoleChange: _changeRoleDemo,
                    ),
                    const SizedBox(width: 8),
                    // Notifications
                    Stack(children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                        onPressed: () {},
                      ),
                      Positioned(top: 8, right: 8,
                        child: Container(width: 8, height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.error, shape: BoxShape.circle))),
                    ]),
                  ]),
                ),
                // Page content
                Expanded(
                  child: _selectedIndex < widget.pages.length
                      ? widget.pages[_selectedIndex]
                      : const Center(child: Text('Coming soon')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile layout: AppBar + BottomNavigationBar ───────────────────
  Widget _buildMobileLayout() {
    // Mobile shows max 5 nav items (bottom nav limit)
    final mobileItems = _navItems.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
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
                style: TextStyle(color: _roleColor, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          Stack(children: [
            IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            Positioned(top: 8, right: 8,
              child: Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))),
          ]),
        ],
      ),
      body: _selectedIndex < widget.pages.length
          ? widget.pages[_selectedIndex]
          : const Center(child: Text('Coming soon')),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex.clamp(0, mobileItems.length - 1),
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

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).logout();
    if (mounted) context.go('/login');
  }

  void _changeRoleDemo(String role) {
    // For demo: invalidate profile so the screen rebuilds with new role context
    ref.invalidate(userProfileProvider);
  }
}

// ── Sidebar nav item ──────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      selectedTileColor: AppColors.primaryLight,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(
        selected ? item.activeIcon : item.icon,
        size: 18,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ── Role switcher (desktop topbar) ────────────────────────────────
class _RoleSwitcher extends StatelessWidget {
  final String currentRole;
  final void Function(String) onRoleChange;

  const _RoleSwitcher({required this.currentRole, required this.onRoleChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _RoleBtn(label: 'Resident',   active: currentRole == 'resident',   onTap: () => onRoleChange('resident')),
        _RoleBtn(label: 'Management', active: currentRole == 'management', onTap: () => onRoleChange('management')),
        _RoleBtn(label: 'Admin',      active: currentRole == 'admin',      onTap: () => onRoleChange('admin')),
      ]),
    );
  }
}

class _RoleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RoleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(.08),
            blurRadius: 4, offset: const Offset(0, 1))] : [],
      ),
      child: Text(label,
        style: TextStyle(
          fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? AppColors.primary : AppColors.textMuted,
        )),
    ),
  );
}
