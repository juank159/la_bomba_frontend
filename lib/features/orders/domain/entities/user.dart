import 'package:equatable/equatable.dart';

/// User role enum matching backend
enum UserRole {
  admin('admin'),
  supervisor('supervisor'),
  employee('employee');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      case 'employee':
        return UserRole.employee;
      default:
        return UserRole.employee;
    }
  }

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

  /// Check if role is admin
  bool get isAdmin => this == UserRole.admin;

  /// Check if role is supervisor
  bool get isSupervisor => this == UserRole.supervisor;

  /// Check if role is employee
  bool get isEmployee => this == UserRole.employee;
}

/// User entity representing a user in the domain layer
/// Matches the backend User entity structure
class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final UserRole role;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    role,
  ];

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, role: ${role.value})';
  }

  /// Copy with method for creating modified instances
  User copyWith({
    String? id,
    String? username,
    String? email,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  /// Check if the user is an admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if the user is a supervisor
  bool get isSupervisor => role == UserRole.supervisor;

  /// Check if the user is an employee
  bool get isEmployee => role == UserRole.employee;

  /// Get display-friendly role text
  String get roleText => role.displayName;

  /// Get user's display name (username)
  String get displayName => username;

  /// Get user's initials for avatar
  String get initials {
    if (username.isEmpty) return 'U';
    
    final parts = username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    } else {
      return username[0].toUpperCase();
    }
  }

  /// Check if user has permission to perform admin actions
  bool get canPerformAdminActions => isAdmin;

  /// Check if user can update order quantities
  bool get canUpdateQuantities => isAdmin;

  /// Check if user can delete orders
  bool get canDeleteOrders => isAdmin;

  /// Check if user can update order status
  bool get canUpdateOrderStatus => isAdmin;
}