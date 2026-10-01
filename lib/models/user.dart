class User {
  final String id;
  final String name;
  final String email;

  /// Empty string means "unknown" (e.g. the trimmed `user` relation returned
  /// with production logs only contains `name`). Never invent a privileged
  /// role for a record that did not carry one.
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Tolerant parser covering both shapes the API emits:
  ///  * full auth/me + login/register user (`id`, `name`, `email`, `role`, ...)
  ///  * the trimmed `user: { select: { name: true } }` relation on logs
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asString(json['id']),
      name: _asString(json['name']),
      email: _asString(json['email']),
      role: _asString(json['role']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isSupervisor => role == 'supervisor';

  static String _asString(Object? value) => value is String ? value : '';

  static DateTime? _asDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
