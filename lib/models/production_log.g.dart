// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductionLogAdapter extends TypeAdapter<ProductionLog> {
  @override
  final int typeId = 1;

  @override
  ProductionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductionLog(
      id: fields[0] as String,
      stageId: fields[1] as String,
      userId: fields[2] as String,
      quantity: fields[3] as int,
      unit: fields[4] as String,
      shift: fields[5] as String,
      logTime: fields[6] as DateTime,
      notes: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      stage: fields[10] as ProductionStage?,
      user: fields[11] as User?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductionLog obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.stageId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.shift)
      ..writeByte(6)
      ..write(obj.logTime)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.stage)
      ..writeByte(11)
      ..write(obj.user);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CreateLogRequestAdapter extends TypeAdapter<CreateLogRequest> {
  @override
  final int typeId = 2;

  @override
  CreateLogRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreateLogRequest(
      stageId: fields[0] as String,
      quantity: fields[1] as int,
      unit: fields[2] as String,
      shift: fields[3] as String,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CreateLogRequest obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.stageId)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.shift)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateLogRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GetLogsQueryAdapter extends TypeAdapter<GetLogsQuery> {
  @override
  final int typeId = 3;

  @override
  GetLogsQuery read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GetLogsQuery(
      shift: fields[0] as String?,
      stageId: fields[1] as String?,
      date: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GetLogsQuery obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.shift)
      ..writeByte(1)
      ..write(obj.stageId)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetLogsQueryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StageTotalAdapter extends TypeAdapter<StageTotal> {
  @override
  final int typeId = 4;

  @override
  StageTotal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StageTotal(
      stageId: fields[0] as String,
      totalQuantity: fields[1] as int,
      count: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StageTotal obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.stageId)
      ..writeByte(1)
      ..write(obj.totalQuantity)
      ..writeByte(2)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StageTotalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
