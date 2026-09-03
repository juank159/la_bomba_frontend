import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_item.dart';
import '../entities/vegetable_stock_movement.dart';
import '../repositories/vegetables_repository.dart';

class RegisterVegetableStockMovementUseCase {
  final VegetablesRepository repository;

  RegisterVegetableStockMovementUseCase(this.repository);

  Future<Either<Failure, VegetableItem>> call(String itemId, RegisterStockMovementParams params) async {
    try {
      if (params.quantity == 0) {
        return Left(ValidationFailure.required('Cantidad', 'La cantidad debe ser distinta de 0'));
      }
      if (params.type == StockMovementType.merma && (params.reason == null || params.reason!.trim().isEmpty)) {
        return Left(ValidationFailure.required('Razón', 'Indica por qué se dio de baja este producto'));
      }
      return await repository.registerStockMovement(itemId, params);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al registrar el movimiento de stock: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
