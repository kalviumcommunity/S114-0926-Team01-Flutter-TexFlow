class ProductionLog {
  final String id;
  final String stageId;
  final String userId;
  final int quantity;
  final String unit;
  final String shift;
  final DateTime logTime;
  final String? notes;
  final String? stageName;

  ProductionLog({
    required this.id,
    required this.stageId,
    required this.userId,
    required this.quantity,
    this.unit = 'meters',
    required this.shift,
    required this.logTime,
    this.notes,
    this.stageName,
  });

  factory ProductionLog.fromJson(Map<String, dynamic> json) {
    return ProductionLog(
      id: json['id'],
      stageId: json['stageId'],
      userId: json['userId'],
      quantity: json['quantity'],
      unit: json['unit'] ?? 'meters',
      shift: json['shift'],
      logTime: DateTime.parse(json['logTime']),
      notes: json['notes'],
      stageName: json['stage']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'quantity': quantity,
      'unit': unit,
      'shift': shift,
      'notes': notes,
    };
  }
}
