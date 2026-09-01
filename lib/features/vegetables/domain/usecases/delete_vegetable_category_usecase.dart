import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/vegetables_repository.dart';

class DeleteVegetableCategoryUseCase {
  final VegetablesRepository repository;

  DeleteVegetableCategoryUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID de la categoría es requerido'));
      }
      return await repository.deleteCategory(id.trim());
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al eliminar la categoría: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
