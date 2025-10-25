import 'package:equatable/equatable.dart';

/// Model for login request data
class LoginRequestModel extends Equatable {
  final String email;
  final String password;

  const LoginRequestModel({
    required this.email,
    required this.password,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  /// Create from JSON (if needed for form data restoration)
  factory LoginRequestModel.fromJson(Map<String, dynamic> json) {
    return LoginRequestModel(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }

  /// Copy with method for creating modified instances
  LoginRequestModel copyWith({
    String? email,
    String? password,
  }) {
    return LoginRequestModel(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  @override
  List<Object?> get props => [email, password];

  @override
  String toString() {
    return 'LoginRequestModel(email: $email, password: [HIDDEN])';
  }

  /// Validation helpers
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool get isValidPassword {
    return password.isNotEmpty && password.length >= 6;
  }

  bool get isValid {
    return email.isNotEmpty && isValidEmail && isValidPassword;
  }
}