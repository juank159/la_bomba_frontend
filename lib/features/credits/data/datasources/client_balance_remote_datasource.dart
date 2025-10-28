// lib/features/credits/data/datasources/client_balance_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../app/config/api_config.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../models/client_balance_model.dart';
import '../models/client_balance_transaction_model.dart';
import '../models/refund_history_model.dart';

/// DataSource remoto para operaciones de saldo de clientes
abstract class ClientBalanceRemoteDataSource {
  Future<List<ClientBalanceModel>> getAllClientBalances();
  Future<ClientBalanceModel?> getClientBalance(String clientId);
  Future<List<ClientBalanceTransactionModel>> getClientTransactions(
    String clientId,
  );
  Future<List<RefundHistoryModel>> getAllRefunds();
  Future<ClientBalanceModel> useBalance({
    required String clientId,
    required double amount,
    required String description,
    String? relatedCreditId,
    String? relatedOrderId,
  });
  Future<ClientBalanceModel> refundBalance({
    required String clientId,
    required double amount,
    required String description,
    String? paymentMethodId,
  });
  Future<ClientBalanceModel> adjustBalance({
    required String clientId,
    required double amount,
    required String description,
  });
}

class ClientBalanceRemoteDataSourceImpl
    implements ClientBalanceRemoteDataSource {
  final DioClient dioClient;

  ClientBalanceRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<ClientBalanceModel>> getAllClientBalances() async {
    try {
      final response = await dioClient.get('/client-balance');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList
            .map((json) => ClientBalanceModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener saldos: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(e, 'Error al obtener saldos');
    } catch (e) {
      throw ServerException('Error inesperado al obtener saldos: $e');
    }
  }

  @override
  Future<ClientBalanceModel?> getClientBalance(String clientId) async {
    try {
      final response = await dioClient.get('/client-balance/client/$clientId');

      if (response.statusCode == 200) {
        final jsonData = response.data;

        // Si el backend devuelve un objeto con balance: 0 y sin id, retornar null
        if (jsonData['id'] == null) {
          return null;
        }

        return ClientBalanceModel.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ServerException(
          'Error al obtener saldo del cliente: ${response.statusCode}',
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
        'Error al obtener saldo del cliente',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener saldo del cliente: $e');
    }
  }

  @override
  Future<List<ClientBalanceTransactionModel>> getClientTransactions(
    String clientId,
  ) async {
    try {
      final response = await dioClient.get(
        '/client-balance/client/$clientId/transactions',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList
            .map((json) => ClientBalanceTransactionModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener transacciones: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(
        e,
        'Error al obtener transacciones',
      );
    } catch (e) {
      throw ServerException('Error inesperado al obtener transacciones: $e');
    }
  }

  @override
  Future<List<RefundHistoryModel>> getAllRefunds() async {
    try {
      final response = await dioClient.get('/client-balance/refunds/all');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList
            .map((json) => RefundHistoryModel.fromJson(json))
            .toList();
      } else {
        throw ServerException(
          'Error al obtener historial de devoluciones: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioExceptionToServerException(
        e,
        'Error al obtener historial de devoluciones',
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener historial de devoluciones: $e',
      );
    }
  }

  @override
  Future<ClientBalanceModel> useBalance({
    required String clientId,
    required double amount,
    required String description,
    String? relatedCreditId,
    String? relatedOrderId,
  }) async {
    try {
      final body = {
        'clientId': clientId,
        'amount': amount,
        'description': description,
        if (relatedCreditId != null) 'relatedCreditId': relatedCreditId,
        if (relatedOrderId != null) 'relatedOrderId': relatedOrderId,
      };

      final response = await dioClient.post(
        '/client-balance/use',
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClientBalanceModel.fromJson(response.data);
      } else if (response.statusCode == 400) {
        final message = response.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Cliente no encontrado');
      } else {
        throw ServerException(
          'Error al usar saldo: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      }
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Cliente no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al usar saldo');
    } catch (e) {
      throw ServerException('Error inesperado al usar saldo: $e');
    }
  }

  @override
  Future<ClientBalanceModel> refundBalance({
    required String clientId,
    required double amount,
    required String description,
    String? paymentMethodId,
  }) async {
    try {
      final body = {
        'clientId': clientId,
        'amount': amount,
        'description': description,
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
      };

      final response = await dioClient.post(
        '/client-balance/refund',
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClientBalanceModel.fromJson(response.data);
      } else if (response.statusCode == 400) {
        final message = response.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Cliente no encontrado');
      } else {
        throw ServerException(
          'Error al devolver saldo: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      }
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Cliente no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al devolver saldo');
    } catch (e) {
      throw ServerException('Error inesperado al devolver saldo: $e');
    }
  }

  @override
  Future<ClientBalanceModel> adjustBalance({
    required String clientId,
    required double amount,
    required String description,
  }) async {
    try {
      final body = {
        'clientId': clientId,
        'amount': amount,
        'description': description,
      };

      final response = await dioClient.post(
        '/client-balance/adjust',
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ClientBalanceModel.fromJson(response.data);
      } else if (response.statusCode == 400) {
        final message = response.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Cliente no encontrado');
      } else {
        throw ServerException(
          'Error al ajustar saldo: ${response.statusCode}',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data?['message'] as String? ??
            'Error de validación';
        throw ValidationException(message);
      }
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Cliente no encontrado');
      }
      throw _mapDioExceptionToServerException(e, 'Error al ajustar saldo');
    } catch (e) {
      throw ServerException('Error inesperado al ajustar saldo: $e');
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
