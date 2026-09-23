import 'production_stage.dart';

class BottleneckAlert {
  final String id;
  final String stageId;
  final String message;
  final String severity;
  final bool resolved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final ProductionStage? stage;

  BottleneckAlert({
    required this.id,
    required this.stageId,
    required this.message,
    required this.severity,
    required this.resolved,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.stage,
  });

  factory BottleneckAlert.fromJson(Map<String, dynamic> json) {
    return BottleneckAlert(
      id: json['id'] as String,
      stageId: json['stageId'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      resolved: json['resolved'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
      stage: json['stage'] != null ? ProductionStage.fromJson(json['stage'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stageId': stageId,
      'message': message,
      'severity': severity,
      'resolved': resolved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }

  String get severityLabel => severity.toUpperCase();
  String get stageName => stage?.name ?? 'Unknown Stage';
}

class AlertsQuery {
  final bool? resolved;

  AlertsQuery({this.resolved});

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (resolved != null) params['resolved'] = resolved.toString();
    return params;
  }
}