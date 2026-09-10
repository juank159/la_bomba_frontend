import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_purchase.dart';
import '../repositories/vegetables_repository.dart';

class GetVegetablePurchasesUseCase {
  final VegetablesRepository repository;

  GetVegetablePurchasesUseCase(this.repository);

  Future<Either<Failure, List<VegetablePurchase>>> call() async {
    try {
      return await repository.getPurchases();
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener las compras: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}

class GetVegetablePurchaseByIdUseCase {
  final VegetablesRepository repository;

  GetVegetablePurchaseByIdUseCase(this.repository);

  Future<Either<Failure, VegetablePurchase>> call(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID de la compra es requerido'));
      }
      return await repository.getPurchaseById(id.trim());
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener la compra: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}

class UpdateVegetablePurchaseUseCase {
  final VegetablesRepository repository;

  UpdateVegetablePurchaseUseCase(this.repository);

  Future<Either<Failure, VegetablePurchase>> call(String id, List<CreateVegetablePurchaseItemParams> items) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID de la compra es requerido'));
      }
      if (items.isEmpty) {
        return Left(ValidationFailure.required('Productos', 'La compra debe tener al menos un producto'));
      }
      return await repository.updatePurchase(id.trim(), items);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al editar la compra: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}

class DeleteVegetablePurchaseUseCase {
  final VegetablesRepository repository;

  DeleteVegetablePurchaseUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID de la compra es requerido'));
      }
      return await repository.deletePurchase(id.trim());
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al eliminar la compra: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
