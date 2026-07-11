import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../bills/presentation/screens/bills_screen.dart';
import '../../../payments/presentation/screens/payments_screen.dart';
import '../../../complaints/presentation/screens/complaints_screen.dart';
import '../../../notices/presentation/screens/notices_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/router/app_router.dart';
import 'admin_dashboard_screen.dart';
import 'resident_dashboard_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
          const SizedBox(height: 16),
          const Text('Could not load profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(userProfileProvider),
            child: const Text('Retry'),
          ),
        ]),
      ))),
      data: (profile) {
        final isPrivileged = profile.role == 'ADMIN' || profile.role == 'MANAGEMENT';

        // Build pages list — index matches NavItem.index in AppShell
        final isAdmin = profile.role == 'ADMIN';
        final pages = isPrivileged
            ? [
                const AdminDashboardScreen(),              // 0 - Dashboard
                const _UsersPage(),                        // 1 - Users
                const _PropertiesPage(),                   // 2 - Properties
                const BillsScreen(isAdmin: true),          // 3 - Billing
                const PaymentsScreen(isAdmin: true),       // 4 - Payments
                const ComplaintsScreen(isAdmin: true),     // 5 - Complaints
                const NoticesScreen(isAdmin: true),        // 6 - Notices
                const ReportsScreen(),                     // 7 - Reports
                if (isAdmin) const SettingsScreen(),       // 8 - Settings (Admin only)
              ]
            : [
                const ResidentDashboardScreen(),         // 0 - Home
                const BillsScreen(isAdmin: false),       // 1 - Bills
                const PaymentsScreen(isAdmin: false),    // 2 - Pay now
                const ComplaintsScreen(isAdmin: false),  // 3 - Complaints
                const NoticesScreen(isAdmin: false),     // 4 - Notices
                const ProfileScreen(),                   // 5 - Profile
              ];

        return AppShell(
          pages:        pages,
          isPrivileged: isPrivileged,
          userName:     profile.name,
          userRole:     profile.role,
        );
      },
    );
  }
}

// ── Coming soon placeholder ───────────────────────────────────────
class _ComingSoon extends StatelessWidget {
  final String name;
  const _ComingSoon(this.name);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.construction_outlined, color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: 16),
        Text('$name', style: AppTextStyles.heading2),
        const SizedBox(height: 6),
        Text('This module will be implemented in the next sprint.',
            style: AppTextStyles.body, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
          child: const Text('Coming soon',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ]),
    ),
  );
}

// ── Users page ────────────────────────────────────────────────────
class _UsersPage extends ConsumerWidget {
  const _UsersPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(usersListProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (users) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('All users', style: AppTextStyles.heading2),
            Row(children: [
              AppBadge(label: '${users.length} total', color: AppColors.primary),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Add user'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          ...users.map((u) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _UserCard(u),
          )),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard(this.user);

  @override
  Widget build(BuildContext context) {
    final role   = user['role'] as String;
    final active = user['is_active'] as bool;
    final color  = role == 'ADMIN' ? AppColors.error
                 : role == 'MANAGEMENT' ? AppColors.warning
                 : AppColors.primary;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        CircleAvatar(
          radius: 20, backgroundColor: color.withOpacity(.12),
          child: Text((user['name'] as String)[0].toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user['name'] as String, style: AppTextStyles.bodyBold),
          Text('+91 ${user['mobile']}', style: AppTextStyles.caption),
          if (user['email'] != null)
            Text(user['email'] as String, style: AppTextStyles.caption),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AppBadge(label: role[0].toUpperCase() + role.substring(1), color: color),
          const SizedBox(height: 4),
          AppBadge(
            label: active ? 'Active' : 'Inactive',
            color: active ? AppColors.success : AppColors.textMuted,
          ),
        ]),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
          onPressed: () {},
        ),
      ]),
    );
  }
}

// ── Properties page ───────────────────────────────────────────────
class _PropertiesPage extends ConsumerWidget {
  const _PropertiesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(propertiesListProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (props) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Properties', style: AppTextStyles.heading2),
            Row(children: [
              AppBadge(label: '${props.length} units', color: AppColors.primary),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_home_outlined, size: 16),
                label: const Text('Add unit'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          ...props.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PropertyCard(p),
          )),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Map<String, dynamic> prop;
  const _PropertyCard(this.prop);

  @override
  Widget build(BuildContext context) {
    final owner = prop['owner'] as Map<String, dynamic>?;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.apartment, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Unit ${prop['unit_no']}', style: AppTextStyles.bodyBold),
          Text('Floor ${prop['floor']}'
              '${prop['area_sqft'] != null ? ' · ${prop['area_sqft']} sq ft' : ''}',
              style: AppTextStyles.caption),
          if (owner != null)
            Text('Owner: ${owner['name']} · +91 ${owner['mobile']}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AppBadge(
            label: (prop['type'] as String? ?? 'residential').toUpperCase(),
            color: AppColors.primary,
          ),
        ]),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
          onPressed: () {},
        ),
      ]),
    );
  }
}

// ── Profile screen (exported for use in shell) ────────────────────
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
        final roleColor = profile.role == 'ADMIN' ? AppColors.error
            : profile.role == 'MANAGEMENT' ? AppColors.warning : AppColors.primary;
        final roleLabel = profile.role[0].toUpperCase() + profile.role.substring(1);

        return ListView(padding: const EdgeInsets.all(20), children: [
          Center(child: Column(children: [
            CircleAvatar(
              radius: 40, backgroundColor: AppColors.primaryLight,
              child: Text(profile.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
            Text(profile.name, style: AppTextStyles.heading2),
            const SizedBox(height: 6),
            AppBadge(label: roleLabel, color: roleColor),
          ])),
          const SizedBox(height: 24),
          AppCard(child: Column(children: [
            _InfoRow(icon: Icons.phone_outlined,  label: 'Mobile', value: '+91 ${profile.mobile}'),
            if (profile.email != null) ...[
              const Divider(height: 1),
              _InfoRow(icon: Icons.email_outlined, label: 'Email', value: profile.email!),
            ],
            ...propAsync.whenData((prop) {
              if (prop == null) return <Widget>[];
              return [
                const Divider(height: 1),
                _InfoRow(icon: Icons.apartment_outlined,  label: 'Unit',  value: 'Unit ${prop.unitNo}'),
                const Divider(height: 1),
                _InfoRow(icon: Icons.layers_outlined,     label: 'Floor', value: 'Floor ${prop.floor}'),
                if (prop.areaSqft != null) ...[
                  const Divider(height: 1),
                  _InfoRow(icon: Icons.square_foot_outlined, label: 'Area', value: '${prop.areaSqft} sq ft'),
                ],
              ];
            }).value ?? [],
          ])),
          const SizedBox(height: 12),
          AppCard(child: Column(children: [
            ListTile(dense: true,
              leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () {}),
            const Divider(height: 1),
            ListTile(dense: true,
              leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              title: const Text('Notification settings'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () {}),
          ])),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () async {
              await ref.read(authNotifierProvider).logout();
            },
          ),
        ]);
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textMuted),
      const SizedBox(width: 10),
      Text('$label  ', style: AppTextStyles.caption),
      Expanded(child: Text(value, style: AppTextStyles.bodyBold, textAlign: TextAlign.right)),
    ]),
  );
}
