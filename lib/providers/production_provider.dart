import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/production_log.dart';
import '../models/production_stage.dart';
import '../models/bottleneck_alert.dart';
import '../models/production_log.dart';
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
  final api = ref.read(productionApiProvider);
  final shift = ref.watch(shiftFilterProvider);
  final date = ref.watch(dateFilterProvider);
  return api.getStageTotals(shift: shift, date: date);
});