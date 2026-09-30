import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/production/log_entry_screen.dart';
import '../screens/dashboard/alerts_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Routes that are reachable without an authenticated session.
///
/// `/splash` is deliberately excluded: it is only a temporary holding screen
/// while the session is being resolved, never a destination.
const String splashRoute = '/splash';
const String loginRoute = '/login';
const String registerRoute = '/register';
const String dashboardRoute = '/';
const String logRoute = '/production/log';
const String alertsRoute = '/dashboard/alerts';
const String adminRoute = '/admin';
const String profileRoute = '/profile';
const Set<String> _publicRoutes = {loginRoute, registerRoute};

/// The app's route table. Exposed so tests (and any alternate entry point) can
/// build a `GoRouter` with the same routes and guard.
final List<RouteBase> appRoutes = <RouteBase>[
  GoRoute(path: splashRoute, builder: (context, state) => const SplashScreen()),
  GoRoute(path: loginRoute, builder: (context, state) => const LoginScreen()),
  GoRoute(
    path: registerRoute,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: dashboardRoute,
    builder: (context, state) => const DashboardScreen(),
  ),
  GoRoute(path: logRoute, builder: (context, state) => const LogEntryScreen()),
  GoRoute(path: alertsRoute, builder: (context, state) => const AlertsScreen()),
  GoRoute(path: adminRoute, builder: (context, state) => const AdminScreen()),
  GoRoute(
    path: profileRoute,
    builder: (context, state) => const ProfileScreen(),
  ),
];

/// The single source of truth for navigation authorisation.
///
/// Extracted from the router so the guard can be exercised directly: entering a
/// guarded URL must never render a screen the role may not use.
String? authRedirect(GoRouterState state, AuthState authState) {
  final location = state.matchedLocation;

  // `initial` covers the window before the first auth check runs, so the login
  // form is never flashed on a cold start.
  final isResolvingAuth =
      authState.status == AuthStatus.initial || authState.isLoading;

  if (isResolvingAuth) {
    // Always hold on the splash screen until the session is known.
    return location == splashRoute ? null : splashRoute;
  }

  // Unauthenticated: only the public auth routes are reachable.
  if (!authState.isAuthenticated) {
    return _publicRoutes.contains(location) ? null : loginRoute;
  }

  // Authenticated: send users away from the auth flow / splash to their role's
  // home route.
  if (_publicRoutes.contains(location) || location == splashRoute) {
    return defaultRouteForRole(authState.user!.role);
  }

  if (!_isRouteAllowedForRole(location, authState.user!.role)) {
    return defaultRouteForRole(authState.user!.role);
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(goRouterRefreshNotifierProvider);

  return GoRouter(
    initialLocation: splashRoute,
    refreshListenable: notifier,
    // Read (do not watch) so the GoRouter instance stays stable and is only
    // re-evaluated through `refreshListenable` when auth state changes.
    redirect: (context, state) => authRedirect(state, ref.read(authProvider)),
    routes: appRoutes,
  );
});

final goRouterRefreshNotifierProvider = Provider<GoRouterRefreshNotifier>((
  ref,
) {
  return GoRouterRefreshNotifier(ref);
});

/// The landing route for a given role.
///
/// Every authenticated role starts on the dashboard: the backend exposes
/// `/api/dashboard`, `/api/production/logs` and `/api/production/totals` to any
/// authenticated user, and the dashboard already adapts its calls to action
/// (supervisors get "Log Production" instead of "View Alerts"). The previous
/// behaviour sent supervisors straight to the bare log form, which left a
/// newly registered user (the Prisma default role is `supervisor`) with no
/// overview and no navigation.
String defaultRouteForRole(String role) => dashboardRoute;

/// Authorisation for every declared route.
///
/// Kept in sync with `AppScaffold`'s destination visibility so the UI never
/// offers a destination the guard would reject.
bool _isRouteAllowedForRole(String location, String role) {
  final normalizedRole = role.toLowerCase();

  // Admin configuration is admin-only.
  if (location == adminRoute) {
    return normalizedRole == 'admin';
  }

  // Triage/resolution of bottleneck alerts is a management action.
  if (location == alertsRoute) {
    return normalizedRole == 'manager' || normalizedRole == 'admin';
  }

  // Overview, production logging and profile are available to every role.
  if (location == dashboardRoute ||
      location == profileRoute ||
      location == logRoute) {
    return true;
  }

  // Deny by default: an unrecognised path must never render.
  return false;
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

// End of file marker
