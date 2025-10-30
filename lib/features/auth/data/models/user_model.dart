import '../../domain/entities/user.dart';

/// User model for data layer that extends User entity
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.role,
    super.fcmToken,
  });

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['id']?.toString() ?? '',
        username: json['username'] ?? json['name'] ?? '',
        email: json['email'] ?? '',
        role: UserRole.fromString(json['role'] ?? 'employee'),
        fcmToken: json['fcmToken'],
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
      'fcmToken': fcmToken,
    };
  }

  /// Convert UserModel to User entity
  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      role: role,
      fcmToken: fcmToken,
    );
  }

  /// Create UserModel from User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      fcmToken: user.fcmToken,
    );
  }

  /// Copy with method for creating modified instances
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    UserRole? role,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, role: ${role.value})';
  }
}