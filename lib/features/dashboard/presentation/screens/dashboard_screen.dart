import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../providers/dashboard_provider.dart';
import 'admin_dashboard_screen.dart';
import 'resident_dashboard_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data:    (profile) {
        final isPrivileged = profile.role == 'admin' || profile.role == 'management';
        final pages = isPrivileged
            ? [const AdminDashboardScreen(), const _UsersScreen(), const _PropertiesScreen(), const ProfileScreen()]
            : [const ResidentDashboardScreen(), const _ComingSoon('Bills'), const _ComingSoon('Complaints'), const ProfileScreen()];
        final navItems = isPrivileged
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.people_outline),     activeIcon: Icon(Icons.people),    label: 'Users'),
                BottomNavigationBarItem(icon: Icon(Icons.apartment_outlined), activeIcon: Icon(Icons.apartment), label: 'Properties'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline),     activeIcon: Icon(Icons.person),    label: 'Profile'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined),           activeIcon: Icon(Icons.home),           label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined),   activeIcon: Icon(Icons.receipt_long),   label: 'Bills'),
                BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined),   activeIcon: Icon(Icons.build_circle),   label: 'Issues'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline),          activeIcon: Icon(Icons.person),         label: 'Profile'),
              ];

        final roleColor = profile.role == 'admin' ? AppColors.error
            : profile.role == 'management' ? AppColors.warning : AppColors.primary;
        final roleLabel = profile.role[0].toUpperCase() + profile.role.substring(1);

        return Scaffold(
          appBar: AppBar(
            title: Row(children: [
              Container(width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.apartment, color: Colors.white, size: 16)),
              const SizedBox(width: 8),
              const Text('3As Complex'),
            ]),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                child: Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
            ],
          ),
          body: pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            items: navItems,
          ),
        );
      },
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String name;
  const _ComingSoon(this.name);
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.construction_outlined, size: 48, color: AppColors.textMuted),
    const SizedBox(height: 12),
    Text('$name — coming in next sprint!', style: AppTextStyles.heading3, textAlign: TextAlign.center),
  ]));
}

class _UsersScreen extends ConsumerWidget {
  const _UsersScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(usersListProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (users) => ListView(padding: const EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('All users', style: AppTextStyles.heading2),
          AppBadge(label: '${users.length} total', color: AppColors.primary),
        ]),
        const SizedBox(height: 14),
        ...users.map((u) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _UserTile(u))),
      ]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserTile(this.user);
  @override
  Widget build(BuildContext context) {
    final role   = user['role'] as String;
    final active = user['is_active'] as bool;
    final color  = role == 'admin' ? AppColors.error : role == 'management' ? AppColors.warning : AppColors.primary;
    return AppCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
      CircleAvatar(backgroundColor: color.withOpacity(.12),
        child: Text((user['name'] as String)[0].toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.w700))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user['name'] as String, style: AppTextStyles.bodyBold),
        Text('+91 ${user['mobile']}', style: AppTextStyles.caption),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        AppBadge(label: role[0].toUpperCase() + role.substring(1), color: color),
        const SizedBox(height: 4),
        AppBadge(label: active ? 'Active' : 'Inactive', color: active ? AppColors.success : AppColors.textMuted),
      ]),
    ]));
  }
}

class _PropertiesScreen extends ConsumerWidget {
  const _PropertiesScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(propertiesListProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (props) => ListView(padding: const EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Properties', style: AppTextStyles.heading2),
          AppBadge(label: '${props.length} units', color: AppColors.primary),
        ]),
        const SizedBox(height: 14),
        ...props.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _PropTile(p))),
      ]),
    );
  }
}

class _PropTile extends StatelessWidget {
  final Map<String, dynamic> prop;
  const _PropTile(this.prop);
  @override
  Widget build(BuildContext context) {
    final owner = prop['owner'] as Map<String, dynamic>?;
    return AppCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
      Container(width: 42, height: 42,
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.apartment, color: AppColors.primary, size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Unit ${prop['unit_no']}', style: AppTextStyles.bodyBold),
        Text('Floor ${prop['floor']}${prop['area_sqft'] != null ? ' · ${prop['area_sqft']} sq ft' : ''}', style: AppTextStyles.caption),
        if (owner != null) Text('Owner: ${owner['name']}', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
      ])),
      AppBadge(label: (prop['type'] as String? ?? 'residential').toUpperCase(), color: AppColors.primary),
    ]));
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final propAsync    = ref.watch(myPropertyProvider);
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (profile) {
        final roleColor = profile.role == 'admin' ? AppColors.error
            : profile.role == 'management' ? AppColors.warning : AppColors.primary;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: Column(children: [
            CircleAvatar(radius: 36, backgroundColor: AppColors.primaryLight,
              child: Text(profile.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary))),
            const SizedBox(height: 10),
            Text(profile.name, style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            AppBadge(label: profile.role[0].toUpperCase() + profile.role.substring(1), color: roleColor),
          ])),
          const SizedBox(height: 24),
          AppCard(child: Column(children: [
            _InfoRow(icon: Icons.phone_outlined,  label: 'Mobile', value: '+91 ${profile.mobile}'),
            if (profile.email != null) ...[const Divider(height: 1), _InfoRow(icon: Icons.email_outlined, label: 'Email', value: profile.email!)],
            ...propAsync.whenData((prop) {
              if (prop == null) return <Widget>[];
              return [
                const Divider(height: 1),
                _InfoRow(icon: Icons.apartment_outlined, label: 'Unit',  value: 'Unit ${prop.unitNo}'),
                const Divider(height: 1),
                _InfoRow(icon: Icons.layers_outlined,    label: 'Floor', value: 'Floor ${prop.floor}'),
                if (prop.areaSqft != null) ...[
                  const Divider(height: 1),
                  _InfoRow(icon: Icons.square_foot_outlined, label: 'Area', value: '${prop.areaSqft} sq ft'),
                ],
              ];
            }).value ?? <Widget>[],
          ])),
          const SizedBox(height: 12),
          AppCard(child: Column(children: [
            ListTile(dense: true, leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: const Text('Change password'), trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted), onTap: () {}),
            const Divider(height: 1),
            ListTile(dense: true, leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              title: const Text('Notification settings'), trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted), onTap: () {}),
          ])),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error), minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ]);
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textMuted), const SizedBox(width: 10),
      Text('$label  ', style: AppTextStyles.caption),
      Expanded(child: Text(value, style: AppTextStyles.bodyBold, textAlign: TextAlign.right)),
    ]));
}
