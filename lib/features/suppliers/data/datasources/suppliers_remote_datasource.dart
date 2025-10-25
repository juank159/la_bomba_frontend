import 'package:dio/dio.dart';

import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/config/api_config.dart';
import '../models/supplier_model.dart';

/// Abstract class defining the contract for suppliers remote data source
abstract class SuppliersRemoteDataSource {
  /// Get all suppliers with optional pagination and search
  Future<List<SupplierModel>> getAllSuppliers({
    int page = 0,
    int limit = 20,
    String? search,
  });

  /// Get a specific supplier by its ID
  Future<SupplierModel> getSupplierById(String id);

  /// Search suppliers by name, phone, email or address
  Future<List<SupplierModel>> searchSuppliers(
    String query, {
    int page = 0,
    int limit = 20,
  });

  /// Get total count of suppliers
  Future<int> getSuppliersCount({String? search});

  /// Create a new supplier
  Future<SupplierModel> createSupplier(Map<String, dynamic> supplierData);

  /// Update a supplier's information
  Future<SupplierModel> updateSupplier(String id, Map<String, dynamic> updatedData);

  /// Delete a supplier (soft delete)
  Future<void> deleteSupplier(String id);
}

/// Implementation of SuppliersRemoteDataSource using Dio HTTP client
class SuppliersRemoteDataSourceImpl implements SuppliersRemoteDataSource {
  final DioClient dioClient;

  SuppliersRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<SupplierModel>> getAllSuppliers({
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
        ApiConfig.suppliersEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response formats
        List<dynamic> suppliersData;
        if (responseData is Map<String, dynamic>) {
          // If response has pagination metadata
          if (responseData.containsKey('data')) {
            suppliersData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('suppliers')) {
            suppliersData = responseData['suppliers'] as List<dynamic>;
          } else {
            // Assume the map itself contains supplier data
            suppliersData = [responseData];
          }
        } else if (responseData is List<dynamic>) {
          suppliersData = responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }

        return suppliersData
            .map((json) => SupplierModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener proveedores: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al obtener proveedores');
    } catch (e) {
      throw ServerException('Error inesperado al obtener proveedores: $e');
    }
  }

  @override
  Future<SupplierModel> getSupplierById(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del proveedor es requerido');
      }

      final response = await dioClient.get(
        '${ApiConfig.suppliersEndpoint}/by-id/$id',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return SupplierModel.fromJson(responseData);
        } else {
          throw ParseException('Formato de respuesta inválido');
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Proveedor con ID $id no encontrado');
      } else {
        throw ServerException(
          'Error al obtener proveedor: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Proveedor con ID $id no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al obtener proveedor');
    } catch (e) {
      throw ServerException('Error inesperado al obtener proveedor: $e');
    }
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        throw ValidationException('El término de búsqueda es requerido');
      }

      return await getAllSuppliers(
        page: page,
        limit: limit,
        search: query.trim(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Error inesperado al buscar proveedores: $e');
    }
  }

  @override
  Future<int> getSuppliersCount({String? search}) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final response = await dioClient.get(
        '${ApiConfig.suppliersEndpoint}/count',
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
          'Error al obtener conteo de proveedores: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(
        e,
        'Error al obtener conteo de proveedores',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener conteo: $e');
    }
  }

  @override
  Future<SupplierModel> createSupplier(Map<String, dynamic> supplierData) async {
    try {
      if (supplierData.isEmpty) {
        throw ValidationException('Los datos del proveedor son requeridos');
      }

      if (!supplierData.containsKey('nombre') ||
          (supplierData['nombre'] as String).trim().isEmpty) {
        throw ValidationException('El nombre del proveedor es obligatorio');
      }

      final response = await dioClient.post(
        ApiConfig.suppliersEndpoint,
        data: supplierData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return SupplierModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para creación de proveedor',
          );
        }
      } else if (response.statusCode == 409) {
        throw ConflictException(
          'Ya existe un proveedor con ese nombre o celular',
        );
      } else {
        throw ServerException(
          'Error al crear proveedor: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final message =
            e.response?.data?['message'] as String? ??
            'Ya existe un proveedor con ese nombre o celular';
        throw ConflictException(message);
      }
      throw _mapDioExceptionToServerException(e, 'Error al crear proveedor');
    } catch (e) {
      throw ServerException('Error inesperado al crear proveedor: $e');
    }
  }

  @override
  Future<SupplierModel> updateSupplier(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del proveedor es requerido');
      }

      if (updatedData.isEmpty) {
        throw ValidationException('Los datos de actualización son requeridos');
      }

      final url = '${ApiConfig.suppliersEndpoint}/by-id/$id';

      final response = await dioClient.patch(url, data: updatedData);

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          return SupplierModel.fromJson(responseData);
        } else {
          throw ParseException(
            'Formato de respuesta inválido para actualización de proveedor',
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException('Proveedor con ID $id no encontrado');
      } else if (response.statusCode == 409) {
        throw ConflictException(
          'Ya existe un proveedor con ese nombre o celular',
        );
      } else {
        throw ServerException(
          'Error al actualizar proveedor: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Proveedor con ID $id no encontrado');
      }
      if (e.response?.statusCode == 409) {
        final message =
            e.response?.data?['message'] as String? ??
            'Ya existe un proveedor con ese nombre o celular';
        throw ConflictException(message);
      }
      throw _mapDioExceptionToServerException(e, 'Error al actualizar proveedor');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar proveedor: $e');
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del proveedor es requerido');
      }

      final response = await dioClient.delete(
        '${ApiConfig.suppliersEndpoint}/by-id/$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        if (response.statusCode == 404) {
          throw NotFoundException('Proveedor con ID $id no encontrado');
        }
        throw ServerException(
          'Error al eliminar proveedor: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Proveedor con ID $id no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al eliminar proveedor');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar proveedor: $e');
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
