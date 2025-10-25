import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for requesting password reset code
class RequestPasswordResetUseCase {
  final AuthRepository repository;

  RequestPasswordResetUseCase(this.repository);

  /// Execute the request password reset use case
  /// Takes [RequestPasswordResetParams] and returns [Map<String, dynamic>?] on success or [Failure] on error
  Future<Either<Failure, Map<String, dynamic>?>> call(RequestPasswordResetParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Request password reset through repository
    return await repository.requestPasswordReset(params.email);
  }

  /// Validate request password reset parameters
  ValidationFailure? _validateParams(RequestPasswordResetParams params) {
    if (params.email.isEmpty) {
      return ValidationFailure.required('email', 'El email es requerido');
    }

    if (!_isValidEmail(params.email)) {
      return ValidationFailure.format('email', 'El formato del email es inválido');
    }

    return null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}

/// Parameters for request password reset use case
class RequestPasswordResetParams extends Equatable {
  final String email;

  const RequestPasswordResetParams({required this.email});

  @override
  List<Object?> get props => [email];

  @override
  String toString() => 'RequestPasswordResetParams(email: $email)';
}
