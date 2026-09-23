import 'production_log.dart';

class DashboardStats {
  final int totalQuantity;
  final int totalEntries;
  final int activeAlerts;
  final List<ProductionLog> recentLogs;

  DashboardStats({
    required this.totalQuantity,
    required this.totalEntries,
    required this.activeAlerts,
    required this.recentLogs,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalQuantity: json['totalQuantity'] as int,
      totalEntries: json['totalEntries'] as int,
      activeAlerts: json['activeAlerts'] as int,
      recentLogs: (json['recentLogs'] as List? ?? [])
          .map((e) => ProductionLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuantity': totalQuantity,
      'totalEntries': totalEntries,
      'activeAlerts': activeAlerts,
      'recentLogs': recentLogs.map((e) => e.toJson()).toList(),
    };
  }
}

class HealthResponse {
  final String status;
  final DateTime timestamp;

  HealthResponse({required this.status, required this.timestamp});

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}