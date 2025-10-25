import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for resetting password with verified code
class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  /// Execute the reset password use case
  /// Takes [ResetPasswordParams] and returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Reset password through repository
    return await repository.resetPassword(params.email, params.code, params.newPassword);
  }

  /// Validate reset password parameters
  ValidationFailure? _validateParams(ResetPasswordParams params) {
    if (params.email.isEmpty) {
      return ValidationFailure.required('email', 'El email es requerido');
    }

    if (!_isValidEmail(params.email)) {
      return ValidationFailure.format('email', 'El formato del email es inválido');
    }

    if (params.code.isEmpty) {
      return ValidationFailure.required('code', 'El código es requerido');
    }

    if (params.code.length != 6) {
      return ValidationFailure.invalid('code', 'El código debe tener 6 dígitos');
    }

    if (params.newPassword.isEmpty) {
      return ValidationFailure.required('password', 'La nueva contraseña es requerida');
    }

    if (params.newPassword.length < 6) {
      return ValidationFailure.minLength('password', 6, 'La contraseña debe tener al menos 6 caracteres');
    }

    return null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}

/// Parameters for reset password use case
class ResetPasswordParams extends Equatable {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordParams({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, code, newPassword];

  @override
  String toString() => 'ResetPasswordParams(email: $email, code: $code, newPassword: [HIDDEN])';
}
