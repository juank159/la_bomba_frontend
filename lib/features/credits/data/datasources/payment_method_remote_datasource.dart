// lib/features/credits/data/datasources/payment_method_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../models/payment_method_model.dart';

/// DataSource remoto para operaciones de métodos de pago
abstract class PaymentMethodRemoteDataSource {
  Future<List<PaymentMethodModel>> getAllPaymentMethods();
  Future<PaymentMethodModel> getPaymentMethodById(String id);
  Future<PaymentMethodModel> createPaymentMethod({
    required String name,
    String? description,
    String? icon,
  });
  Future<PaymentMethodModel> updatePaymentMethod({
    required String id,
    String? name,
    String? description,
    String? icon,
  });
  Future<void> deletePaymentMethod(String id);
  Future<PaymentMethodModel> activatePaymentMethod({
    required String id,
    required bool isActive,
  });
}

class PaymentMethodRemoteDataSourceImpl
    implements PaymentMethodRemoteDataSource {
  final DioClient dioClient;

  PaymentMethodRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<PaymentMethodModel>> getAllPaymentMethods() async {
    try {
      final response = await dioClient.get('/payment-methods');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList
            .map((json) => PaymentMethodModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener métodos de pago: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(
        e,
        'Error al obtener métodos de pago',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener métodos de pago: $e');
    }
  }

  @override
  Future<PaymentMethodModel> getPaymentMethodById(String id) async {
    try {
      final response = await dioClient.get('/payment-methods/$id');

      if (response.statusCode == 200) {
        return PaymentMethodModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Método de pago no encontrado');
      } else {
        throw ServerException(
          'Error al obtener método de pago: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Método de pago no encontrado');
      }
      throw _mapDioExceptionToServerException(
        e,
        'Error al obtener método de pago',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener método de pago: $e');
    }
  }

  @override
  Future<PaymentMethodModel> createPaymentMethod({
    required String name,
    String? description,
    String? icon,
  }) async {
    try {
      final body = {
        'name': name,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
      };

      final response = await dioClient.post(
        '/payment-methods',
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentMethodModel.fromJson(response.data);
      } else if (response.statusCode == 400) {
        final message = response.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      } else if (response.statusCode == 409) {
        throw ValidationException('Ya existe un método de pago con ese nombre');
      } else {
        throw ServerException(
          'Error al crear método de pago: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 409) {
        final message = e.response?.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      }
      throw _mapDioExceptionToServerException(
        e,
        'Error al crear método de pago',
      );
    } catch (e) {
      throw ServerException('Error inesperado al crear método de pago: $e');
    }
  }

  @override
  Future<PaymentMethodModel> updatePaymentMethod({
    required String id,
    String? name,
    String? description,
    String? icon,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (icon != null) body['icon'] = icon;

      final response = await dioClient.put(
        '/payment-methods/$id',
        data: body,
      );

      if (response.statusCode == 200) {
        return PaymentMethodModel.fromJson(response.data);
      } else if (response.statusCode == 400) {
        final message = response.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Método de pago no encontrado');
      } else if (response.statusCode == 409) {
        throw ValidationException('Ya existe un método de pago con ese nombre');
      } else {
        throw ServerException(
          'Error al actualizar método de pago: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 409) {
        final message = e.response?.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      }
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Método de pago no encontrado');
      }
      throw _mapDioExceptionToServerException(
        e,
        'Error al actualizar método de pago',
      );
    } catch (e) {
      throw ServerException('Error inesperado al actualizar método de pago: $e');
    }
  }

  @override
  Future<void> deletePaymentMethod(String id) async {
    try {
      final response = await dioClient.delete('/payment-methods/$id');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw NotFoundException('Método de pago no encontrado');
      } else {
        throw ServerException(
          'Error al eliminar método de pago: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Método de pago no encontrado');
      }
      throw _mapDioExceptionToServerException(
        e,
        'Error al eliminar método de pago',
      );
    } catch (e) {
      throw ServerException('Error inesperado al eliminar método de pago: $e');
    }
  }

  @override
  Future<PaymentMethodModel> activatePaymentMethod({
    required String id,
    required bool isActive,
  }) async {
    try {
      final body = {'isActive': isActive};

      final response = await dioClient.put(
        '/payment-methods/$id/activate',
        data: body,
      );

      if (response.statusCode == 200) {
        return PaymentMethodModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Método de pago no encontrado');
      } else {
        throw ServerException(
          'Error al cambiar estado del método de pago: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Método de pago no encontrado');
      }
      throw _mapDioExceptionToServerException(
        e,
        'Error al cambiar estado del método de pago',
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al cambiar estado del método de pago: $e',
      );
    }
  }

  /// Helper method to map DioException to ServerException
  ServerException _mapDioExceptionToServerException(
    DioException dioException,
    String contextMessage,
  ) {
    final statusCode = dioException.response?.statusCode ?? 0;
    final errorMessage = dioException.response?.data?['message'] as String? ??
        dioException.message ??
        contextMessage;

    switch (statusCode) {
      case 400:
        return BadRequestException(errorMessage);
      case 401:
        return UnauthorizedException(errorMessage);
      case 403:
        return ForbiddenException(errorMessage);
      case 404:
        return NotFoundException(errorMessage);
      case 409:
        return ValidationException(errorMessage);
      case 422:
        return ValidationException(errorMessage);
      case 500:
        return InternalServerException(errorMessage);
      case 502:
        return BadGatewayException(errorMessage);
      case 503:
        return ServiceUnavailableException(errorMessage);
      default:
        if (dioException.type == DioExceptionType.connectionTimeout ||
            dioException.type == DioExceptionType.receiveTimeout ||
            dioException.type == DioExceptionType.sendTimeout) {
          return ServerException('Timeout: $contextMessage', statusCode: 408);
        } else if (dioException.type == DioExceptionType.connectionError) {
          return ServerException(
            'Error de conexión: $contextMessage',
            statusCode: 503,
          );
        } else {
          return ServerException(
            '$contextMessage: $errorMessage',
            statusCode: statusCode,
          );
        }
    }
  }
}
