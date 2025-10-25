import '../../domain/entities/user.dart';

/// User model for data layer that extends User entity
/// Handles JSON serialization/deserialization matching backend structure
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
        id: json['id'] as String,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: UserRole.fromString(json['role'] as String? ?? 'employee'),
      );
    } catch (e) {
      throw FormatException('Error parsing UserModel from JSON: $e', json);
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

  /// Create a copy with updated values
  @override
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

  /// Create empty UserModel for testing or initial state
  factory UserModel.empty() {
    return const UserModel(
      id: '',
      username: '',
      email: '',
      role: UserRole.employee,
    );
  }

  /// Validate if the UserModel has valid data
  bool get isValid {
    return id.isNotEmpty &&
           username.isNotEmpty &&
           email.isNotEmpty;
  }

  /// Check if email format is valid
  bool get isEmailValid {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}