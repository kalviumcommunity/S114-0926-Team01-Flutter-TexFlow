// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineLogAdapter extends TypeAdapter<OfflineLog> {
  @override
  final int typeId = 0;

  @override
  OfflineLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineLog(
      id: fields[0] as String,
      stageId: fields[1] as String,
      quantity: fields[2] as int,
      unit: fields[3] as String,
      shift: fields[4] as String,
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      retryCount: fields[7] as int,
      lastAttemptAt: fields[8] as DateTime?,
      lastError: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.stageId)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.shift)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.retryCount)
      ..writeByte(8)
      ..write(obj.lastAttemptAt)
      ..writeByte(9)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
