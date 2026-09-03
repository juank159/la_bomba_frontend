// lib/features/vegetable_expenses/data/datasources/vegetable_expenses_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../app/config/api_config.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/vegetable_expense.dart';
import '../models/vegetable_expense_model.dart';

abstract class VegetableExpensesRemoteDataSource {
  Future<List<VegetableExpenseModel>> getExpenses();
  Future<VegetableExpenseModel> getExpenseById(String id);
  Future<VegetableExpenseModel> createExpense({
    required String description,
    required double amount,
    required ExpenseFundingSource fundingSource,
  });
  Future<VegetableExpenseModel> updateExpense({required String id, String? description, double? amount});
  Future<void> deleteExpense(String id);
}

class VegetableExpensesRemoteDataSourceImpl implements VegetableExpensesRemoteDataSource {
  final DioClient dioClient;

  VegetableExpensesRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<VegetableExpenseModel>> getExpenses() async {
    try {
      final response = await dioClient.get(ApiConfig.vegetableExpensesEndpoint);

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((json) => VegetableExpenseModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw ServerException('Error al obtener los gastos', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener los gastos');
    } catch (e) {
      throw ServerException('Error inesperado al obtener los gastos: ${e.toString()}');
    }
  }

  @override
  Future<VegetableExpenseModel> getExpenseById(String id) async {
    try {
      final response = await dioClient.get('${ApiConfig.vegetableExpensesEndpoint}/$id');

      if (response.statusCode == 200) {
        return VegetableExpenseModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Gasto con ID $id no encontrado');
      }
      throw ServerException('Error al obtener el gasto', statusCode: response.statusCode);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Gasto con ID $id no encontrado');
      }
      throw _handleDioException(e, 'obtener el gasto');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException('Error inesperado al obtener el gasto: ${e.toString()}');
    }
  }

  @override
  Future<VegetableExpenseModel> createExpense({
    required String description,
    required double amount,
    required ExpenseFundingSource fundingSource,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConfig.vegetableExpensesEndpoint,
        data: {'description': description, 'amount': amount, 'fundingSource': fundingSource.value},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return VegetableExpenseModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error al crear el gasto', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'crear el gasto');
    } catch (e) {
      throw ServerException('Error inesperado al crear el gasto: ${e.toString()}');
    }
  }

  @override
  Future<VegetableExpenseModel> updateExpense({required String id, String? description, double? amount}) async {
    try {
      final data = <String, dynamic>{
        if (description != null) 'description': description,
        if (amount != null) 'amount': amount,
      };

      final response = await dioClient.patch('${ApiConfig.vegetableExpensesEndpoint}/$id', data: data);

      if (response.statusCode == 200) {
        return VegetableExpenseModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw ServerException('Error al actualizar el gasto', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioException(e, 'actualizar el gasto');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar el gasto: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final response = await dioClient.delete('${ApiConfig.vegetableExpensesEndpoint}/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Error al eliminar el gasto', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'eliminar el gasto');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar el gasto: ${e.toString()}');
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
            return ValidationException('Datos inválidos: $message');
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
