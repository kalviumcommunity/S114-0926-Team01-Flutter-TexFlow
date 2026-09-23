import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/production_log.dart';
import '../../models/production_stage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/production_provider.dart';
import '../../widgets/charts/production_chart.dart';
import '../../widgets/common/app_card.dart';
import '../../utils/helpers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final logsAsync = ref.watch(productionLogsProvider);
    final stagesAsync = ref.watch(productionStagesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final isManagerOrAdmin = authState.isManager || authState.isAdmin;
    final isSupervisor = authState.isSupervisor;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TexFlow'),
        actions: [
          if (authState.user == null)
            TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Login'),
            )
          else
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
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productionLogsProvider);
            ref.invalidate(productionStagesProvider);
            ref.invalidate(alertsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Production intelligence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Smart textile production',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        authState.user != null
                            ? 'Welcome, ${authState.user!.name} (${authState.user!.role})'
                            : 'Track every stage of your production line',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (isSupervisor || isManagerOrAdmin)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => context.go('/production/log'),
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: const Text('Log Production'),
                            ),
                          if (isManagerOrAdmin)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => context.go('/dashboard/alerts'),
                              icon: const Icon(Icons.warning_amber_rounded),
                              label: const Text('View Alerts'),
                            ),
                          if (authState.isAdmin)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => context.go('/admin'),
                              icon: const Icon(Icons.admin_panel_settings_rounded),
                              label: const Text('Admin Panel'),
                            ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                            ),
                            onPressed: () {
                              ref.invalidate(productionLogsProvider);
                              ref.invalidate(productionStagesProvider);
                              ref.invalidate(alertsProvider);
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh Data'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                logsAsync.when(
                  data: (logs) => _buildStatsGrid(context, logs),
                  loading: () => _buildStatsGrid(context, [], isLoading: true),
                  error: (err, _) => _buildStatsGrid(context, [], error: err.toString()),
                ),
                const SizedBox(height: 24),
                Text(
                  'Production by Stage (Today)',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                stagesAsync.when(
                  data: (stages) => logsAsync.when(
                    data: (logs) => _buildStageChartCard(context, stages, logs),
                    loading: () => _buildChartPlaceholder(),
                    error: (err, _) => _buildErrorCard(err.toString()),
                  ),
                  loading: () => _buildChartPlaceholder(),
                  error: (err, _) => _buildErrorCard(err.toString()),
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent Production Logs',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                logsAsync.when(
                  data: (logs) => _buildRecentLogs(context, logs),
                  loading: () => _buildLoadingCard(),
                  error: (err, _) => _buildErrorCard(err.toString()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, List<ProductionLog> logs,
      {bool isLoading = false, String? error}) {
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayLogs = logs.where((log) => log.logTime.isAfter(todayStart)).toList();
    final totalQuantity = todayLogs.fold(0, (sum, log) => sum + log.quantity);
    final totalEntries = todayLogs.length;

    final stats = [
      {'label': 'Total Quantity', 'value': formatQuantity(totalQuantity), 'icon': Icons.inventory_2_rounded},
      {'label': 'Entries Today', 'value': totalEntries.toString(), 'icon': Icons.note_alt_rounded},
      {'label': 'Active Stages', 'value': logs.map((l) => l.stageId).toSet().length.toString(), 'icon': Icons.factory_rounded},
      {'label': 'Avg/Entry', 'value': totalEntries > 0 ? formatQuantity(totalQuantity ~/ totalEntries) : '0', 'icon': Icons.trending_up_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final item = stats[index];
        final icon = item['icon'] as IconData;
        final label = item['label'] as String;
        final value = item['value'] as String;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStageChartCard(BuildContext context, List<ProductionStage> stages, List<ProductionLog> logs) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayLogs = logs.where((log) => log.logTime.isAfter(todayStart)).toList();

    final stageData = <String, int>{};
    for (final stage in stages) {
      final stageLogs = todayLogs.where((log) => log.stageId == stage.id).toList();
      final total = stageLogs.fold(0, (sum, log) => sum + log.quantity);
      stageData[stage.name] = total;
    }

    final sortedStages = stages.where((s) => stageData[s.name]! > 0).toList()
      ..sort((a, b) => (stageData[b.name] ?? 0).compareTo(stageData[a.name] ?? 0));

    final data = sortedStages.map((s) => (stageData[s.name] ?? 0).toDouble()).toList();
    final labels = sortedStages.map((s) => s.name).toList();

    return AppCard(
      title: 'Today\'s Production by Stage',
      child: data.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No production data for today'),
                    Text('Log some production to see the chart', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          : ProductionChart(data: data, labels: labels),
    );
  }

  Widget _buildRecentLogs(BuildContext context, List<ProductionLog> logs) {
    if (logs.isEmpty) {
      return AppCard(
        title: 'Recent Logs',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No production logs yet'),
                Text('Start logging to see history', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    final recentLogs = logs.take(10).toList();

    return AppCard(
      title: 'Recent Logs',
      child: Column(
        children: recentLogs.map((log) {
          final time = DateFormat('HH:mm').format(log.logTime);
          final date = DateFormat('MMM d').format(log.logTime);
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.factory_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Text(log.stageName ?? 'Unknown Stage'),
            subtitle: Text('${log.quantity} ${log.unit} • ${getShiftLabel(log.shift)} • $date'),
            trailing: Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartPlaceholder() => AppCard(
        title: 'Today\'s Production by Stage',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );

  Widget _buildLoadingCard() => AppCard(
        title: 'Recent Logs',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );

  Widget _buildErrorCard(String error) => AppCard(
        title: 'Error',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load data: $error'),
                const SizedBox(height: 8),
                const Text('Check if the server is running on localhost:5000',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
}