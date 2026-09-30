import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/services.dart';

final _initSyncProvider = FutureProvider<void>((ref) async {
  final sync = ref.read(syncServiceProvider);
  sync.startPeriodicSync(interval: const Duration(minutes: 5));
});

final _initNotificationsProvider = FutureProvider<void>((ref) async {
  final notifications = ref.read(notificationServiceProvider);
  await notifications.initialize();
  for (final warning in notifications.warnings) {
    debugPrint('TexFlow notifications: $warning');
  }
});

class TexFlowApp extends ConsumerStatefulWidget {
  const TexFlowApp({super.key});

  @override
  ConsumerState<TexFlowApp> createState() => _TexFlowAppState();
}

class _TexFlowAppState extends ConsumerState<TexFlowApp> {
  @override
  void initState() {
    super.initState();
    // Kick off session restoration; the router holds on `/splash` until this
    // resolves so the login form is never shown prematurely.
    Future.microtask(() => ref.read(authProvider.notifier).checkAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(_initSyncProvider);
    ref.watch(_initNotificationsProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'TexFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
