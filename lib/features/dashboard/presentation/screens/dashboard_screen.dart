import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3As Complex'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: const FlutterSecureStorage().read(key: AppConstants.kUserName),
        builder: (ctx, snap) {
          final name = snap.data ?? 'User';
          final role = 'resident'; // will come from storage in Feature 2
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', style: AppTextStyles.body.copyWith(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(name,
                          style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 22)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Resident', style: AppTextStyles.caption.copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text('Feature 2: Dashboard coming next!', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Text(
                  'Authentication is complete ✅\n\nNext up: Dashboard with bills summary, quick actions, and notifications.',
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 24),
                // Module grid preview
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _ModuleTile(icon: Icons.receipt_long, label: 'Bills', color: AppColors.primary, ready: false),
                    _ModuleTile(icon: Icons.payment,      label: 'Pay now', color: AppColors.success, ready: false),
                    _ModuleTile(icon: Icons.build_circle, label: 'Complaints', color: AppColors.warning, ready: false),
                    _ModuleTile(icon: Icons.campaign,     label: 'Notices', color: Color(0xFF7C3AED), ready: false),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool ready;

  const _ModuleTile({required this.icon, required this.label, required this.color, required this.ready});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        border: Border.all(color: color.withOpacity(.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodyBold.copyWith(color: color)),
          if (!ready)
            Text('Coming soon', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
