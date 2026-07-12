import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../constants/api_endpoints.dart';

class AppBranding {
  final String appName;
  final String appTagline;
  final String appLogoUrl;
  final String primaryColor;

  const AppBranding({
    required this.appName,
    required this.appTagline,
    required this.appLogoUrl,
    required this.primaryColor,
  });

  factory AppBranding.defaults() => const AppBranding(
    appName:      '3As Complex',
    appTagline:   'Maintenance Management System',
    appLogoUrl:   '',
    primaryColor: '#2563EB',
  );

  factory AppBranding.fromJson(Map<String, dynamic> j) => AppBranding(
    appName:      j['app_name']          as String? ?? '3As Complex',
    appTagline:   j['app_tagline']       as String? ?? 'Maintenance Management System',
    appLogoUrl:   j['app_logo_url']      as String? ?? '',
    primaryColor: j['app_primary_color'] as String? ?? '#2563EB',
  );

  bool get isBase64Logo => appLogoUrl.startsWith('data:image');
  bool get isNetworkLogo => appLogoUrl.startsWith('http');
  bool get hasLogo => appLogoUrl.isNotEmpty;

  Color get primaryColorValue {
    try {
      final hex = primaryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF2563EB);
    }
  }
}

final brandingProvider = FutureProvider<AppBranding>((ref) async {
  try {
    final client = ref.read(dioClientProvider);
    final res = await client.get(ApiEndpoints.branding);
    return AppBranding.fromJson(res.data as Map<String, dynamic>);
  } catch (_) {
    return AppBranding.defaults();
  }
});

AppBranding getBranding(WidgetRef ref) =>
    ref.watch(brandingProvider).valueOrNull ?? AppBranding.defaults();
