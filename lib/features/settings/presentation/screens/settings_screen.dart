import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/stat_card.dart';

// ── Provider ──────────────────────────────────────────────────────
final settingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final res = await client.get(ApiEndpoints.settings);
  return List<Map<String, dynamic>>.from(res.data['items'] as List);
});

// ── Screen ────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 10),
            Text(e.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(settingsProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ]),
        )),
        data: (settings) {
          final Map<String, String> map = {
            for (final s in settings) s['key'] as String: s['value'] as String,
          };
          return ListView(padding: const EdgeInsets.all(20), children: [
            Text('Settings', style: AppTextStyles.heading2),
            const SizedBox(height: 16),

            // ── Penalty engine ───────────────────────────────
            const SectionHeader(title: 'Penalty engine'),
            const SizedBox(height: 8),
            AppCard(child: Column(children: [
              _SettingRow(
                icon: Icons.calculate_outlined,
                label: 'Daily penalty %',
                value: '${map['penalty_daily_pct'] ?? '0.05'}%',
                onEdit: () => _editSetting(context, ref, 'penalty_daily_pct',
                    'Daily penalty %', map['penalty_daily_pct'] ?? '0.05'),
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.calendar_today_outlined,
                label: 'Due day of month',
                value: map['due_day_of_month'] ?? '10',
                onEdit: () => _editSetting(context, ref, 'due_day_of_month',
                    'Due day of month', map['due_day_of_month'] ?? '10'),
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.payments_outlined,
                label: 'Default maintenance amount',
                value: '₹${map['maintenance_amount'] ?? '2000'}',
                onEdit: () => _editSetting(context, ref, 'maintenance_amount',
                    'Maintenance amount (₹)', map['maintenance_amount'] ?? '2000'),
              ),
            ])),

            // Penalty formula preview
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Penalty formula',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  'Penalty = Outstanding × ${map['penalty_daily_pct'] ?? '0.05'}% × Days overdue',
                  style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 12, color: Color(0xFF7DD3FC)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Example: ₹2,000 × ${map['penalty_daily_pct'] ?? '0.05'}% × 45 days = ₹${(2000 * double.parse(map['penalty_daily_pct'] ?? '0.05') / 100 * 45).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 11, color: Color(0xFF6EE7B7)),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Payment gateway ──────────────────────────────
            const SectionHeader(title: 'Payment gateway'),
            const SizedBox(height: 8),
            AppCard(child: Column(children: [
              _SettingRow(
                icon: Icons.qr_code_outlined,
                label: 'UPI ID',
                value: map['upi_id'] ?? '3ascomplex@upi',
                onEdit: () => _editSetting(context, ref, 'upi_id',
                    'UPI ID', map['upi_id'] ?? '3ascomplex@upi'),
              ),
            ])),

            const SizedBox(height: 20),

            // ── Society info ─────────────────────────────────
            const SectionHeader(title: 'Society info'),
            const SizedBox(height: 8),
            AppCard(child: Column(children: [
              _SettingRow(
                icon: Icons.apartment_outlined,
                label: 'Society name',
                value: map['society_name'] ?? '3As Complex',
                onEdit: () => _editSetting(context, ref, 'society_name',
                    'Society name', map['society_name'] ?? '3As Complex'),
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: map['society_address'] ?? 'Pune, Maharashtra',
                onEdit: () => _editSetting(context, ref, 'society_address',
                    'Address', map['society_address'] ?? ''),
              ),
            ])),

            const SizedBox(height: 20),

            // ── Notifications ────────────────────────────────
            const SectionHeader(title: 'Notifications'),
            const SizedBox(height: 8),
            AppCard(child: Column(children: [
              _SwitchRow(
                icon: Icons.notifications_outlined,
                label: 'FCM push notifications',
                subtitle: 'Bills, payments, complaints',
                value: map['fcm_enabled'] == 'true',
                onChanged: (v) => _updateSetting(context, ref, 'fcm_enabled', v.toString()),
              ),
              const Divider(height: 1),
              _SwitchRow(
                icon: Icons.sms_outlined,
                label: 'SMS notifications',
                subtitle: 'OTP and alerts via SMS',
                value: map['sms_enabled'] == 'true',
                onChanged: (v) => _updateSetting(context, ref, 'sms_enabled', v.toString()),
              ),
            ])),

            const SizedBox(height: 20),
          ]);
        },
      ),
    );
  }

  Future<void> _editSetting(BuildContext context, WidgetRef ref,
      String key, String label, String current) async {
    final ctr = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctr,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctr.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _updateSetting(context, ref, key, result);
    }
  }

  Future<void> _updateSetting(BuildContext context, WidgetRef ref,
      String key, String value) async {
    try {
      final client = ref.read(dioClientProvider);
      await client.patch('${ApiEndpoints.settings}/$key', data: {'value': value});
      ref.invalidate(settingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Setting saved'),
          backgroundColor: AppColors.success,
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

// ── Sub-widgets ───────────────────────────────────────────────────

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onEdit;

  const _SettingRow({
    required this.icon, required this.label,
    required this.value, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textMuted),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
      ])),
      IconButton(
        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
        onPressed: onEdit,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
      ),
    ]),
  );
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon, required this.label, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.textMuted),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
        Text(subtitle, style: AppTextStyles.caption),
      ])),
      Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    ]),
  );
}
