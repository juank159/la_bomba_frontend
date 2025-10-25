import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for verifying password reset code
class VerifyResetCodeUseCase {
  final AuthRepository repository;

  VerifyResetCodeUseCase(this.repository);

  /// Execute the verify reset code use case
  /// Takes [VerifyResetCodeParams] and returns [bool] on success or [Failure] on error
  Future<Either<Failure, bool>> call(VerifyResetCodeParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Verify reset code through repository
    return await repository.verifyResetCode(params.email, params.code);
  }

  /// Validate verify reset code parameters
  ValidationFailure? _validateParams(VerifyResetCodeParams params) {
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

    if (!_isNumeric(params.code)) {
      return ValidationFailure.invalid('code', 'El código debe contener solo números');
    }

    return null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Check if string is numeric
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }
}

/// Parameters for verify reset code use case
class VerifyResetCodeParams extends Equatable {
  final String email;
  final String code;

  const VerifyResetCodeParams({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];

  @override
  String toString() => 'VerifyResetCodeParams(email: $email, code: $code)';
}
