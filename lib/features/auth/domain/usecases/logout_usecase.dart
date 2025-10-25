import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case for user logout functionality
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  /// Execute the logout use case
  /// Returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}