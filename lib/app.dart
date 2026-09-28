import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/auth_provider.dart';
import '../providers/production_provider.dart';
import '../services/notification_service.dart';
import '../services/services.dart';

final _initAuthProvider = FutureProvider<void>((ref) async {
  await ref.read(authProvider.notifier).checkAuthStatus();
});

final _initSyncProvider = FutureProvider<void>((ref) async {
  final sync = ref.read(syncServiceProvider);
  await sync.startPeriodicSync(interval: const Duration(minutes: 5));
});

final _initNotificationsProvider = FutureProvider<void>((ref) async {
  final notifications = ref.read(notificationServiceProvider);
  await notifications.initialize();
});

class TexFlowApp extends ConsumerWidget {
  const TexFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_initAuthProvider);
    ref.watch(_initSyncProvider);
    ref.watch(_initNotificationsProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'TexFlow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
