import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/production_log.dart';
import '../models/production_stage.dart';
import '../models/bottleneck_alert.dart';
import '../core/api/api.dart';

final productionApiProvider = Provider<ProductionApiService>((ref) => ProductionApiService());
final alertApiProvider = Provider<DashboardApiService>((ref) => DashboardApiService());

final productionStagesProvider = FutureProvider<List<ProductionStage>>((ref) async {
  final api = ref.read(productionApiProvider);
  return api.getStages();
});

final productionLogsProvider = FutureProvider<List<ProductionLog>>((ref) async {
  final api = ref.read(productionApiProvider);
  return api.getLogs();
});

final alertsProvider = FutureProvider<List<BottleneckAlert>>((ref) async {
  final api = ref.read(alertApiProvider);
  return api.getAlerts(resolved: false);
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final api = ref.read(alertApiProvider);
  return api.getDashboardStats();
});