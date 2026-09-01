import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_category.dart';
import '../repositories/vegetables_repository.dart';

/// Handles both create (id == null) and update (id != null) of a category.
class SaveVegetableCategoryUseCase {
  final VegetablesRepository repository;

  SaveVegetableCategoryUseCase(this.repository);

  Future<Either<Failure, VegetableCategory>> call({
    String? id,
    required VegetableCategoryParams params,
  }) async {
    try {
      if (params.name.trim().isEmpty) {
        return Left(ValidationFailure.required('Nombre', 'El nombre de la categoría es requerido'));
      }

      if (id == null) {
        return await repository.createCategory(params);
      }
      return await repository.updateCategory(id, params);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al guardar la categoría: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
