import 'package:dio/dio.dart';

import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/config/api_config.dart';
import '../models/client_model.dart';

/// Abstract class defining the contract for clients remote data source
abstract class ClientsRemoteDataSource {
  /// Get all clients with optional pagination and search
  Future<List<ClientModel>> getAllClients({
    int page = 0,
    int limit = 20,
    String? search,
  });

  /// Get a specific client by its ID
  Future<ClientModel> getClientById(String id);

  /// Search clients by name, phone, email or address
  Future<List<ClientModel>> searchClients(
    String query, {
    int page = 0,
    int limit = 20,
  });

  /// Get total count of clients
  Future<int> getClientsCount({String? search});

  /// Create a new client
  Future<ClientModel> createClient(Map<String, dynamic> clientData);

  /// Update a client's information
  Future<ClientModel> updateClient(String id, Map<String, dynamic> updatedData);

  /// Delete a client (soft delete)
  Future<void> deleteClient(String id);
}

/// Implementation of ClientsRemoteDataSource using Dio HTTP client
class ClientsRemoteDataSourceImpl implements ClientsRemoteDataSource {
  final DioClient dioClient;

  ClientsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<ClientModel>> getAllClients({
    int page = 0,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final response = await dioClient.get(
        ApiConfig.clientsEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response formats
        List<dynamic> clientsData;
        if (responseData is Map<String, dynamic>) {
          // If response has pagination metadata
          if (responseData.containsKey('data')) {
            clientsData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('clients')) {
            clientsData = responseData['clients'] as List<dynamic>;
          } else {
            // Assume the map itself contains client data
            clientsData = [responseData];
          }
        } else if (responseData is List<dynamic>) {
          clientsData = responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }

        return clientsData
            .map((json) => ClientModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener clientes: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al obtener clientes');
    } catch (e) {
      throw ServerException('Error inesperado al obtener clientes: $e');
    }
  }

  @override
  Future<ClientModel> getClientById(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del cliente es requerido');
      }

      final response = await dioClient.get(
        '${ApiConfig.clientsEndpoint}/by-id/$id',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return ClientModel.fromJson(responseData);
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Cliente con ID $id no encontrado');
      } else {
        throw ServerException(
          'Error al obtener cliente: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Cliente con ID $id no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al obtener cliente');
    } catch (e) {
      throw ServerException('Error inesperado al obtener cliente: $e');
    }
  }

  @override
  Future<List<ClientModel>> searchClients(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        throw ValidationException('El término de búsqueda es requerido');
      }

      return await getAllClients(
        page: page,
        limit: limit,
        search: query.trim(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Error inesperado al buscar clientes: $e');
    }
  }

  @override
  Future<int> getClientsCount({String? search}) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final response = await dioClient.get(
        '${ApiConfig.clientsEndpoint}/count',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return responseData['count'] as int? ??
              responseData['total'] as int? ??
              0;
        } else if (responseData is int) {
          return responseData;
        } else {
          throw ParseException('Formato de respuesta inválido para conteo');
        }
      } else {
        throw ServerException(
          'Error al obtener conteo de clientes: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(
        e,
        'Error al obtener conteo de clientes',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener conteo: $e');
    }
  }

  @override
  Future<ClientModel> createClient(Map<String, dynamic> clientData) async {
    try {
      if (clientData.isEmpty) {
        throw ValidationException('Los datos del cliente son requeridos');
      }

      if (!clientData.containsKey('nombre') ||
          (clientData['nombre'] as String).trim().isEmpty) {
        throw ValidationException('El nombre del cliente es obligatorio');
      }

      final response = await dioClient.post(
        ApiConfig.clientsEndpoint,
        data: clientData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return ClientModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para creación de cliente',
          );
        }
      } else if (response.statusCode == 409) {
        throw ConflictException(
          'Ya existe un cliente con ese nombre o celular',
        );
      } else {
        throw ServerException(
          'Error al crear cliente: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final message =
            e.response?.data?['message'] as String? ??
            'Ya existe un cliente con ese nombre o celular';
        throw ConflictException(message);
      }
      throw _mapDioExceptionToServerException(e, 'Error al crear cliente');
    } catch (e) {
      throw ServerException('Error inesperado al crear cliente: $e');
    }
  }

  @override
  Future<ClientModel> updateClient(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del cliente es requerido');
      }

      if (updatedData.isEmpty) {
        throw ValidationException('Los datos de actualización son requeridos');
      }

      final url = '${ApiConfig.clientsEndpoint}/by-id/$id';

      final response = await dioClient.patch(url, data: updatedData);

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return ClientModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para actualización de cliente',
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Cliente con ID $id no encontrado');
      } else if (response.statusCode == 409) {
        throw ConflictException(
          'Ya existe un cliente con ese nombre o celular',
        );
      } else {
        throw ServerException(
          'Error al actualizar cliente: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Cliente con ID $id no encontrado');
      }
      if (e.response?.statusCode == 409) {
        final message =
            e.response?.data?['message'] as String? ??
            'Ya existe un cliente con ese nombre o celular';
        throw ConflictException(message);
      }
      throw _mapDioExceptionToServerException(e, 'Error al actualizar cliente');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar cliente: $e');
    }
  }

  @override
  Future<void> deleteClient(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del cliente es requerido');
      }

      final response = await dioClient.delete(
        '${ApiConfig.clientsEndpoint}/by-id/$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        if (response.statusCode == 404) {
          throw NotFoundException('Cliente con ID $id no encontrado');
        }
        throw ServerException(
          'Error al eliminar cliente: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Cliente con ID $id no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al eliminar cliente');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar cliente: $e');
    }
  }

  /// Helper method to map DioException to ServerException
  ServerException _mapDioExceptionToServerException(
    DioException dioException,
    String contextMessage,
  ) {
    final statusCode = dioException.response?.statusCode ?? 0;
    final errorMessage =
        dioException.response?.data?['message'] as String? ??
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
        return ConflictException(errorMessage);
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
          return ServerException('Error de conexión: $contextMessage', statusCode: 503);
        } else {
          return ServerException(
            '$contextMessage: $errorMessage',
            statusCode: statusCode,
          );
        }
    }
  }
}
