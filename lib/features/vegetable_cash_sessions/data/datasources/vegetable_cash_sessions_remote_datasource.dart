// lib/features/vegetable_cash_sessions/data/datasources/vegetable_cash_sessions_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../app/config/api_config.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/vegetable_cash_session_model.dart';

abstract class VegetableCashSessionsRemoteDataSource {
  Future<VegetableCashSessionModel> open({required double openingAmount, String? notes});
  Future<VegetableCashSessionModel> close({required double closingAmount, String? notes});
  Future<VegetableCashSessionSummaryModel> getCurrent();
  Future<List<VegetableCashSessionModel>> getHistory();
  Future<VegetableCashSessionModel> getById(String id);
}

class VegetableCashSessionsRemoteDataSourceImpl implements VegetableCashSessionsRemoteDataSource {
  final DioClient dioClient;

  VegetableCashSessionsRemoteDataSourceImpl(this.dioClient);

  @override
  Future<VegetableCashSessionModel> open({required double openingAmount, String? notes}) async {
    try {
      final response = await dioClient.post(
        '${ApiConfig.vegetableCashSessionsEndpoint}/open',
        data: {'openingAmount': openingAmount, if (notes != null && notes.isNotEmpty) 'notes': notes},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return VegetableCashSessionModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error al abrir la caja', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'abrir la caja');
    } catch (e) {
      throw ServerException('Error inesperado al abrir la caja: ${e.toString()}');
    }
  }

  @override
  Future<VegetableCashSessionModel> close({required double closingAmount, String? notes}) async {
    try {
      final response = await dioClient.post(
        '${ApiConfig.vegetableCashSessionsEndpoint}/close',
        data: {'closingAmount': closingAmount, if (notes != null && notes.isNotEmpty) 'notes': notes},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return VegetableCashSessionModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error al cerrar la caja', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'cerrar la caja');
    } catch (e) {
      throw ServerException('Error inesperado al cerrar la caja: ${e.toString()}');
    }
  }

  @override
  Future<VegetableCashSessionSummaryModel> getCurrent() async {
    try {
      final response = await dioClient.get('${ApiConfig.vegetableCashSessionsEndpoint}/current');

      if (response.statusCode == 200) {
        return VegetableCashSessionSummaryModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error al consultar la caja', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'consultar la caja');
    } catch (e) {
      throw ServerException('Error inesperado al consultar la caja: ${e.toString()}');
    }
  }

  @override
  Future<List<VegetableCashSessionModel>> getHistory() async {
    try {
      final response = await dioClient.get(ApiConfig.vegetableCashSessionsEndpoint);

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((json) => VegetableCashSessionModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ServerException('Error al obtener el historial de caja', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener el historial de caja');
    } catch (e) {
      throw ServerException('Error inesperado al obtener el historial de caja: ${e.toString()}');
    }
  }

  @override
  Future<VegetableCashSessionModel> getById(String id) async {
    try {
      final response = await dioClient.get('${ApiConfig.vegetableCashSessionsEndpoint}/$id');

      if (response.statusCode == 200) {
        return VegetableCashSessionModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Turno de caja con ID $id no encontrado');
      }
      throw ServerException('Error al obtener el turno de caja', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Turno de caja con ID $id no encontrado');
      }
      throw _handleDioException(e, 'obtener el turno de caja');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException('Error inesperado al obtener el turno de caja: ${e.toString()}');
    }
  }

  Exception _handleDioException(DioException e, String operation) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Tiempo de espera agotado al $operation');
      case DioExceptionType.connectionError:
        return NetworkException('Error de conexión al $operation');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] as String? ?? 'Error del servidor';
        switch (statusCode) {
          case 400:
            return ValidationException(message);
          case 401:
            return AuthException('No autorizado para $operation');
          case 403:
            return AuthException('No tiene permisos para $operation');
          case 404:
            return NotFoundException('Recurso no encontrado');
          case 409:
            return ConflictException(message);
          default:
            return ServerException('Error del servidor al $operation: $message', statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return NetworkException('Operación cancelada al $operation');
      default:
        return NetworkException('Error de red al $operation: ${e.message}');
    }
  }
}
