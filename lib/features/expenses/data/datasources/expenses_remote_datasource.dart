// lib/features/expenses/data/datasources/expenses_remote_datasource.dart

import 'package:dio/dio.dart';

import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/config/api_config.dart';
import '../models/expense_model.dart';

/// Expenses remote data source interface
abstract class ExpensesRemoteDataSource {
  /// Get all expenses
  Future<List<ExpenseModel>> getExpenses();

  /// Get expense by ID
  Future<ExpenseModel> getExpenseById(String id);

  /// Create a new expense
  Future<ExpenseModel> createExpense({
    required String description,
    required double amount,
  });

  /// Update an expense
  Future<ExpenseModel> updateExpense({
    required String id,
    String? description,
    double? amount,
  });

  /// Delete an expense
  Future<void> deleteExpense(String id);
}

/// Implementation of ExpensesRemoteDataSource using Dio HTTP client
class ExpensesRemoteDataSourceImpl implements ExpensesRemoteDataSource {
  final DioClient dioClient;

  ExpensesRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final response = await dioClient.get(ApiConfig.expensesEndpoint);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different response formats
        List<dynamic> expensesData;
        if (responseData is Map<String, dynamic>) {
          // If response has metadata
          if (responseData.containsKey('data')) {
            expensesData = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('expenses')) {
            expensesData = responseData['expenses'] as List<dynamic>;
          } else {
            // Assume the map itself contains expense data
            expensesData = [responseData];
          }
        } else if (responseData is List<dynamic>) {
          expensesData = responseData;
        } else {
          throw ParseException('Formato de respuesta inválido');
        }

        return expensesData
            .map((json) => ExpenseModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener gastos: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al obtener gastos');
    } catch (e) {
      throw ServerException('Error inesperado al obtener gastos: $e');
    }
  }

  @override
  Future<ExpenseModel> getExpenseById(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del gasto es requerido');
      }

      final response = await dioClient.get('${ApiConfig.expensesEndpoint}/$id');

      if (response.statusCode == 200) {
        return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Error al obtener gasto: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al obtener gasto');
    } catch (e) {
      throw ServerException('Error inesperado al obtener gasto: $e');
    }
  }

  @override
  Future<ExpenseModel> createExpense({
    required String description,
    required double amount,
  }) async {
    try {
      if (description.trim().isEmpty) {
        throw ValidationException('La descripción es requerida');
      }

      if (amount <= 0) {
        throw ValidationException('El monto debe ser mayor a 0');
      }

      final data = {
        'description': description,
        'amount': amount,
      };

      final response = await dioClient.post(
        ApiConfig.expensesEndpoint,
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Error al crear gasto: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al crear gasto');
    } catch (e) {
      throw ServerException('Error inesperado al crear gasto: $e');
    }
  }

  @override
  Future<ExpenseModel> updateExpense({
    required String id,
    String? description,
    double? amount,
  }) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del gasto es requerido');
      }

      if (description == null && amount == null) {
        throw ValidationException('Debe proporcionar al menos un campo para actualizar');
      }

      final data = <String, dynamic>{};
      if (description != null) data['description'] = description;
      if (amount != null) data['amount'] = amount;

      final response = await dioClient.patch(
        '${ApiConfig.expensesEndpoint}/$id',
        data: data,
      );

      if (response.statusCode == 200) {
        return ExpenseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Error al actualizar gasto: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al actualizar gasto');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar gasto: $e');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ValidationException('El ID del gasto es requerido');
      }

      final response = await dioClient.delete('${ApiConfig.expensesEndpoint}/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          'Error al eliminar gasto: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al eliminar gasto');
    } catch (e) {
      throw ServerException('Error inesperado al eliminar gasto: $e');
    }
  }

  /// Map DioException to ServerException
  ServerException _mapDioExceptionToServerException(
    DioException exception,
    String defaultMessage,
  ) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerException(
          'Error de conexión: Tiempo de espera agotado',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode ?? 0;
        final message = exception.response?.data?['message'] ?? defaultMessage;
        return ServerException(message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return ServerException('Solicitud cancelada');
      case DioExceptionType.connectionError:
        return ServerException('Error de conexión: Verifique su internet');
      default:
        return ServerException(defaultMessage);
    }
  }
}
