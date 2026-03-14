import 'package:dio/dio.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/config/api_config.dart';
import '../models/income_model.dart';

abstract class IncomesRemoteDataSource {
  Future<List<IncomeModel>> getIncomes();
  Future<IncomeModel> getIncomeById(String id);
  Future<IncomeModel> createIncome({required String description, required double amount});
  Future<IncomeModel> updateIncome({required String id, String? description, double? amount});
  Future<void> deleteIncome(String id);
}

class IncomesRemoteDataSourceImpl implements IncomesRemoteDataSource {
  final DioClient dioClient;
  IncomesRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<IncomeModel>> getIncomes() async {
    try {
      final response = await dioClient.get(ApiConfig.incomesEndpoint);
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> incomesData;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            incomesData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('incomes')) {
            incomesData = responseData['incomes'] as List<dynamic>;
          } else {
            incomesData = [responseData];
          }
        } else if (responseData is List<dynamic>) {
          incomesData = responseData;
        } else {
          throw ParseException('Formato de respuesta invalido');
        }
        return incomesData.map((json) => IncomeModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerException('Error al obtener ingresos: ${response.statusCode}', statusCode: response.statusCode ?? 0);
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e, 'Error al obtener ingresos');
    } catch (e) {
      throw ServerException('Error inesperado al obtener ingresos: $e');
    }
  }

  @override
  Future<IncomeModel> getIncomeById(String id) async {
    try {
      if (id.trim().isEmpty) throw ValidationException('El ID del ingreso es requerido');
      final response = await dioClient.get('${ApiConfig.incomesEndpoint}/$id');
      if (response.statusCode == 200) {
        return IncomeModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Error al obtener ingreso: ${response.statusCode}', statusCode: response.statusCode ?? 0);
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e, 'Error al obtener ingreso');
    } catch (e) {
      throw ServerException('Error inesperado al obtener ingreso: $e');
    }
  }

  @override
  Future<IncomeModel> createIncome({required String description, required double amount}) async {
    try {
      if (description.trim().isEmpty) throw ValidationException('La descripcion es requerida');
      if (amount <= 0) throw ValidationException('El monto debe ser mayor a 0');
      final response = await dioClient.post(ApiConfig.incomesEndpoint, data: {'description': description, 'amount': amount});
      if (response.statusCode == 201 || response.statusCode == 200) {
        return IncomeModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Error al crear ingreso: ${response.statusCode}', statusCode: response.statusCode ?? 0);
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e, 'Error al crear ingreso');
    } catch (e) {
      throw ServerException('Error inesperado al crear ingreso: $e');
    }
  }

  @override
  Future<IncomeModel> updateIncome({required String id, String? description, double? amount}) async {
    try {
      if (id.trim().isEmpty) throw ValidationException('El ID del ingreso es requerido');
      if (description == null && amount == null) throw ValidationException('Debe proporcionar al menos un campo para actualizar');
      final data = <String, dynamic>{};
      if (description != null) data['description'] = description;
      if (amount != null) data['amount'] = amount;
      final response = await dioClient.patch('${ApiConfig.incomesEndpoint}/$id', data: data);
      if (response.statusCode == 200) {
        return IncomeModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Error al actualizar ingreso: ${response.statusCode}', statusCode: response.statusCode ?? 0);
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e, 'Error al actualizar ingreso');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar ingreso: $e');
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      if (id.trim().isEmpty) throw ValidationException('El ID del ingreso es requerido');
      final response = await dioClient.delete('${ApiConfig.incomesEndpoint}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Error al eliminar ingreso: ${response.statusCode}', statusCode: response.statusCode ?? 0);
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e, 'Error al eliminar ingreso');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar ingreso: $e');
    }
  }

  ServerException _mapDioException(DioException exception, String defaultMessage) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerException('Error de conexion: Tiempo de espera agotado', statusCode: 408);
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode ?? 0;
        final message = exception.response?.data?['message'] ?? defaultMessage;
        return ServerException(message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return ServerException('Solicitud cancelada');
      case DioExceptionType.connectionError:
        return ServerException('Error de conexion: Verifique su internet');
      default:
        return ServerException(defaultMessage);
    }
  }
}
