// lib/features/credits/data/datasources/credits_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/config/api_config.dart';
import '../models/credit_model.dart';

/// Abstract class defining the contract for credits remote data source
abstract class CreditsRemoteDataSource {
  /// Get all credits
  Future<List<CreditModel>> getAllCredits();

  /// Get a specific credit by its ID with payments
  Future<CreditModel> getCreditById(String id);

  /// Create a new credit
  Future<CreditModel> createCredit(Map<String, dynamic> creditData);

  /// Update a credit's information
  Future<CreditModel> updateCredit(String id, Map<String, dynamic> updatedData);

  /// Add a payment to a credit
  Future<CreditModel> addPayment(String creditId, Map<String, dynamic> paymentData);

  /// Delete a payment from a credit
  Future<CreditModel> removePayment(String creditId, String paymentId);

  /// Delete a credit
  Future<void> deleteCredit(String id);

  /// Get pending credit for a client
  Future<CreditModel?> getPendingCreditByClient(String clientId);

  /// Add amount to an existing credit
  Future<CreditModel> addAmountToCredit(
    String creditId,
    double amount,
    String description,
  );
}

/// Implementation of CreditsRemoteDataSource using Dio HTTP client
class CreditsRemoteDataSourceImpl implements CreditsRemoteDataSource {
  final DioClient dioClient;

  CreditsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<CreditModel>> getAllCredits() async {
    try {
      final response = await dioClient.get(ApiConfig.creditsEndpoint);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response formats
        List<dynamic> creditsData;
        if (responseData is Map<String, dynamic>) {
          // If response has metadata
          if (responseData.containsKey('data')) {
            creditsData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('credits')) {
            creditsData = responseData['credits'] as List<dynamic>;
          } else {
            // Assume the map itself contains credit data
            creditsData = [responseData];
          }
        } else if (responseData is List<dynamic>) {
          creditsData = responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }

        return creditsData
            .map((json) => CreditModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener créditos: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al obtener créditos');
    } catch (e) {
      throw ServerException('Error inesperado al obtener créditos: $e');
    }
  }

  @override
  Future<CreditModel> getCreditById(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del crédito es requerido');
      }

      final response = await dioClient.get(
        '${ApiConfig.creditsEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return CreditModel.fromJson(responseData);
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Crédito con ID $id no encontrado');
      } else {
        throw ServerException(
          'Error al obtener crédito: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Crédito con ID $id no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al obtener crédito');
    } catch (e) {
      throw ServerException('Error inesperado al obtener crédito: $e');
    }
  }

  @override
  Future<CreditModel> createCredit(Map<String, dynamic> creditData) async {
    try {
      if (creditData.isEmpty) {
        throw ValidationException('Los datos del crédito son requeridos');
      }

      if (!creditData.containsKey('clientId') ||
          (creditData['clientId'] as String).trim().isEmpty) {
        throw ValidationException('El ID del cliente es obligatorio');
      }

      if (!creditData.containsKey('description') ||
          (creditData['description'] as String).trim().isEmpty) {
        throw ValidationException('La descripción es obligatoria');
      }

      if (!creditData.containsKey('totalAmount')) {
        throw ValidationException('El monto total es obligatorio');
      }

      final response = await dioClient.post(
        ApiConfig.creditsEndpoint,
        data: creditData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return CreditModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para creación de crédito',
          );
        }
      } else {
        throw ServerException(
          'Error al crear crédito: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al crear crédito');
    } catch (e) {
      throw ServerException('Error inesperado al crear crédito: $e');
    }
  }

  @override
  Future<CreditModel> updateCredit(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del crédito es requerido');
      }

      if (updatedData.isEmpty) {
        throw ValidationException('Los datos de actualización son requeridos');
      }

      final response = await dioClient.patch(
        '${ApiConfig.creditsEndpoint}/$id',
        data: updatedData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return CreditModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para actualización de crédito',
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Crédito con ID $id no encontrado');
      } else {
        throw ServerException(
          'Error al actualizar crédito: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Crédito con ID $id no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al actualizar crédito');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar crédito: $e');
    }
  }

  @override
  Future<CreditModel> addPayment(
    String creditId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      if (creditId.trim().isEmpty) {
        throw ValidationException('El ID del crédito es requerido');
      }

      if (paymentData.isEmpty) {
        throw ValidationException('Los datos del pago son requeridos');
      }

      if (!paymentData.containsKey('amount')) {
        throw ValidationException('El monto del pago es obligatorio');
      }

      final response = await dioClient.post(
        '${ApiConfig.creditsEndpoint}/$creditId/payments',
        data: paymentData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return CreditModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para agregar pago',
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Crédito con ID $creditId no encontrado');
      } else if (response.statusCode == 400) {
        final message = response.data?['message'] as String? ??
            'El monto del pago excede el saldo pendiente';
        throw BadRequestException(message);
      } else {
        throw ServerException(
          'Error al agregar pago: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Crédito con ID $creditId no encontrado');
      }
      if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message'] as String? ??
            'El monto del pago excede el saldo pendiente';
        throw BadRequestException(message);
      }
      throw _mapDioExceptionToServerException(e, 'Error al agregar pago');
    } catch (e) {
      throw ServerException('Error inesperado al agregar pago: $e');
    }
  }

  @override
  Future<CreditModel> removePayment(String creditId, String paymentId) async {
    try {
      if (creditId.trim().isEmpty) {
        throw ValidationException('El ID del crédito es requerido');
      }

      if (paymentId.trim().isEmpty) {
        throw ValidationException('El ID del pago es requerido');
      }

      final response = await dioClient.delete(
        '${ApiConfig.creditsEndpoint}/$creditId/payments/$paymentId',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return CreditModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para eliminar pago',
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Pago no encontrado');
      } else {
        throw ServerException(
          'Error al eliminar pago: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Pago no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al eliminar pago');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar pago: $e');
    }
  }

  @override
  Future<void> deleteCredit(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del crédito es requerido');
      }

      final response = await dioClient.delete(
        '${ApiConfig.creditsEndpoint}/$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        if (response.statusCode == 404) {
          throw NotFoundException('Crédito con ID $id no encontrado');
        }
        throw ServerException(
          'Error al eliminar crédito: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Crédito con ID $id no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al eliminar crédito');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar crédito: $e');
    }
  }

  @override
  Future<CreditModel?> getPendingCreditByClient(String clientId) async {
    try {
      if (clientId.trim().isEmpty) {
        throw ValidationException('El ID del cliente es requerido');
      }

      final response = await dioClient.get(
        '${ApiConfig.creditsEndpoint}/client/$clientId/pending',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Si no hay crédito pendiente, el backend devuelve null
        if (responseData == null) {
          return null;
        }

        if (responseData is Map<String, dynamic>) {
          return CreditModel.fromJson(responseData);
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ServerException(
          'Error al obtener crédito pendiente: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _mapDioExceptionToServerException(
        e,
        'Error al obtener crédito pendiente',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener crédito pendiente: $e');
    }
  }

  @override
  Future<CreditModel> addAmountToCredit(
    String creditId,
    double amount,
    String description,
  ) async {
    try {
      if (creditId.trim().isEmpty) {
        throw ValidationException('El ID del crédito es requerido');
      }

      if (amount <= 0) {
        throw ValidationException('El monto debe ser mayor a cero');
      }

      if (description.trim().isEmpty) {
        throw ValidationException('La descripción es requerida');
      }

      final response = await dioClient.post(
        '${ApiConfig.creditsEndpoint}/$creditId/add-amount',
        data: {
          'amount': amount,
          'description': description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return CreditModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para agregar monto',
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Crédito con ID $creditId no encontrado');
      } else if (response.statusCode == 400) {
        final message = response.data?['message'] as String? ??
            'No se puede agregar monto a este crédito';
        throw BadRequestException(message);
      } else {
        throw ServerException(
          'Error al agregar monto: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Crédito con ID $creditId no encontrado');
      }
      if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message'] as String? ??
            'No se puede agregar monto a este crédito';
        throw BadRequestException(message);
      }
      throw _mapDioExceptionToServerException(e, 'Error al agregar monto');
    } catch (e) {
      throw ServerException('Error inesperado al agregar monto: $e');
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
              'Error de conexión: $contextMessage', statusCode: 503);
        } else {
          return ServerException(
            '$contextMessage: $errorMessage',
            statusCode: statusCode,
          );
        }
    }
  }
}
