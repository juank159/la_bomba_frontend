import 'package:equatable/equatable.dart';

/// User entity representing a user in the domain layer
class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final UserRole role;
  final String? fcmToken;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.fcmToken,
  });

  @override
  List<Object?> get props => [id, username, email, role, fcmToken];

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, role: $role)';
  }

  /// Copy with method for creating modified instances
  User copyWith({
    String? id,
    String? username,
    String? email,
    UserRole? role,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

/// User role enumeration
enum UserRole {
  admin,
  supervisor,
  employee;

  /// Convert string to UserRole
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      case 'employee':
        return UserRole.employee;
      default:
        throw ArgumentError('Invalid user role: $role');
    }
  }

  /// Convert UserRole to string
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.employee:
        return 'employee';
    }
  }

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.employee:
        return 'Empleado';
    }
  }

  /// Check if user has admin privileges
  bool get isAdmin => this == UserRole.admin;

  /// Check if user is a supervisor
  bool get isSupervisor => this == UserRole.supervisor;

  /// Check if user is an employee
  bool get isEmployee => this == UserRole.employee;

  /// Check if user can manage tasks (supervisor or admin)
  bool get canManageTasks => isAdmin || isSupervisor;
}