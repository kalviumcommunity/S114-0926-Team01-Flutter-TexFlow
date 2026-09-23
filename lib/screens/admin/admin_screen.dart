import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_card.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!authState.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin access required',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                authState.user!.name.isNotEmpty ? authState.user!.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: colorScheme.onSurface),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administration',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'System configuration and management',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              AppCard(
                title: 'User Management',
                child: Column(
                  children: [
                    _buildAdminItem(
                      context,
                      Icons.people_outline,
                      'Users',
                      'Manage user accounts and roles',
                      () {},
                    ),
                    const Divider(),
                    _buildAdminItem(
                      context,
                      Icons.security_outlined,
                      'Roles & Permissions',
                      'Configure role-based access control',
                      () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                title: 'Production Configuration',
                child: Column(
                  children: [
                    _buildAdminItem(
                      context,
                      Icons.factory_outlined,
                      'Production Stages',
                      'Manage production stages and order',
                      () {},
                    ),
                    const Divider(),
                    _buildAdminItem(
                      context,
                      Icons.settings_outlined,
                      'Shift Settings',
                      'Configure shift times and labels',
                      () {},
                    ),
                    const Divider(),
                    _buildAdminItem(
                      context,
                      Icons.warning_outlined,
                      'Alert Thresholds',
                      'Configure bottleneck detection thresholds',
                      () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                title: 'System',
                child: Column(
                  children: [
                    _buildAdminItem(
                      context,
                      Icons.storage_outlined,
                      'Database',
                      'Database management and backup',
                      () {},
                    ),
                    const Divider(),
                    _buildAdminItem(
                      context,
                      Icons.bug_report_outlined,
                      'Debug Logs',
                      'View system logs and errors',
                      () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}