import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../models/bottleneck_alert.dart';
import '../../models/dashboard.dart';

class DashboardApiService {
  final ApiClient _client = ApiClient();

  DashboardApiService() {
    _client.initialize();
  }

  /// GET /api/dashboard/
  /// Requires authentication
  /// Response: DashboardStats { totalQuantity, totalEntries, activeAlerts, recentLogs }
  /// Errors: 401, 403, 500
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _client.dio.get('/dashboard');
      return _client.handleResponse(response, DashboardStats.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// GET /api/dashboard/alerts
  /// Requires authentication
  /// Query params: resolved? (true/false)
  /// Response: BottleneckAlert[]
  /// Errors: 401, 403, 500
  Future<List<BottleneckAlert>> getAlerts({bool resolved = false}) async {
    try {
      final query = AlertsQuery(resolved: resolved);
      final response = await _client.dio.get(
        '/dashboard/alerts',
        queryParameters: query.toQueryParameters(),
      );
      return _client.handleListResponse(response, BottleneckAlert.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  /// PATCH /api/dashboard/alerts/:id/resolve
  /// Requires authentication
  /// Response: BottleneckAlert (updated with resolved=true, resolvedAt)
  /// Errors: 401, 403, 404 (alert not found), 500
  Future<BottleneckAlert> resolveAlert(String alertId) async {
    try {
      final response = await _client.dio.patch('/dashboard/alerts/$alertId/resolve');
      return _client.handleResponse(response, BottleneckAlert.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}