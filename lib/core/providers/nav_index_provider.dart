import 'package:flutter_riverpod/flutter_riverpod.dart';

// Shared nav index — write to navigate AppShell to a specific tab
final navIndexProvider = StateProvider<int>((ref) => -1); // -1 = no navigation
