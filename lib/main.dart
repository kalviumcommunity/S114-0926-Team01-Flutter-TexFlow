import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Best-effort: push messaging is optional, so startup must continue even if
  // Firebase is unconfigured or unavailable on this platform.
  final firebase = await initializeFirebase();
  if (!firebase.isAvailable) {
    debugPrint('TexFlow: push notifications inactive ($firebase)');
  }

  runApp(const ProviderScope(child: TexFlowApp()));
}
