import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/production_log.dart';
import '../models/production_stage.dart';
import '../models/bottleneck_alert.dart';
import '../services/production_service.dart';
import '../services/alert_service.dart';

final productionServiceProvider =
    Provider<ProductionService>((ref) => ProductionService());

final alertServiceProvider =
    Provider<AlertService>((ref) => AlertService());

final productionLogsProvider =
    FutureProvider<List<ProductionLog>>((ref) async {
  final service = ref.read(productionServiceProvider);
  return service.getLogs();
});

final productionStagesProvider =
    FutureProvider<List<ProductionStage>>((ref) async {
  final service = ref.read(productionServiceProvider);
  return service.getStages();
});

final alertsProvider =
    FutureProvider<List<BottleneckAlert>>((ref) async {
  final service = ref.read(alertServiceProvider);
  return service.getAlerts(resolved: false);
});
