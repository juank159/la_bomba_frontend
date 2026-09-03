// lib/features/corresponsal/data/datasources/corresponsal_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../app/config/api_config.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/corresponsal_entry_model.dart';

abstract class CorresponsalRemoteDataSource {
  Future<List<CorresponsalEntryModel>> getEntries();
  Future<CorresponsalEntryModel> createEntry({required double amount, String? note});
  Future<void> deleteEntry(String id);
}

class CorresponsalRemoteDataSourceImpl implements CorresponsalRemoteDataSource {
  final DioClient dioClient;

  CorresponsalRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<CorresponsalEntryModel>> getEntries() async {
    try {
      final response = await dioClient.get(ApiConfig.corresponsalEndpoint);

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((json) => CorresponsalEntryModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ServerException('Error al obtener los registros de corresponsal', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener los registros de corresponsal');
    } catch (e) {
      throw ServerException('Error inesperado al obtener los registros de corresponsal: ${e.toString()}');
    }
  }

  @override
  Future<CorresponsalEntryModel> createEntry({required double amount, String? note}) async {
    try {
      final response = await dioClient.post(
        ApiConfig.corresponsalEndpoint,
        data: {'amount': amount, if (note != null && note.isNotEmpty) 'note': note},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return CorresponsalEntryModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error al registrar el ingreso', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'registrar el ingreso');
    } catch (e) {
      throw ServerException('Error inesperado al registrar el ingreso: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    try {
      final response = await dioClient.delete('${ApiConfig.corresponsalEndpoint}/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Error al eliminar el registro', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'eliminar el registro');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar el registro: ${e.toString()}');
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
