import 'package:dio/dio.dart';

import '../../../../app/config/api_config.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/invoice_model.dart';
import '../../domain/repositories/invoices_repository.dart';

/// Abstract class defining the contract for Invoices remote data source
abstract class InvoicesRemoteDataSource {
  /// Get all invoices, most recent first
  Future<List<InvoiceModel>> getAllInvoices();

  /// Get a specific invoice by ID
  Future<InvoiceModel> getInvoiceById(String id);

  /// Create a new invoice
  Future<InvoiceModel> createInvoice(CreateInvoiceParams params);

  /// Cancel an existing invoice
  Future<InvoiceModel> cancelInvoice(String id);
}

/// Implementation of InvoicesRemoteDataSource using Dio HTTP client
class InvoicesRemoteDataSourceImpl implements InvoicesRemoteDataSource {
  final DioClient dioClient;

  InvoicesRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<InvoiceModel>> getAllInvoices() async {
    try {
      final response = await dioClient.get(ApiConfig.invoicesEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => InvoiceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Error del servidor al obtener facturas',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener facturas');
    } catch (e) {
      throw ServerException('Error inesperado al obtener facturas: ${e.toString()}');
    }
  }

  @override
  Future<InvoiceModel> getInvoiceById(String id) async {
    try {
      final response = await dioClient.get('${ApiConfig.invoicesEndpoint}/$id');

      if (response.statusCode == 200) {
        return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Factura con ID $id no encontrada');
      } else {
        throw ServerException(
          'Error del servidor al obtener la factura',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Factura con ID $id no encontrada');
      }
      throw _handleDioException(e, 'obtener la factura');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException('Error inesperado al obtener la factura: ${e.toString()}');
    }
  }

  @override
  Future<InvoiceModel> createInvoice(CreateInvoiceParams params) async {
    try {
      final data = {
        if (params.clientId != null && params.clientId!.trim().isNotEmpty)
          'clientId': params.clientId,
        'paymentMethodId': params.paymentMethodId,
        'items': params.items
            .map((item) => {
                  'productId': item.productId,
                  'quantity': item.quantity,
                  if (item.unitPrice != null) 'unitPrice': item.unitPrice,
                })
            .toList(),
      };

      final response = await dioClient.post(
        ApiConfig.invoicesEndpoint,
        data: data,
      );

      if (response.statusCode == 201) {
        return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Error del servidor al crear la factura',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'crear la factura');
    } catch (e) {
      throw ServerException('Error inesperado al crear la factura: ${e.toString()}');
    }
  }

  @override
  Future<InvoiceModel> cancelInvoice(String id) async {
    try {
      final response = await dioClient.patch('${ApiConfig.invoicesEndpoint}/$id/cancel');

      if (response.statusCode == 200) {
        return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Factura con ID $id no encontrada');
      } else {
        throw ServerException(
          'Error del servidor al anular la factura',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Factura con ID $id no encontrada');
      }
      throw _handleDioException(e, 'anular la factura');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException('Error inesperado al anular la factura: ${e.toString()}');
    }
  }

  /// Helper method to handle DioException and convert to appropriate custom exceptions
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
        final message = e.response?.data?['message'] as String? ??
            e.response?.data?['error'] as String? ??
            'Error del servidor';

        switch (statusCode) {
          case 400:
            return ValidationException('Datos inválidos: $message');
          case 401:
            return AuthException('No autorizado para $operation');
          case 403:
            return AuthException('No tiene permisos para $operation');
          case 404:
            return NotFoundException('Recurso no encontrado');
          case 422:
            return ValidationException('Error de validación: $message');
          case 500:
            return ServerException('Error interno del servidor al $operation');
          default:
            return ServerException(
              'Error del servidor al $operation: $message',
              statusCode: statusCode,
            );
        }

      case DioExceptionType.cancel:
        return NetworkException('Operación cancelada al $operation');

      case DioExceptionType.badCertificate:
        return NetworkException('Error de certificado al $operation');

      case DioExceptionType.unknown:
      default:
        return NetworkException('Error de red desconocido al $operation: ${e.message}');
    }
  }
}
