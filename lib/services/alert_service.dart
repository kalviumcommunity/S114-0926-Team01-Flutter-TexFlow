import '../models/bottleneck_alert.dart';
import 'api_service.dart';
import '../config/constants.dart';

class AlertService {
  final ApiService _api = ApiService();

  Future<List<BottleneckAlert>> getAlerts({bool resolved = false}) async {
    final response = await _api.dio.get(
      ApiConstants.bottlenecks,
      queryParameters: {'resolved': resolved.toString()},
    );
    return (response.data as List)
        .map((json) => BottleneckAlert.fromJson(json))
        .toList();
  }

  Future<BottleneckAlert> resolveAlert(String alertId) async {
    final response = await _api.dio.patch(
      '${ApiConstants.bottlenecks}/$alertId/resolve',
    );
    return BottleneckAlert.fromJson(response.data);
  }
}