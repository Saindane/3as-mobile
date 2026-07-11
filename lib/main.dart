import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — uncomment when credentials are added
  // if (!kIsWeb) await Firebase.initializeApp();

  runApp(const ProviderScope(child: ThreeAsApp()));
}

class ThreeAsApp extends ConsumerWidget {
  const ThreeAsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '3As Complex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      // Web-specific: scroll behaviour without glow on desktop
      scrollBehavior: kIsWeb ? const _WebScrollBehavior() : null,
    );
  }
}

/// Removes the overscroll glow effect on web/desktop
class _WebScrollBehavior extends MaterialScrollBehavior {
  const _WebScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    
  };
}
