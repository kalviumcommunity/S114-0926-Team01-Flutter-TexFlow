class ProductionStage {
  final String id;
  final String name;
  final String? description;
  final int order;

  ProductionStage({
    required this.id,
    required this.name,
    this.description,
    required this.order,
  });

  factory ProductionStage.fromJson(Map<String, dynamic> json) {
    return ProductionStage(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
    };
  }
}
