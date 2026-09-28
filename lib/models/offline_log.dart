import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'offline_log.g.dart';

@HiveType(typeId: 0)
class OfflineLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String stageId;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  String unit;

  @HiveField(4)
  String shift;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  int retryCount;

  @HiveField(8)
  DateTime? lastAttemptAt;

  @HiveField(9)
  String? lastError;

  OfflineLog({
    required this.id,
    required this.stageId,
    required this.quantity,
    required this.unit,
    required this.shift,
    this.notes,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.lastError,
  });

  factory OfflineLog.fromCreateLogRequest(
    String stageId,
    int quantity,
    String unit,
    String shift,
    String? notes,
  ) {
    return OfflineLog(
      id: const Uuid().v4(),
      stageId: stageId,
      quantity: quantity,
      unit: unit,
      shift: shift,
      notes: notes,
      createdAt: DateTime.now(),
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