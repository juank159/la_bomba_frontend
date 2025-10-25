import '../../domain/entities/user.dart';

/// User model for data layer that extends User entity
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.role,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['id']?.toString() ?? '',
        username: json['username'] ?? json['name'] ?? '',
        email: json['email'] ?? '',
        role: UserRole.fromString(json['role'] ?? 'employee'),
      );
    } catch (e) {
      throw FormatException('Failed to parse UserModel from JSON: $e');
    }
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role.value,
    };
  }

  /// Convert UserModel to User entity
  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      role: role,
    );
  }

  /// Create UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
    );
  }

  /// Copy with method for creating modified instances
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, role: ${role.value})';
  }
}