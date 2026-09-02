import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_order.dart';
import '../repositories/vegetables_repository.dart';

class CreateVegetableOrderUseCase {
  final VegetablesRepository repository;

  CreateVegetableOrderUseCase(this.repository);

  Future<Either<Failure, VegetableOrder>> call(List<CreateVegetableOrderItemParams> items) async {
    try {
      if (items.isEmpty) {
        return Left(ValidationFailure.required('Productos', 'El pedido debe tener al menos un producto'));
      }
      for (final item in items) {
        if ((item.vegetableItemId == null || item.vegetableItemId!.isEmpty) &&
            (item.description == null || item.description!.trim().isEmpty)) {
          return Left(ValidationFailure.required('Producto', 'Cada línea necesita un producto del catálogo o un nombre'));
        }
        if (item.quantity <= 0) {
          return Left(ValidationFailure('La cantidad debe ser mayor a 0', code: 'INVALID_QUANTITY'));
        }
      }
      return await repository.createOrder(items);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al registrar el pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
