class BottleneckAlert {
  final String id;
  final String stageId;
  final String message;
  final String severity;
  final bool resolved;
  final DateTime createdAt;

  BottleneckAlert({
    required this.id,
    required this.stageId,
    required this.message,
    required this.severity,
    required this.resolved,
    required this.createdAt,
  });

  factory BottleneckAlert.fromJson(Map<String, dynamic> json) {
    return BottleneckAlert(
      id: json['id'],
      stageId: json['stageId'],
      message: json['message'],
      severity: json['severity'],
      resolved: json['resolved'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
