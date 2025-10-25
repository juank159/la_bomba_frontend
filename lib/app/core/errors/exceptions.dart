/// Custom exceptions for the Pedidos application
/// These exceptions are thrown in the data layer and converted to failures in the domain layer

/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppException(this.message, {this.code, this.originalError});
  
  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Server-related exceptions
class ServerException extends AppException {
  final int? statusCode;
  
  const ServerException(
    super.message, {
    super.code,
    super.originalError,
    this.statusCode,
  });
  
  factory ServerException.fromResponse(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return BadRequestException(message);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      case 422:
        return ValidationException(message);
      case 500:
        return InternalServerException(message);
      case 502:
        return BadGatewayException(message);
      case 503:
        return ServiceUnavailableException(message);
      default:
        return ServerException(message, code: statusCode.toString());
    }
  }
}

/// Bad request exception (400)
class BadRequestException extends ServerException {
  const BadRequestException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Unauthorized exception (401)
class UnauthorizedException extends ServerException {
  const UnauthorizedException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Forbidden exception (403)
class ForbiddenException extends ServerException {
  const ForbiddenException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Not found exception (404)
class NotFoundException extends ServerException {
  const NotFoundException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Conflict exception (409)
class ConflictException extends ServerException {
  const ConflictException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Validation exception (422)
class ValidationException extends ServerException {
  const ValidationException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Internal server error exception (500)
class InternalServerException extends ServerException {
  const InternalServerException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Bad gateway exception (502)
class BadGatewayException extends ServerException {
  const BadGatewayException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Service unavailable exception (503)
class ServiceUnavailableException extends ServerException {
  const ServiceUnavailableException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Client-side error exception (4xx)
class ClientException extends ServerException {
  const ClientException(super.message, {super.code, super.originalError, super.statusCode});
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

/// Connection timeout exception
class ConnectionTimeoutException extends NetworkException {
  const ConnectionTimeoutException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Connection error exception
class ConnectionException extends NetworkException {
  const ConnectionException(super.message, {super.code, super.originalError});
}

/// No internet connection exception
class NoInternetException extends NetworkException {
  const NoInternetException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.originalError});
}

/// Cache not found exception
class CacheNotFoundException extends CacheException {
  const CacheNotFoundException(super.message, {super.code, super.originalError});
}

/// Cache write exception
class CacheWriteException extends CacheException {
  const CacheWriteException(super.message, {super.code, super.originalError});
}

/// Cache read exception
class CacheReadException extends CacheException {
  const CacheReadException(super.message, {super.code, super.originalError});
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

/// Secure storage exception
class SecureStorageException extends StorageException {
  const SecureStorageException(super.message, {super.code, super.originalError});
}

/// Parsing-related exceptions
class ParseException extends AppException {
  const ParseException(super.message, {super.code, super.originalError});
}

/// JSON parsing exception
class JsonParseException extends ParseException {
  const JsonParseException(super.message, {super.code, super.originalError});
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Token expired exception
class TokenExpiredException extends AuthException {
  const TokenExpiredException(super.message, {super.code, super.originalError});
}

/// Invalid credentials exception
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException(super.message, {super.code, super.originalError});
}

/// Business logic exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException(super.message, {super.code, super.originalError});
}

/// Permission denied exception
class PermissionDeniedException extends BusinessLogicException {
  const PermissionDeniedException(super.message, {super.code, super.originalError});
}

/// Resource not available exception
class ResourceNotAvailableException extends BusinessLogicException {
  const ResourceNotAvailableException(super.message, {super.code, super.originalError});
}