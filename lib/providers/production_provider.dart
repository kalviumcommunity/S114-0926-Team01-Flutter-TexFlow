import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/production_log.dart';
import '../models/production_stage.dart';
import '../models/bottleneck_alert.dart';
import '../core/api/api.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';

final productionApiProvider = Provider<ProductionApiService>((ref) => ProductionApiService());
final alertApiProvider = Provider<DashboardApiService>((ref) => DashboardApiService());
final cacheServiceProvider = Provider<CacheService>((ref) => CacheService()..init());

final productionStagesProvider = FutureProvider<List<ProductionStage>>((ref) async {
  final cache = ref.read(cacheServiceProvider);
  final api = ref.read(productionApiProvider);
  
  try {
    final stages = await api.getStages();
    await cache.cacheStages(stages);
    return stages;
  } catch (_) {
    // Return cached data if API fails
    final cached = cache.getCachedStages();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
});

final productionLogsProvider = FutureProvider<List<ProductionLog>>((ref) async {
  final cache = ref.read(cacheServiceProvider);
  final api = ref.read(productionApiProvider);
  
  try {
    final logs = await api.getLogs();
    await cache.cacheLogs(logs);
    return logs;
  } catch (_) {
    final cached = cache.getCachedLogs();
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
});

final alertsProvider = FutureProvider<List<BottleneckAlert>>((ref) async {
  final api = ref.read(alertApiProvider);
  return api.getAlerts(resolved: false);
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final api = ref.read(alertApiProvider);
  return api.getDashboardStats();
});

class ShiftFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setShift(String? shift) => state = shift;
  void clear() => state = null;
}

class DateFilterNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void setDate(DateTime? date) => state = date;
  void clear() => state = null;
}

final shiftFilterProvider = NotifierProvider<ShiftFilterNotifier, String?>(ShiftFilterNotifier.new);
final dateFilterProvider = NotifierProvider<DateFilterNotifier, DateTime?>(DateFilterNotifier.new);

final stageTotalsProvider = FutureProvider<List<StageTotal>>((ref) async {
  final cache = ref.read(cacheServiceProvider);
  final api = ref.read(productionApiProvider);
  final shift = ref.watch(shiftFilterProvider);
  final date = ref.watch(dateFilterProvider);
  
  try {
    final totals = await api.getStageTotals(shift: shift, date: date);
    return totals;
  } catch (_) {
    // Return empty list if API fails - offline mode
    return [];
  }
});

final offlineQueueCountProvider = Provider<int>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return cache.getOfflineQueueCount();
});

final connectivityProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectionStream;
});