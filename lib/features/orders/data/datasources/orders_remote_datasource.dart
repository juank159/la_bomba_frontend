import 'package:dio/dio.dart';

import '../../../../app/config/api_config.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/repositories/orders_repository.dart';

/// Abstract class defining the contract for Orders remote data source
abstract class OrdersRemoteDataSource {
  /// Get all orders with pagination and optional filters
  Future<List<OrderModel>> getAllOrders({
    int page = 0,
    int limit = 20,
    String? search,
    String? status,
  });

  /// Get a specific order by ID
  Future<OrderModel> getOrderById(String id);

  /// Create a new order
  Future<OrderModel> createOrder(CreateOrderParams params);

  /// Update an existing order
  Future<OrderModel> updateOrder(UpdateOrderParams params);

  /// Delete an order
  Future<bool> deleteOrder(String id);

  /// Update requested quantities for order items (admin only)
  Future<bool> updateRequestedQuantities(UpdateQuantitiesParams params);

  /// Search orders by description or provider
  Future<List<OrderModel>> searchOrders(
    String query, {
    int page = 0,
    int limit = 20,
    String? status,
  });

  /// Get total count of orders
  Future<int> getOrdersCount({
    String? search,
    String? status,
  });

  /// Get orders by status
  Future<List<OrderModel>> getOrdersByStatus(
    String status, {
    int page = 0,
    int limit = 20,
  });

  /// Add product to existing order
  Future<OrderModel> addProductToOrder(
    String orderId,
    String? productId,
    int existingQuantity,
    int? requestedQuantity,
    String measurementUnit, {
    String? temporaryProductId,
    String? supplierId,
  });

  /// Remove product from existing order
  Future<OrderModel> removeProductFromOrder(String orderId, String itemId);

  /// Update quantities for specific order item
  Future<OrderModel> updateOrderItemQuantity(
    String orderId,
    String itemId,
    int? existingQuantity,
    int? requestedQuantity,
    MeasurementUnit? measurementUnit, {
    String? supplierId,
  });

  /// Get order items grouped by supplier
  Future<Map<String, List<OrderItem>>> getOrderGroupedBySupplier(String orderId);

  /// Assign supplier to order item
  Future<OrderModel> assignSupplierToItem(
    String orderId,
    String itemId,
    String supplierId,
  );
}

/// Implementation of OrdersRemoteDataSource using Dio HTTP client
class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final DioClient dioClient;

  OrdersRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<OrderModel>> getAllOrders({
    int page = 0,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status.trim();
      }

      final response = await dioClient.get(
        ApiConfig.ordersEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerException(
          'Error del servidor al obtener pedidos',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener pedidos');
    } catch (e) {
      throw ServerException('Error inesperado al obtener pedidos: ${e.toString()}');
    }
  }

  @override
  Future<OrderModel> getOrderById(String id) async {
    try {
      final response = await dioClient.get('${ApiConfig.ordersEndpoint}/$id');

      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Pedido con ID $id no encontrado');
      } else {
        throw ServerException(
          'Error del servidor al obtener el pedido',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Pedido con ID $id no encontrado');
      }
      throw _handleDioException(e, 'obtener el pedido');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException('Error inesperado al obtener el pedido: ${e.toString()}');
    }
  }

  @override
  Future<OrderModel> createOrder(CreateOrderParams params) async {
    try {
      final orderModel = OrderModel.forCreation(
        description: params.description,
        provider: params.provider,
        items: params.items.map((item) {
          return OrderItemModel.forCreation(
            productId: item.productId,
            temporaryProductId: item.temporaryProductId,
            supplierId: item.supplierId,
            existingQuantity: item.existingQuantity,
            requestedQuantity: item.requestedQuantity,
            measurementUnit: MeasurementUnit.fromString(item.measurementUnit),
          ).toEntity();
        }).toList(),
        createdById: '', // Will be set by backend based on auth token
      );

      final response = await dioClient.post(
        ApiConfig.ordersEndpoint,
        data: orderModel.toCreateJson(),
      );

      if (response.statusCode == 201) {
        return OrderModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Error del servidor al crear el pedido',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'crear el pedido');
    } catch (e) {
      throw ServerException('Error inesperado al crear el pedido: ${e.toString()}');
    }
  }

  @override
  Future<OrderModel> updateOrder(UpdateOrderParams params) async {
    try {
      final updateData = <String, dynamic>{};

      if (params.description != null) {
        updateData['description'] = params.description;
      }

      if (params.provider != null) {
        updateData['provider'] = params.provider;
      }

      if (params.status != null) {
        updateData['status'] = params.status;
      }

      print('🟢 [DataSource] updateOrder API call');
      print('🟢 [DataSource] URL: ${ApiConfig.ordersEndpoint}/${params.id}');
      print('🟢 [DataSource] Data being sent: $updateData');

      final response = await dioClient.patch(
        '${ApiConfig.ordersEndpoint}/${params.id}',
        data: updateData,
      );

      print('🟢 [DataSource] Response status: ${response.statusCode}');
      print('🟢 [DataSource] Response data keys: ${(response.data as Map<String, dynamic>).keys}');
      print('🟢 [DataSource] Response provider: ${(response.data as Map<String, dynamic>)['provider']}');

      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Pedido con ID ${params.id} no encontrado');
      } else {
        throw ServerException(
          'Error del servidor al actualizar el pedido',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Pedido con ID ${params.id} no encontrado');
      }
      throw _handleDioException(e, 'actualizar el pedido');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException('Error inesperado al actualizar el pedido: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteOrder(String id) async {
    try {
      final response = await dioClient.delete('${ApiConfig.ordersEndpoint}/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 404) {
        throw NotFoundException('Pedido con ID $id no encontrado');
      } else {
        throw ServerException(
          'Error del servidor al eliminar el pedido',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException('Pedido con ID $id no encontrado');
      }
      throw _handleDioException(e, 'eliminar el pedido');
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException('Error inesperado al eliminar el pedido: ${e.toString()}');
    }
  }

  @override
  Future<bool> updateRequestedQuantities(UpdateQuantitiesParams params) async {
    try {
      final updateData = {
        'items': params.items.map((item) => {
          'id': item.id,
          'requestedQuantity': item.requestedQuantity,
        }).toList(),
      };

      final response = await dioClient.patch(
        '${ApiConfig.ordersEndpoint}/items/quantities',
        data: updateData,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          'Error del servidor al actualizar las cantidades',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'actualizar las cantidades');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar las cantidades: ${e.toString()}');
    }
  }

  @override
  Future<List<OrderModel>> searchOrders(
    String query, {
    int page = 0,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'search': query.trim(),
        'page': page,
        'limit': limit,
      };

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status.trim();
      }

      final response = await dioClient.get(
        ApiConfig.ordersEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerException(
          'Error del servidor al buscar pedidos',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'buscar pedidos');
    } catch (e) {
      throw ServerException('Error inesperado al buscar pedidos: ${e.toString()}');
    }
  }

  @override
  Future<int> getOrdersCount({
    String? search,
    String? status,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'count': true,
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      if (status != null && status.trim().isNotEmpty) {
        queryParameters['status'] = status.trim();
      }

      final response = await dioClient.get(
        ApiConfig.ordersEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        // Assuming backend returns count in response data
        if (response.data is Map<String, dynamic> && response.data['count'] != null) {
          return response.data['count'] as int;
        } else if (response.data is int) {
          return response.data as int;
        } else {
          return 0;
        }
      } else {
        throw ServerException(
          'Error del servidor al obtener el conteo de pedidos',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener el conteo de pedidos');
    } catch (e) {
      throw ServerException('Error inesperado al obtener el conteo de pedidos: ${e.toString()}');
    }
  }

  @override
  Future<List<OrderModel>> getOrdersByStatus(
    String status, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'status': status,
        'page': page,
        'limit': limit,
      };

      final response = await dioClient.get(
        ApiConfig.ordersEndpoint,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerException(
          'Error del servidor al obtener pedidos por estado',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener pedidos por estado');
    } catch (e) {
      throw ServerException('Error inesperado al obtener pedidos por estado: ${e.toString()}');
    }
  }

  @override
  Future<OrderModel> addProductToOrder(
    String orderId,
    String? productId,
    int existingQuantity,
    int? requestedQuantity,
    String measurementUnit, {
    String? temporaryProductId,
    String? supplierId,
  }) async {
    try {
      final data = <String, dynamic>{
        'existingQuantity': existingQuantity,
        'requestedQuantity': requestedQuantity,
        'measurementUnit': measurementUnit,
      };

      if (productId != null) {
        data['productId'] = productId;
      }

      if (temporaryProductId != null) {
        data['temporaryProductId'] = temporaryProductId;
      }

      if (supplierId != null) {
        data['supplierId'] = supplierId;
      }

      final response = await dioClient.post(
        '${ApiConfig.ordersEndpoint}/$orderId/items',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OrderModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Error del servidor al agregar producto al pedido',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'agregar producto al pedido');
    } catch (e) {
      throw ServerException('Error inesperado al agregar producto al pedido: ${e.toString()}');
    }
  }

  @override
  Future<OrderModel> removeProductFromOrder(String orderId, String itemId) async {
    try {
      final response = await dioClient.delete(
        '${ApiConfig.ordersEndpoint}/$orderId/items/$itemId',
      );

      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Error del servidor al quitar producto del pedido',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'quitar producto del pedido');
    } catch (e) {
      throw ServerException('Error inesperado al quitar producto del pedido: ${e.toString()}');
    }
  }

  @override
  Future<OrderModel> updateOrderItemQuantity(
    String orderId,
    String itemId,
    int? existingQuantity,
    int? requestedQuantity,
    MeasurementUnit? measurementUnit, {
    String? supplierId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (existingQuantity != null) {
        data['existingQuantity'] = existingQuantity;
      }
      if (requestedQuantity != null) {
        data['requestedQuantity'] = requestedQuantity;
      }
      if (measurementUnit != null) {
        data['measurementUnit'] = measurementUnit.value;
      }
      if (supplierId != null) {
        data['supplierId'] = supplierId;
      }

      print('🟡 [DataSource] updateOrderItemQuantity');
      print('🟡 [DataSource] URL: ${ApiConfig.ordersEndpoint}/$orderId/items/$itemId');
      print('🟡 [DataSource] Data being sent: $data');

      final response = await dioClient.patch(
        '${ApiConfig.ordersEndpoint}/$orderId/items/$itemId',
        data: data,
      );

      print('🟡 [DataSource] Response status: ${response.statusCode}');
      print('🟡 [DataSource] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final orderModel = OrderModel.fromJson(response.data as Map<String, dynamic>);
        print('🟡 [DataSource] Updated order item measurementUnit: ${orderModel.items.firstWhere((item) => item.id == itemId).measurementUnit}');
        return orderModel;
      } else {
        throw ServerException(
          'Error del servidor al actualizar cantidades del producto',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'actualizar cantidades del producto');
    } catch (e) {
      throw ServerException('Error inesperado al actualizar cantidades del producto: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, List<OrderItem>>> getOrderGroupedBySupplier(String orderId) async {
    try {
      final response = await dioClient.get(
        '${ApiConfig.ordersEndpoint}/$orderId/by-supplier',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final Map<String, List<OrderItem>> groupedItems = {};

        data.forEach((key, value) {
          final items = (value as List)
              .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>).toEntity())
              .toList();
          groupedItems[key] = items;
        });

        return groupedItems;
      } else {
        throw ServerException(
          'Error del servidor al obtener pedido agrupado por proveedor',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'obtener pedido agrupado por proveedor');
    } catch (e) {
      throw ServerException('Error inesperado al obtener pedido agrupado por proveedor: ${e.toString()}');
    }
  }

  @override
  Future<OrderModel> assignSupplierToItem(
    String orderId,
    String itemId,
    String supplierId,
  ) async {
    try {
      final response = await dioClient.patch(
        '${ApiConfig.ordersEndpoint}/$orderId/items/$itemId/supplier',
        data: {'supplierId': supplierId},
      );

      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Error del servidor al asignar proveedor al item',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'asignar proveedor al item');
    } catch (e) {
      throw ServerException('Error inesperado al asignar proveedor al item: ${e.toString()}');
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