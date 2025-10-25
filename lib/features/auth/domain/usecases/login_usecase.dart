import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for user login functionality
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// Execute the login use case
  /// Takes [LoginParams] and returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> call(LoginParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Perform login through repository
    return await repository.login(params.email, params.password);
  }

  /// Validate login parameters
  ValidationFailure? _validateParams(LoginParams params) {
    if (params.email.isEmpty) {
      return ValidationFailure.required('email', 'El email es requerido');
    }

    if (!_isValidEmail(params.email)) {
      return ValidationFailure.format('email', 'El formato del email es inválido');
    }

    if (params.password.isEmpty) {
      return ValidationFailure.required('password', 'La contraseña es requerida');
    }

    if (params.password.length < 6) {
      return ValidationFailure.minLength('password', 6, 'La contraseña debe tener al menos 6 caracteres');
    }

    return null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}

/// Parameters for login use case
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];

  @override
  String toString() {
    return 'LoginParams(email: $email, password: [HIDDEN])';
  }
}