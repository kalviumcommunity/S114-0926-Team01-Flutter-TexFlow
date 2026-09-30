import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/bottleneck_alert.dart';
import '../../providers/production_provider.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/app_states.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(alertsProvider);
    final activeCount = activeAsync.asData?.value.length;

    return AppScaffold(
      title: 'Alerts',
      subtitle: activeCount == null
          ? 'Bottleneck monitoring'
          : (activeCount == 0
                ? 'All clear'
                : '$activeCount active issue${activeCount == 1 ? '' : 's'}'),
      scrollable: false,
      contentPadding: EdgeInsets.zero,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Active'),
                Tab(text: 'Resolved'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AlertsList(
                    provider: alertsProvider,
                    emptyTitle: 'No active alerts',
                    emptyMessage: 'All production stages are running smoothly.',
                    emptyIcon: Icons.verified_rounded,
                    showResolve: true,
                  ),
                  _AlertsList(
                    provider: resolvedAlertsProvider,
                    emptyTitle: 'Nothing resolved yet',
                    emptyMessage: 'Resolved alerts will be archived here.',
                    emptyIcon: Icons.archive_outlined,
                    showResolve: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsList extends ConsumerWidget {
  final FutureProvider<List<BottleneckAlert>> provider;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showResolve;

  const _AlertsList({
    required this.provider,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.showResolve,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(provider),
      child: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              children: [
                AppEmptyState(
                  icon: emptyIcon,
                  title: emptyTitle,
                  message: emptyMessage,
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _AlertCard(alert: alerts[index], showResolve: showResolve),
          );
        },
        loading: () => const AppLoadingView(label: 'Loading alerts...'),
        error: (err, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppErrorView(
              message: err.toString(),
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends ConsumerStatefulWidget {
  final BottleneckAlert alert;
  final bool showResolve;

  const _AlertCard({required this.alert, required this.showResolve});

  @override
  ConsumerState<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends ConsumerState<_AlertCard> {
  bool _resolving = false;

  Future<void> _resolve() async {
    setState(() => _resolving = true);
    try {
      await ref.read(alertApiProvider).resolveAlert(widget.alert.id);
      ref.invalidate(alertsProvider);
      ref.invalidate(resolvedAlertsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert marked as resolved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not resolve alert: $e')));
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final scheme = Theme.of(context).colorScheme;
    final severity = _severityStyle(alert.severity);

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: severity.color, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: severity.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(severity.icon, size: 13, color: severity.color),
                        const SizedBox(width: 5),
                        Text(
                          severity.label,
                          style: TextStyle(
                            color: severity.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(alert.createdAt),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.factory_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    alert.stageName,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              if (widget.showResolve && !alert.resolved) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _resolving ? null : _resolve,
                    icon: _resolving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                    label: const Text('Mark as resolved'),
                  ),
                ),
              ] else if (alert.resolved && alert.resolvedAt != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Resolved ${DateFormat('MMM d, HH:mm').format(alert.resolvedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _SeverityStyle _severityStyle(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return const _SeverityStyle(
          label: 'HIGH',
          color: Color(0xFFD32F2F),
          icon: Icons.priority_high_rounded,
        );
      case 'medium':
        return const _SeverityStyle(
          label: 'MEDIUM',
          color: Color(0xFFEF6C00),
          icon: Icons.warning_amber_rounded,
        );
      case 'low':
        return const _SeverityStyle(
          label: 'LOW',
          color: Color(0xFF1976D2),
          icon: Icons.info_outline_rounded,
        );
      default:
        return _SeverityStyle(
          label: severity.toUpperCase(),
          color: const Color(0xFF616161),
          icon: Icons.circle_outlined,
        );
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}

class _SeverityStyle {
  final String label;
  final Color color;
  final IconData icon;

  const _SeverityStyle({
    required this.label,
    required this.color,
    required this.icon,
  });
}
