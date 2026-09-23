import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/production/log_entry_screen.dart';
import '../screens/dashboard/alerts_screen.dart';
import '../screens/admin/admin_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = ref.watch(goRouterRefreshNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isLoginRoute = state.matchedLocation == '/login';

      if (isLoading) {
        return null;
      }

      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) {
        return _getDefaultRouteForRole(authState.user!.role);
      }

      if (isLoggedIn) {
        final location = state.matchedLocation;
        if (!_isRouteAllowedForRole(location, authState.user!.role)) {
          return _getDefaultRouteForRole(authState.user!.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/production/log',
        builder: (context, state) => const LogEntryScreen(),
      ),
      GoRoute(
        path: '/dashboard/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
    ],
  );
});

final goRouterRefreshNotifierProvider = Provider<GoRouterRefreshNotifier>((ref) {
  return GoRouterRefreshNotifier(ref);
});

String _getDefaultRouteForRole(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return '/admin';
    case 'manager':
      return '/';
    case 'supervisor':
    default:
      return '/production/log';
  }
}

bool _isRouteAllowedForRole(String location, String role) {
  final normalizedRole = role.toLowerCase();
  
  if (location.startsWith('/admin')) {
    return normalizedRole == 'admin';
  }
  
  if (location.startsWith('/dashboard/alerts')) {
    return normalizedRole == 'manager' || normalizedRole == 'admin';
  }
  
  if (location.startsWith('/production/log')) {
    return normalizedRole == 'supervisor' || normalizedRole == 'manager' || normalizedRole == 'admin';
  }
  
  if (location == '/') {
    return normalizedRole == 'manager' || normalizedRole == 'admin';
  }
  
  return true;
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}