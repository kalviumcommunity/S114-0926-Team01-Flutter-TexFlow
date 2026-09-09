import '../models/production_log.dart';
import '../models/production_stage.dart';
import 'api_service.dart';
import '../config/constants.dart';

class ProductionService {
  final ApiService _api = ApiService();

  Future<List<ProductionLog>> getLogs({String? shift, String? stageId}) async {
    final response = await _api.dio.get(
      ApiConstants.productionLogs,
      queryParameters: {'shift': shift, 'stageId': stageId},
    );
    return (response.data as List)
        .map((json) => ProductionLog.fromJson(json))
        .toList();
  }

  Future<ProductionLog> createLog(ProductionLog log) async {
    final response = await _api.dio.post(
      ApiConstants.productionLogs,
      data: log.toJson(),
    );
    return ProductionLog.fromJson(response.data);
  }

  Future<List<ProductionStage>> getStages() async {
    final response = await _api.dio.get(ApiConstants.productionStages);
    return (response.data as List)
        .map((json) => ProductionStage.fromJson(json))
        .toList();
  }
}
