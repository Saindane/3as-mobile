import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (role) {
      'admin'      => (AppColors.error,   'Admin'),
      'management' => (AppColors.warning, 'Management'),
      _            => (AppColors.primary, 'Resident'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
