import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/entities/vegetable_sale.dart';
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
  Future<Either<Failure, VegetableSale>> createSale(List<CreateVegetableSaleItemParams> items) async {
    try {
      final model = await remoteDataSource.createSale(items);
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
}
