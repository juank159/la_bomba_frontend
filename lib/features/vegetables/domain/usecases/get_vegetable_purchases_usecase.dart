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
