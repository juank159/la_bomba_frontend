//lib/features/orders/data/repositories/orders_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/order.dart' as order_entity;
import '../../domain/entities/order_item.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';

/// Implementation of OrdersRepository that uses remote data source
class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;

  OrdersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<order_entity.Order>>> getAllOrders({
    int page = 0,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      final orderModels = await remoteDataSource.getAllOrders(
        page: page,
        limit: limit,
        search: search,
        status: status,
      );

      final orders = orderModels.map((model) => model.toEntity()).toList();
      return Right(orders);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener pedidos: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> getOrderById(String id) async {
    try {
      final orderModel = await remoteDataSource.getOrderById(id);
      return Right(orderModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener el pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> createOrder(
    CreateOrderParams params,
  ) async {
    try {
      final orderModel = await remoteDataSource.createOrder(params);
      return Right(orderModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al crear el pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> updateOrder(
    UpdateOrderParams params,
  ) async {
    try {
      final orderModel = await remoteDataSource.updateOrder(params);
      return Right(orderModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al actualizar el pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> deleteOrder(String id) async {
    try {
      final result = await remoteDataSource.deleteOrder(id);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al eliminar el pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> updateRequestedQuantities(
    UpdateQuantitiesParams params,
  ) async {
    try {
      final result = await remoteDataSource.updateRequestedQuantities(params);
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al actualizar las cantidades: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<order_entity.Order>>> searchOrders(
    String query, {
    int page = 0,
    int limit = 20,
    String? status,
  }) async {
    try {
      final orderModels = await remoteDataSource.searchOrders(
        query,
        page: page,
        limit: limit,
        status: status,
      );

      final orders = orderModels.map((model) => model.toEntity()).toList();
      return Right(orders);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al buscar pedidos: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getOrdersCount({
    String? search,
    String? status,
  }) async {
    try {
      final count = await remoteDataSource.getOrdersCount(
        search: search,
        status: status,
      );
      return Right(count);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener el conteo de pedidos: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<order_entity.Order>>> getOrdersByStatus(
    String status, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final orderModels = await remoteDataSource.getOrdersByStatus(
        status,
        page: page,
        limit: limit,
      );

      final orders = orderModels.map((model) => model.toEntity()).toList();
      return Right(orders);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener pedidos por estado: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> addProductToOrder(
    String orderId,
    String? productId,
    int existingQuantity,
    int? requestedQuantity,
    String measurementUnit, {
    String? temporaryProductId,
    String? supplierId,
  }) async {
    try {
      final orderModel = await remoteDataSource.addProductToOrder(
        orderId,
        productId,
        existingQuantity,
        requestedQuantity,
        measurementUnit,
        temporaryProductId: temporaryProductId,
        supplierId: supplierId,
      );

      return Right(orderModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al agregar producto al pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> removeProductFromOrder(
    String orderId,
    String itemId,
  ) async {
    try {
      final orderModel = await remoteDataSource.removeProductFromOrder(
        orderId,
        itemId,
      );

      return Right(orderModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al quitar producto del pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> updateOrderItemQuantity(
    String orderId,
    String itemId,
    int? existingQuantity,
    int? requestedQuantity,
  ) async {
    try {
      final orderModel = await remoteDataSource.updateOrderItemQuantity(
        orderId,
        itemId,
        existingQuantity,
        requestedQuantity,
      );

      return Right(orderModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al actualizar cantidades del producto: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, List<OrderItem>>>>
  getOrderGroupedBySupplier(String orderId) async {
    try {
      final groupedItems = await remoteDataSource.getOrderGroupedBySupplier(
        orderId,
      );
      return Right(groupedItems);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener pedido agrupado por proveedor: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> assignSupplierToItem(
    String orderId,
    String itemId,
    String supplierId,
  ) async {
    try {
      final orderModel = await remoteDataSource.assignSupplierToItem(
        orderId,
        itemId,
        supplierId,
      );

      return Right(orderModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al asignar proveedor al item: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
