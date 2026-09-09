import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/production_log.dart';
import '../models/production_stage.dart';
import '../services/production_service.dart';

final productionServiceProvider =
    Provider<ProductionService>((ref) => ProductionService());

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
