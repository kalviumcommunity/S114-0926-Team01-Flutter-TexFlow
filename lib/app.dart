import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../providers/auth_provider.dart';

final _initAuthProvider = FutureProvider<void>((ref) async {
  await ref.read(authProvider.notifier).checkAuthStatus();
});

class TexFlowApp extends ConsumerWidget {
  const TexFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_initAuthProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'TexFlow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
