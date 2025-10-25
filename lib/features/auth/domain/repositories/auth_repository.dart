import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract repository interface for authentication operations
abstract class AuthRepository {
  /// Authenticate user with email and password
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> login(String email, String password);

  /// Log out current user and clear authentication data
  /// Returns [void] on success, [Failure] on error
  Future<Either<Failure, void>> logout();

  /// Get current authenticated user from local storage
  /// Returns [User] if authenticated, [null] if not authenticated, [Failure] on error
  Future<Either<Failure, User?>> getCurrentUser();

  /// Check if user is currently authenticated
  /// Returns [bool] indicating authentication status, [Failure] on error
  Future<Either<Failure, bool>> isAuthenticated();

  /// Refresh authentication token
  /// Returns [void] on success, [Failure] on error
  Future<Either<Failure, void>> refreshToken();

  /// Clear all authentication data (tokens, user data)
  /// Returns [void] on success, [Failure] on error
  Future<Either<Failure, void>> clearAuthData();

  /// Request password reset code to be sent to email
  /// Returns [Map<String, dynamic>?] on success (may contain code in development), [Failure] on error
  Future<Either<Failure, Map<String, dynamic>?>> requestPasswordReset(String email);

  /// Verify password reset code
  /// Returns [bool] indicating if code is valid, [Failure] on error
  Future<Either<Failure, bool>> verifyResetCode(String email, String code);

  /// Reset password with verified code
  /// Returns [void] on success, [Failure] on error
  Future<Either<Failure, void>> resetPassword(String email, String code, String newPassword);
}