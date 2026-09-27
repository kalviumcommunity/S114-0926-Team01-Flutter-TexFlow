// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_stage.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductionStageAdapter extends TypeAdapter<ProductionStage> {
  @override
  final int typeId = 0;

  @override
  ProductionStage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductionStage(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      order: fields[3] as int,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProductionStage obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.order)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionStageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
