import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:texflow/config/routes.dart';
import 'package:texflow/models/dashboard.dart';
import 'package:texflow/models/production_log.dart';
import 'package:texflow/models/production_stage.dart';
import 'package:texflow/models/user.dart';
import 'package:texflow/providers/auth_provider.dart';
import 'package:texflow/providers/production_provider.dart';

/// Deterministic stand-in for the real notifier so tests never touch secure
/// storage, the network or the splash timer.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  @override
  Future<void> checkAuthStatus() async {}
}

/// Mirrors `TexFlowApp`'s router without the background sync/notification
/// initialisers (which would leave pending timers behind in tests).
///
/// The router is rebuilt here from the *production* route table and guard, so
/// these tests exercise the real authorisation rules, including deep links.
class _TestApp extends ConsumerWidget {
  const _TestApp({this.initialLocation = splashRoute});

  final String initialLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: initialLocation,
      redirect: (context, state) => authRedirect(state, ref.read(authProvider)),
      routes: appRoutes,
    );
    return MaterialApp.router(routerConfig: router);
  }
}

User _user(String role) => User(
  id: 'u1',
  name: 'Test User',
  email: 'test@texflow.com',
  role: role,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

/// Empty payloads used so every screen stays off the network, Hive /
/// path_provider and the connectivity plugin, which are unavailable in the
/// test binding.
DashboardStats _emptyStats() => DashboardStats(
  totalQuantity: 0,
  totalEntries: 0,
  activeAlerts: 0,
  recentLogs: const [],
);

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    AuthState state, {
    String initialLocation = splashRoute,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(state)),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          productionStagesProvider.overrideWith(
            (ref) => const <ProductionStage>[],
          ),
          productionLogsProvider.overrideWith((ref) => const <ProductionLog>[]),
          alertsProvider.overrideWith((ref) => const []),
          resolvedAlertsProvider.overrideWith((ref) => const []),
          stageTotalsProvider.overrideWith((ref) => const []),
          dashboardStatsProvider.overrideWith((ref) async => _emptyStats()),
          offlineQueueCountProvider.overrideWith((ref) async => 0),
        ],
        child: _TestApp(initialLocation: initialLocation),
      ),
    );
    await tester.pumpAndSettle();
  }

  // --- Auth flow -----------------------------------------------------------

  testWidgets('cold start without a session lands on the login screen', (
    tester,
  ) async {
    await pumpApp(tester, const AuthState(status: AuthStatus.unauthenticated));

    // The splash screen must hand off to login instead of getting stuck.
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Use demo credentials'), findsOneWidget);
  });

  testWidgets('unauthenticated users are kept off the production screens', (
    tester,
  ) async {
    await pumpApp(tester, const AuthState(status: AuthStatus.unauthenticated));

    expect(find.text('Production by Stage (Today)'), findsNothing);
    expect(find.text('New Production Entry'), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('unauthenticated deep link to the dashboard is blocked', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const AuthState(status: AuthStatus.unauthenticated),
      initialLocation: dashboardRoute,
    );

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Production by Stage (Today)'), findsNothing);
  });

  testWidgets('unauthenticated users can navigate to the register screen', (
    tester,
  ) async {
    await pumpApp(tester, const AuthState(status: AuthStatus.unauthenticated));

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
  });

  // --- Role permissions ----------------------------------------------------

  testWidgets('a new supervisor is given the dashboard as home', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AuthState(user: _user('supervisor'), status: AuthStatus.authenticated),
    );

    expect(find.text('Production by Stage (Today)'), findsOneWidget);
    // Supervisors can still log production from the dashboard.
    expect(find.text('Log Production'), findsWidgets);
  });

  testWidgets('supervisor navigation hides Alerts and Admin', (tester) async {
    await pumpApp(
      tester,
      AuthState(user: _user('supervisor'), status: AuthStatus.authenticated),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Alerts'), findsNothing);
    expect(find.text('Admin'), findsNothing);
  });

  testWidgets('manager navigation shows Alerts but not Admin', (tester) async {
    await pumpApp(
      tester,
      AuthState(user: _user('manager'), status: AuthStatus.authenticated),
    );

    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
  });

  testWidgets('admin navigation shows every destination', (tester) async {
    await pumpApp(
      tester,
      AuthState(user: _user('admin'), status: AuthStatus.authenticated),
    );

    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('supervisor deep link to Alerts is bounced to the dashboard', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AuthState(user: _user('supervisor'), status: AuthStatus.authenticated),
      initialLocation: alertsRoute,
    );

    expect(find.text('Production by Stage (Today)'), findsOneWidget);
    expect(find.text('Alerts'), findsNothing);
  });

  testWidgets('manager deep link to Admin is bounced to the dashboard', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AuthState(user: _user('manager'), status: AuthStatus.authenticated),
      initialLocation: adminRoute,
    );

    expect(find.text('Production by Stage (Today)'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
  });

  testWidgets('a supervisor can reach the log screen from the dashboard', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AuthState(user: _user('supervisor'), status: AuthStatus.authenticated),
    );

    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();

    expect(find.text('New Production Entry'), findsOneWidget);
  });

  // --- Responsive layouts --------------------------------------------------

  testWidgets('narrow layout uses a bottom navigation bar', (tester) async {
    await pumpApp(
      tester,
      AuthState(user: _user('supervisor'), status: AuthStatus.authenticated),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('wide layout uses a navigation rail', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      AuthState(user: _user('supervisor'), status: AuthStatus.authenticated),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Alerts'), findsNothing);
  });

  testWidgets('wide layout still gates Alerts for a supervisor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      AuthState(user: _user('supervisor'), status: AuthStatus.authenticated),
      initialLocation: alertsRoute,
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Production by Stage (Today)'), findsOneWidget);
  });

  // --- Admin panel ---------------------------------------------------------

  testWidgets('admin reaches the panel and keeps navigation on narrow layout', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AuthState(user: _user('admin'), status: AuthStatus.authenticated),
      initialLocation: adminRoute,
    );

    expect(find.text('Admin Panel'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    // The admin is not stranded: the shared nav is still present.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('admin panel renders its tabs on a wide layout', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(
      tester,
      AuthState(user: _user('admin'), status: AuthStatus.authenticated),
      initialLocation: adminRoute,
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Admin Panel'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Stages'), findsOneWidget);
  });
}
