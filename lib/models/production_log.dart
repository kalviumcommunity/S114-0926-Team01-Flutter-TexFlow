import 'production_stage.dart';
import 'user.dart';

class ProductionLog {
  final String id;
  final String stageId;
  final String userId;
  final int quantity;
  final String unit;
  final String shift;
  final DateTime logTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductionStage? stage;
  final User? user;

  ProductionLog({
    required this.id,
    required this.stageId,
    required this.userId,
    required this.quantity,
    required this.unit,
    required this.shift,
    required this.logTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.stage,
    this.user,
  });

  factory ProductionLog.fromJson(Map<String, dynamic> json) {
    return ProductionLog(
      id: json['id'] as String,
      stageId: json['stageId'] as String,
      userId: json['userId'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      shift: json['shift'] as String,
      logTime: DateTime.parse(json['logTime'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      stage: json['stage'] != null ? ProductionStage.fromJson(json['stage'] as Map<String, dynamic>) : null,
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'quantity': quantity,
      'unit': unit,
      'shift': shift,
      if (notes != null) 'notes': notes,
    };
  }

  String get stageName => stage?.name ?? 'Unknown Stage';
  String get userName => user?.name ?? 'Unknown User';
}

class CreateLogRequest {
  final String stageId;
  final int quantity;
  final String unit;
  final String shift;
  final String? notes;

  CreateLogRequest({
    required this.stageId,
    required this.quantity,
    required this.unit,
    required this.shift,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'quantity': quantity,
      'unit': unit,
      'shift': shift,
      if (notes != null) 'notes': notes,
    };
  }
}

class GetLogsQuery {
  final String? shift;
  final String? stageId;
  final DateTime? date;

  GetLogsQuery({this.shift, this.stageId, this.date});

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (shift != null) params['shift'] = shift;
    if (stageId != null) params['stageId'] = stageId;
    if (date != null) {
      params['date'] = date!.toIso8601String().split('T')[0];
    }
    return params;
  }
}

class StageTotal {
  final String stageId;
  final int totalQuantity;
  final int count;

  StageTotal({
    required this.stageId,
    required this.totalQuantity,
    required this.count,
  });

  factory StageTotal.fromJson(Map<String, dynamic> json) {
    return StageTotal(
      stageId: json['stageId'] as String,
      totalQuantity: (json['_sum']?['quantity'] as int?) ?? 0,
      count: (json['_count'] as int?) ?? 0,
    );
  }
}