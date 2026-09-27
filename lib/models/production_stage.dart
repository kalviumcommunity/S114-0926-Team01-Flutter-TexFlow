import 'package:hive/hive.dart';

part 'production_stage.g.dart';

@HiveType(typeId: 0)
class ProductionStage {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final int order;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  ProductionStage({
    required this.id,
    required this.name,
    this.description,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductionStage.fromJson(Map<String, dynamic> json) {
    return ProductionStage(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      order: json['order'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}