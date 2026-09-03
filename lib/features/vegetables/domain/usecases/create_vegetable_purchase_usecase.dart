import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_purchase.dart';
import '../repositories/vegetables_repository.dart';

class CreateVegetablePurchaseUseCase {
  final VegetablesRepository repository;

  CreateVegetablePurchaseUseCase(this.repository);

  Future<Either<Failure, VegetablePurchase>> call(List<CreateVegetablePurchaseItemParams> items) async {
    try {
      if (items.isEmpty) {
        return Left(ValidationFailure.required('Productos', 'La compra debe tener al menos un producto'));
      }
      return await repository.createPurchase(items);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al registrar la compra: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
