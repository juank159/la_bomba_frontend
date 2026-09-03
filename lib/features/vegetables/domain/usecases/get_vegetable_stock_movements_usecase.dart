import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_stock_movement.dart';
import '../repositories/vegetables_repository.dart';

class GetVegetableStockMovementsUseCase {
  final VegetablesRepository repository;

  GetVegetableStockMovementsUseCase(this.repository);

  Future<Either<Failure, List<VegetableStockMovement>>> call(String itemId) async {
    try {
      return await repository.getStockMovements(itemId);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener el historial de inventario: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
