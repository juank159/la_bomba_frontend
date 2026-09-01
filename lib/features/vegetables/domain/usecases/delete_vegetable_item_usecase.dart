import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/vegetables_repository.dart';

class DeleteVegetableItemUseCase {
  final VegetablesRepository repository;

  DeleteVegetableItemUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del producto es requerido'));
      }
      return await repository.deleteItem(id.trim());
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al eliminar el producto: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
