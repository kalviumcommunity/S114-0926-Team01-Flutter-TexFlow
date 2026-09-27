import 'package:hive/hive.dart';
import 'production_stage.dart';
import 'user.dart';

part 'production_log.g.dart';

@HiveType(typeId: 1)
class ProductionLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String stageId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final String shift;

  @HiveField(6)
  final DateTime logTime;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final ProductionStage? stage;

  @HiveField(11)
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

@HiveType(typeId: 2)
class CreateLogRequest {
  @HiveField(0)
  final String stageId;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final String unit;

  @HiveField(3)
  final String shift;

  @HiveField(4)
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

@HiveType(typeId: 3)
class GetLogsQuery {
  @HiveField(0)
  final String? shift;

  @HiveField(1)
  final String? stageId;

  @HiveField(2)
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

@HiveType(typeId: 4)
class StageTotal {
  @HiveField(0)
  final String stageId;

  @HiveField(1)
  final int totalQuantity;

  @HiveField(2)
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