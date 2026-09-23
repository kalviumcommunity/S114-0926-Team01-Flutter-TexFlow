import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../models/production_log.dart';
import '../../models/production_stage.dart';

class ProductionApiService {
  final ApiClient _client = ApiClient();

  ProductionApiService() {
    _client.initialize();
  }

  /// GET /api/production/stages
  /// Public endpoint - no authentication required
  /// Response: ProductionStage[]
  /// Errors: 500
  Future<List<ProductionStage>> getStages() async {
    try {
      final response = await _client.dio.get('/production/stages');
      return _client.handleListResponse(response, ProductionStage.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// GET /api/production/logs
  /// Requires authentication
  /// Query params: shift?, stageId?, date? (YYYY-MM-DD)
  /// Response: ProductionLog[]
  /// Errors: 401, 403, 500
  Future<List<ProductionLog>> getLogs({String? shift, String? stageId, DateTime? date}) async {
    try {
      final query = GetLogsQuery(shift: shift, stageId: stageId, date: date);
      final response = await _client.dio.get(
        '/production/logs',
        queryParameters: query.toQueryParameters(),
      );
      return _client.handleListResponse(response, ProductionLog.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// POST /api/production/logs
  /// Requires authentication
  /// Request: { stageId, quantity, unit, shift, notes? }
  /// Response: ProductionLog
  /// Errors: 400 (validation), 401, 403, 404 (stage not found), 500
  Future<ProductionLog> createLog(CreateLogRequest request) async {
    try {
      final response = await _client.dio.post(
        '/production/logs',
        data: request.toJson(),
      );
      return _client.handleResponse(response, ProductionLog.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// GET /api/production/totals
  /// Requires authentication
  /// Query params: shift?, date? (YYYY-MM-DD)
  /// Response: StageTotal[] (grouped by stageId with _sum.quantity and _count)
  /// Errors: 401, 403, 500
  Future<List<StageTotal>> getStageTotals({String? shift, DateTime? date}) async {
    try {
      final query = GetLogsQuery(shift: shift, date: date);
      final response = await _client.dio.get(
        '/production/totals',
        queryParameters: query.toQueryParameters(),
      );
      return _client.handleListResponse(response, StageTotal.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}