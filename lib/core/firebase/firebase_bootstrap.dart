import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Outcome of attempting to bring up Firebase at app startup.
enum FirebaseSupportStatus {
  /// Firebase was initialised and messaging can be used.
  initialized,

  /// Firebase is intentionally not started (missing/blank configuration).
  disabled,

  /// The current platform has no messaging support wired up in this project.
  unsupportedPlatform,

  /// Firebase was configured but initialisation threw.
  failed,
}

class FirebaseBootstrapResult {
  final FirebaseSupportStatus status;
  final String? message;

  const FirebaseBootstrapResult(this.status, [this.message]);

  bool get isAvailable => status == FirebaseSupportStatus.initialized;

  @override
  String toString() =>
      'FirebaseBootstrapResult($status${message == null ? '' : ': $message'})';
}

/// Starts Firebase when it is both supported and configured, and never throws.
///
/// Push messaging is an optional enhancement in TexFlow: if Firebase cannot be
/// started the app must still run, so every failure is converted into a
/// [FirebaseBootstrapResult] the caller can log instead of an exception that
/// would crash `main()`.
///
/// Configuration sources, in order:
/// * Android: `android/app/google-services.json`
/// * iOS: `ios/Runner/GoogleService-Info.plist`
/// * Web: `--dart-define` values (see `webFirebaseOptions` below) because the
///   web SDK has no native config file to fall back on.
Future<FirebaseBootstrapResult> initializeFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      return const FirebaseBootstrapResult(FirebaseSupportStatus.initialized);
    }

    if (kIsWeb) {
      final options = _webFirebaseOptionsFromEnvironment();
      if (options == null) {
        return const FirebaseBootstrapResult(
          FirebaseSupportStatus.disabled,
          'Web Firebase config not supplied. Pass FIREBASE_API_KEY, '
          'FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID and '
          'FIREBASE_PROJECT_ID via --dart-define to enable web push.',
        );
      }
      await Firebase.initializeApp(options: options);
      return const FirebaseBootstrapResult(FirebaseSupportStatus.initialized);
    }

    // firebase_messaging in this project is only wired for mobile.
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return FirebaseBootstrapResult(
        FirebaseSupportStatus.unsupportedPlatform,
        'Firebase messaging is not configured for $platform.',
      );
    }

    await Firebase.initializeApp();
    return const FirebaseBootstrapResult(FirebaseSupportStatus.initialized);
  } catch (error) {
    return FirebaseBootstrapResult(
      FirebaseSupportStatus.failed,
      'Firebase.initializeApp() failed: $error',
    );
  }
}

FirebaseOptions? _webFirebaseOptionsFromEnvironment() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  if (apiKey.isEmpty ||
      appId.isEmpty ||
      messagingSenderId.isEmpty ||
      projectId.isEmpty) {
    return null;
  }

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain.isEmpty ? null : authDomain,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
  );
}
