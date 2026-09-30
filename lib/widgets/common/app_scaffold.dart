import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/production_provider.dart';

class AppDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool Function(AuthState auth) visible;

  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.visible,
  });
}

/// Roles allowed to triage/resolve alerts. Mirrors the route guard.
const _alertRoles = {'manager', 'admin'};

/// Mirrors `_isRouteAllowedForRole` in `lib/config/routes.dart` so the nav
/// never offers a destination that the guard would reject.
final _destinations = <AppDestination>[
  AppDestination(
    label: 'Dashboard',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
    route: '/',
    // Overview data is available to every authenticated role.
    visible: (auth) => auth.isAuthenticated,
  ),
  AppDestination(
    label: 'Log',
    icon: Icons.add_box_outlined,
    selectedIcon: Icons.add_box_rounded,
    route: '/production/log',
    visible: (auth) => auth.isAuthenticated,
  ),
  AppDestination(
    label: 'Alerts',
    icon: Icons.notifications_none_rounded,
    selectedIcon: Icons.notifications_rounded,
    route: '/dashboard/alerts',
    visible: (auth) => _alertRoles.contains(auth.user?.role.toLowerCase()),
  ),
  AppDestination(
    label: 'Admin',
    icon: Icons.admin_panel_settings_outlined,
    selectedIcon: Icons.admin_panel_settings_rounded,
    route: '/admin',
    visible: (auth) => auth.isAdmin,
  ),
  AppDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    route: '/profile',
    visible: (auth) => auth.isAuthenticated,
  ),
];

class AppScaffold extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final EdgeInsetsGeometry contentPadding;
  final bool scrollable;
  final Future<void> Function()? onRefresh;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
    this.scrollable = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final location = GoRouterState.of(context).uri.path;

    final destinations = _destinations
        .where((d) => d.visible(authState))
        .toList();

    var selectedIndex = destinations.indexWhere((d) => d.route == location);
    if (selectedIndex < 0) selectedIndex = 0;

    final isOnline = ref
        .watch(connectivityProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1200 ? 1100.0 : 820.0;

        Widget inner;
        if (!scrollable) {
          inner = body;
        } else {
          final scrollView = SingleChildScrollView(
            physics: onRefresh != null
                ? const AlwaysScrollableScrollPhysics()
                : null,
            padding: contentPadding,
            child: body,
          );
          inner = onRefresh != null
              ? RefreshIndicator(onRefresh: onRefresh!, child: scrollView)
              : scrollView;
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: inner,
          ),
        );
      },
    );

    Widget navBar() {
      if (destinations.length < 2) return const SizedBox.shrink();
      return NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final route = destinations[index].route;
          if (route != location) context.go(route);
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      );
    }

    Widget rail() {
      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final route = destinations[index].route;
          if (route != location) context.go(route);
        },
        labelType: NavigationRailLabelType.all,
        scrollable: destinations.length > 5,
        leading: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: _BrandMark(size: 40),
        ),
        destinations: [
          for (final d in destinations)
            NavigationRailDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: Text(d.label),
            ),
        ],
      );
    }

    final appBar = AppBar(
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title),
          if (subtitle != null)
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        _ConnectivityBadge(isOnline: isOnline),
        ...actions,
        const SizedBox(width: 8),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;

        if (wide && destinations.length >= 2) {
          return Scaffold(
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                rail(),
                VerticalDivider(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.6),
                ),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          floatingActionButton: floatingActionButton,
          body: content,
          bottomNavigationBar: destinations.length >= 2 ? navBar() : null,
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;

  const _BrandMark({required this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.factory_rounded,
        color: scheme.onPrimary,
        size: size * 0.55,
      ),
    );
  }
}

class _ConnectivityBadge extends StatelessWidget {
  final bool isOnline;

  const _ConnectivityBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isOnline ? scheme.primary : Colors.orange;

    return Tooltip(
      message: isOnline ? 'Online' : 'Offline - changes are queued',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 7,
              width: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
