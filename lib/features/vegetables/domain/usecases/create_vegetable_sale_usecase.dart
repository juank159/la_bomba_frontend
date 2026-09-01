import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_sale.dart';
import '../repositories/vegetables_repository.dart';

class CreateVegetableSaleUseCase {
  final VegetablesRepository repository;

  CreateVegetableSaleUseCase(this.repository);

  Future<Either<Failure, VegetableSale>> call(List<CreateVegetableSaleItemParams> items) async {
    try {
      if (items.isEmpty) {
        return Left(ValidationFailure.required('Productos', 'La venta debe tener al menos un producto'));
      }
      return await repository.createSale(items);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al registrar la venta: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
