/// Failure classes for the Pedidos application
/// These failures are returned from use cases and represent business logic errors

/// Base failure class for all failures in the domain layer
abstract class Failure {
  final String message;
  final String? code;
  final Exception? exception;
  
  const Failure(this.message, {this.code, this.exception});
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code &&
        other.exception == exception;
  }
  
  @override
  int get hashCode => message.hashCode ^ code.hashCode ^ exception.hashCode;
  
  @override
  String toString() {
    return 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.exception});
  
  factory ServerFailure.badRequest([String? message]) {
    return ServerFailure(
      message ?? 'Solicitud incorrecta',
      code: '400',
    );
  }
  
  factory ServerFailure.unauthorized([String? message]) {
    return ServerFailure(
      message ?? 'No autorizado',
      code: '401',
    );
  }
  
  factory ServerFailure.forbidden([String? message]) {
    return ServerFailure(
      message ?? 'Acceso denegado',
      code: '403',
    );
  }
  
  factory ServerFailure.notFound([String? message]) {
    return ServerFailure(
      message ?? 'Recurso no encontrado',
      code: '404',
    );
  }
  
  factory ServerFailure.conflict([String? message]) {
    return ServerFailure(
      message ?? 'Conflicto en el servidor',
      code: '409',
    );
  }
  
  factory ServerFailure.validationError([String? message]) {
    return ServerFailure(
      message ?? 'Error de validación',
      code: '422',
    );
  }
  
  factory ServerFailure.internalServer([String? message]) {
    return ServerFailure(
      message ?? 'Error interno del servidor',
      code: '500',
    );
  }
  
  factory ServerFailure.badGateway([String? message]) {
    return ServerFailure(
      message ?? 'Error de gateway',
      code: '502',
    );
  }
  
  factory ServerFailure.serviceUnavailable([String? message]) {
    return ServerFailure(
      message ?? 'Servicio no disponible',
      code: '503',
    );
  }
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.exception});
  
  factory NetworkFailure.connectionTimeout([String? message]) {
    return NetworkFailure(
      message ?? 'Tiempo de conexión agotado',
      code: 'CONNECTION_TIMEOUT',
    );
  }
  
  factory NetworkFailure.connectionError([String? message]) {
    return NetworkFailure(
      message ?? 'Error de conexión',
      code: 'CONNECTION_ERROR',
    );
  }
  
  factory NetworkFailure.noInternet([String? message]) {
    return NetworkFailure(
      message ?? 'Sin conexión a internet',
      code: 'NO_INTERNET',
    );
  }
  
  factory NetworkFailure.requestCancelled([String? message]) {
    return NetworkFailure(
      message ?? 'Solicitud cancelada',
      code: 'REQUEST_CANCELLED',
    );
  }
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.exception});
  
  factory CacheFailure.notFound([String? message]) {
    return CacheFailure(
      message ?? 'Datos no encontrados en caché',
      code: 'CACHE_NOT_FOUND',
    );
  }
  
  factory CacheFailure.writeError([String? message]) {
    return CacheFailure(
      message ?? 'Error al escribir en caché',
      code: 'CACHE_WRITE_ERROR',
    );
  }
  
  factory CacheFailure.readError([String? message]) {
    return CacheFailure(
      message ?? 'Error al leer de caché',
      code: 'CACHE_READ_ERROR',
    );
  }
  
  factory CacheFailure.expired([String? message]) {
    return CacheFailure(
      message ?? 'Datos de caché expirados',
      code: 'CACHE_EXPIRED',
    );
  }
}

/// Storage-related failures
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code, super.exception});
  
  factory StorageFailure.accessDenied([String? message]) {
    return StorageFailure(
      message ?? 'Acceso denegado al almacenamiento',
      code: 'STORAGE_ACCESS_DENIED',
    );
  }
  
  factory StorageFailure.writeError([String? message]) {
    return StorageFailure(
      message ?? 'Error al escribir en almacenamiento',
      code: 'STORAGE_WRITE_ERROR',
    );
  }
  
  factory StorageFailure.readError([String? message]) {
    return StorageFailure(
      message ?? 'Error al leer del almacenamiento',
      code: 'STORAGE_READ_ERROR',
    );
  }
  
  factory StorageFailure.notFound([String? message]) {
    return StorageFailure(
      message ?? 'Datos no encontrados en almacenamiento',
      code: 'STORAGE_NOT_FOUND',
    );
  }
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.exception});
  
  factory AuthFailure.invalidCredentials([String? message]) {
    return AuthFailure(
      message ?? 'Credenciales inválidas',
      code: 'INVALID_CREDENTIALS',
    );
  }
  
  factory AuthFailure.userNotFound([String? message]) {
    return AuthFailure(
      message ?? 'Usuario no encontrado',
      code: 'USER_NOT_FOUND',
    );
  }
  
  factory AuthFailure.tokenExpired([String? message]) {
    return AuthFailure(
      message ?? 'Token expirado',
      code: 'TOKEN_EXPIRED',
    );
  }
  
  factory AuthFailure.userAlreadyExists([String? message]) {
    return AuthFailure(
      message ?? 'Usuario ya existe',
      code: 'USER_ALREADY_EXISTS',
    );
  }
  
  factory AuthFailure.accountDisabled([String? message]) {
    return AuthFailure(
      message ?? 'Cuenta deshabilitada',
      code: 'ACCOUNT_DISABLED',
    );
  }
  
  factory AuthFailure.sessionExpired([String? message]) {
    return AuthFailure(
      message ?? 'Sesión expirada',
      code: 'SESSION_EXPIRED',
    );
  }
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.exception});
  
  factory ValidationFailure.required(String field, [String? message]) {
    return ValidationFailure(
      message ?? 'El campo $field es requerido',
      code: 'FIELD_REQUIRED',
    );
  }
  
  factory ValidationFailure.invalid(String field, [String? message]) {
    return ValidationFailure(
      message ?? 'El campo $field no es válido',
      code: 'FIELD_INVALID',
    );
  }
  
  factory ValidationFailure.minLength(String field, int minLength, [String? message]) {
    return ValidationFailure(
      message ?? 'El campo $field debe tener al menos $minLength caracteres',
      code: 'FIELD_MIN_LENGTH',
    );
  }
  
  factory ValidationFailure.maxLength(String field, int maxLength, [String? message]) {
    return ValidationFailure(
      message ?? 'El campo $field no puede tener más de $maxLength caracteres',
      code: 'FIELD_MAX_LENGTH',
    );
  }
  
  factory ValidationFailure.format(String field, [String? message]) {
    return ValidationFailure(
      message ?? 'El formato del campo $field es incorrecto',
      code: 'FIELD_FORMAT',
    );
  }
}

/// Parsing-related failures
class ParseFailure extends Failure {
  const ParseFailure(super.message, {super.code, super.exception});
  
  factory ParseFailure.json([String? message]) {
    return ParseFailure(
      message ?? 'Error al parsear JSON',
      code: 'JSON_PARSE_ERROR',
    );
  }
  
  factory ParseFailure.invalidFormat([String? message]) {
    return ParseFailure(
      message ?? 'Formato de datos inválido',
      code: 'INVALID_FORMAT',
    );
  }
  
  factory ParseFailure.missingField(String field, [String? message]) {
    return ParseFailure(
      message ?? 'Campo requerido faltante: $field',
      code: 'MISSING_FIELD',
    );
  }
}

/// Business logic failures
class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure(super.message, {super.code, super.exception});
  
  factory BusinessLogicFailure.operationNotAllowed([String? message]) {
    return BusinessLogicFailure(
      message ?? 'Operación no permitida',
      code: 'OPERATION_NOT_ALLOWED',
    );
  }
  
  factory BusinessLogicFailure.insufficientPermissions([String? message]) {
    return BusinessLogicFailure(
      message ?? 'Permisos insuficientes',
      code: 'INSUFFICIENT_PERMISSIONS',
    );
  }
  
  factory BusinessLogicFailure.resourceNotAvailable([String? message]) {
    return BusinessLogicFailure(
      message ?? 'Recurso no disponible',
      code: 'RESOURCE_NOT_AVAILABLE',
    );
  }
  
  factory BusinessLogicFailure.operationFailed([String? message]) {
    return BusinessLogicFailure(
      message ?? 'Operación fallida',
      code: 'OPERATION_FAILED',
    );
  }
}

/// Generic failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.code, super.exception});
  
  factory UnexpectedFailure.unknown([String? message]) {
    return UnexpectedFailure(
      message ?? 'Error inesperado',
      code: 'UNKNOWN_ERROR',
    );
  }
}