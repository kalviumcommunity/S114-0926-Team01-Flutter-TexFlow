import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Build-time override, e.g.
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000/api`
  ///
  /// Use this for physical devices (the host LAN IP), staging and production.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Resolved API root, always ending in `/api`.
  static String get baseUrl =>
      _envBaseUrl.isNotEmpty ? _envBaseUrl : _defaultBaseUrl;

  /// Sensible per-platform local defaults when no dart-define is supplied.
  static String get _defaultBaseUrl {
    // Web and desktop run on the same host as the backend.
    if (kIsWeb) return 'http://localhost:5000/api';

    switch (defaultTargetPlatform) {
      // The Android emulator reaches the host machine through 10.0.2.2.
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api';
      // The iOS simulator shares the host loopback interface.
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:5000/api';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5000/api';
    }
  }

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String currentUser = '/auth/me';
  static const String productionLogs = '/production/logs';
  static const String productionStages = '/production/stages';
  static const String productionTotals = '/production/totals';
  static const String dashboard = '/dashboard';
  static const String bottlenecks = '/alerts/bottlenecks';
}
