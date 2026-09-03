import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/vegetable_category.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/entities/vegetable_order.dart';
import '../../domain/entities/vegetable_sale.dart';
import '../../domain/entities/vegetable_stock_movement.dart';
import '../../domain/entities/vegetable_purchase.dart';
import '../../domain/repositories/vegetables_repository.dart';
import '../datasources/vegetables_remote_datasource.dart';

class VegetablesRepositoryImpl implements VegetablesRepository {
  final VegetablesRemoteDataSource remoteDataSource;

  VegetablesRepositoryImpl({required this.remoteDataSource});

  Failure _mapException(Object e, String fallbackMessage) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ValidationException) return ValidationFailure(e.message, code: 'VALIDATION_ERROR');
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return ServerFailure.notFound(e.message);
    if (e is ConflictException) return ServerFailure.conflict(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return UnexpectedFailure(
      '$fallbackMessage: ${e.toString()}',
      exception: e is Exception ? e : Exception(e.toString()),
    );
  }

  @override
  Future<Either<Failure, List<VegetableCategory>>> getCategories({bool includeInactive = false}) async {
    try {
      final models = await remoteDataSource.getCategories(includeInactive: includeInactive);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener las categorías'));
    }
  }

  @override
  Future<Either<Failure, VegetableCategory>> createCategory(VegetableCategoryParams params) async {
    try {
      final model = await remoteDataSource.createCategory(params);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al crear la categoría'));
    }
  }

  @override
  Future<Either<Failure, VegetableCategory>> updateCategory(String id, VegetableCategoryParams params) async {
    try {
      final model = await remoteDataSource.updateCategory(id, params);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al actualizar la categoría'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async {
    try {
      await remoteDataSource.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al eliminar la categoría'));
    }
  }

  @override
  Future<Either<Failure, List<VegetableItem>>> getItems({bool includeInactive = false}) async {
    try {
      final models = await remoteDataSource.getItems(includeInactive: includeInactive);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener el catálogo de verduras'));
    }
  }

  @override
  Future<Either<Failure, VegetableItem>> createItem(VegetableItemParams params) async {
    try {
      final model = await remoteDataSource.createItem(params);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al crear el producto'));
    }
  }

  @override
  Future<Either<Failure, VegetableItem>> updateItem(String id, VegetableItemParams params) async {
    try {
      final model = await remoteDataSource.updateItem(id, params);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al actualizar el producto'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) async {
    try {
      await remoteDataSource.deleteItem(id);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al eliminar el producto'));
    }
  }

  @override
  Future<Either<Failure, VegetableSale>> createSale(List<CreateVegetableSaleItemParams> items, String paymentMethodId) async {
    try {
      final model = await remoteDataSource.createSale(items, paymentMethodId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al registrar la venta'));
    }
  }

  @override
  Future<Either<Failure, List<VegetableSale>>> getSales() async {
    try {
      final models = await remoteDataSource.getSales();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener las ventas'));
    }
  }

  @override
  Future<Either<Failure, VegetableSale>> getSaleById(String id) async {
    try {
      final model = await remoteDataSource.getSaleById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener la venta'));
    }
  }

  @override
  Future<Either<Failure, VegetableOrder>> createOrder(List<CreateVegetableOrderItemParams> items) async {
    try {
      final model = await remoteDataSource.createOrder(items);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al registrar el pedido'));
    }
  }

  @override
  Future<Either<Failure, List<VegetableOrder>>> getOrders() async {
    try {
      final models = await remoteDataSource.getOrders();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener los pedidos'));
    }
  }

  @override
  Future<Either<Failure, VegetableOrder>> getOrderById(String id) async {
    try {
      final model = await remoteDataSource.getOrderById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener el pedido'));
    }
  }

  @override
  Future<Either<Failure, VegetableItem>> registerStockMovement(String itemId, RegisterStockMovementParams params) async {
    try {
      final model = await remoteDataSource.registerStockMovement(itemId, params);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al registrar el movimiento de stock'));
    }
  }

  @override
  Future<Either<Failure, List<VegetableStockMovement>>> getStockMovements(String itemId) async {
    try {
      final models = await remoteDataSource.getStockMovements(itemId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener el historial de inventario'));
    }
  }

  @override
  Future<Either<Failure, VegetablePurchase>> createPurchase(List<CreateVegetablePurchaseItemParams> items) async {
    try {
      final model = await remoteDataSource.createPurchase(items);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al registrar la compra'));
    }
  }

  @override
  Future<Either<Failure, List<VegetablePurchase>>> getPurchases() async {
    try {
      final models = await remoteDataSource.getPurchases();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener las compras'));
    }
  }

  @override
  Future<Either<Failure, VegetablePurchase>> getPurchaseById(String id) async {
    try {
      final model = await remoteDataSource.getPurchaseById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener la compra'));
    }
  }
}
