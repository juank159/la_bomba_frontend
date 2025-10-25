import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';
import '../models/request_password_reset_model.dart';
import '../models/verify_reset_code_model.dart';
import '../models/reset_password_model.dart';

/// Implementation of AuthRepository combining remote and local data sources
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final request = LoginRequestModel(email: email, password: password);
      final response = await remoteDataSource.login(request);
      
      // Save login response (tokens and user data) to local storage
      await localDataSource.saveLoginResponse(response);
      
      return Right(response.user.toEntity());
    } on ServerException catch (e) {
      return Left(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Left(_mapNetworkExceptionToFailure(e));
    } on CacheException catch (e) {
      return Left(_mapCacheExceptionToFailure(e));
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error inesperado durante el login: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Try to logout from remote server first
      try {
        await remoteDataSource.logout();
      } catch (e) {
        // If remote logout fails, we still continue with local logout
        // This ensures user can always logout locally even if server is down
      }
      
      // Clear local authentication data
      await localDataSource.clearAuthData();
      
      return const Right(null);
    } on CacheException catch (e) {
      return Left(_mapCacheExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error inesperado durante el logout: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Right(user?.toEntity());
    } on CacheException catch (e) {
      return Left(_mapCacheExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error al obtener usuario actual: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final isAuth = await localDataSource.isAuthenticated();
      return Right(isAuth);
    } on CacheException catch (e) {
      return Left(_mapCacheExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error al verificar autenticación: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> refreshToken() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return Left(AuthFailure.tokenExpired('Token de actualización no encontrado'));
      }

      final response = await remoteDataSource.refreshToken(refreshToken);
      await localDataSource.saveTokens(response.accessToken, response.refreshToken);
      
      return const Right(null);
    } on TokenExpiredException catch (e) {
      // Clear auth data if refresh token is expired
      await localDataSource.clearAuthData();
      return Left(AuthFailure.tokenExpired(e.message));
    } on ServerException catch (e) {
      return Left(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Left(_mapNetworkExceptionToFailure(e));
    } on CacheException catch (e) {
      return Left(_mapCacheExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error al renovar token: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAuthData() async {
    try {
      await localDataSource.clearAuthData();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(_mapCacheExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error al limpiar datos de autenticación: ${e.toString()}'));
    }
  }

  /// Map ServerException to appropriate Failure
  Failure _mapServerExceptionToFailure(ServerException exception) {
    switch (exception.runtimeType) {
      case BadRequestException:
        return ServerFailure.badRequest(exception.message);
      case UnauthorizedException:
        return AuthFailure.invalidCredentials(exception.message);
      case ForbiddenException:
        return AuthFailure.invalidCredentials('Acceso denegado');
      case NotFoundException:
        return ServerFailure.notFound(exception.message);
      case ConflictException:
        return ServerFailure.conflict(exception.message);
      case ValidationException:
        return ValidationFailure.invalid('datos', exception.message);
      case InternalServerException:
        return ServerFailure.internalServer(exception.message);
      case ServiceUnavailableException:
        return ServerFailure.serviceUnavailable(exception.message);
      default:
        return ServerFailure(exception.message);
    }
  }

  /// Map NetworkException to appropriate Failure
  Failure _mapNetworkExceptionToFailure(NetworkException exception) {
    switch (exception.runtimeType) {
      case ConnectionTimeoutException:
        return NetworkFailure.connectionTimeout(exception.message);
      case ConnectionException:
        return NetworkFailure.connectionError(exception.message);
      case NoInternetException:
        return NetworkFailure.noInternet(exception.message);
      default:
        return NetworkFailure(exception.message);
    }
  }

  /// Map CacheException to appropriate Failure
  Failure _mapCacheExceptionToFailure(CacheException exception) {
    switch (exception.runtimeType) {
      case CacheNotFoundException:
        return StorageFailure.notFound(exception.message);
      case CacheWriteException:
        return StorageFailure.writeError(exception.message);
      case CacheReadException:
        return StorageFailure.readError(exception.message);
      default:
        return StorageFailure(exception.message);
    }
  }

  /// Map AuthException to appropriate Failure
  Failure _mapAuthExceptionToFailure(AuthException exception) {
    switch (exception.runtimeType) {
      case InvalidCredentialsException:
        return AuthFailure.invalidCredentials(exception.message);
      case TokenExpiredException:
        return AuthFailure.tokenExpired(exception.message);
      default:
        return AuthFailure(exception.message);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> requestPasswordReset(String email) async {
    try {
      final request = RequestPasswordResetModel(email: email);
      final response = await remoteDataSource.requestPasswordReset(request);
      return Right(response);
    } on ServerException catch (e) {
      return Left(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Left(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error al solicitar recuperación de contraseña: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyResetCode(String email, String code) async {
    try {
      final request = VerifyResetCodeModel(email: email, code: code);
      final isValid = await remoteDataSource.verifyResetCode(request);
      return Right(isValid);
    } on ServerException catch (e) {
      return Left(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Left(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error al verificar código: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email, String code, String newPassword) async {
    try {
      final request = ResetPasswordModel(email: email, code: code, newPassword: newPassword);
      await remoteDataSource.resetPassword(request);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(_mapServerExceptionToFailure(e));
    } on NetworkException catch (e) {
      return Left(_mapNetworkExceptionToFailure(e));
    } catch (e) {
      return Left(UnexpectedFailure.unknown('Error al restablecer contraseña: ${e.toString()}'));
    }
  }
}