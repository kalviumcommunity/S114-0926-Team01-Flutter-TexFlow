import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../models/dashboard.dart';

class HealthApiService {
  final ApiClient _client = ApiClient();

  HealthApiService() {
    _client.initialize();
  }

  /// GET /api/health
  /// Public endpoint - no authentication required
  /// Response: { status: 'ok', timestamp: ISO8601 }
  /// Errors: 500
  Future<HealthResponse> checkHealth() async {
    try {
      final response = await _client.dio.get('/health');
      return _client.handleResponse(response, HealthResponse.fromJson);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}