import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_category.dart';
import '../repositories/vegetables_repository.dart';

class GetVegetableCategoriesUseCase {
  final VegetablesRepository repository;

  GetVegetableCategoriesUseCase(this.repository);

  Future<Either<Failure, List<VegetableCategory>>> call({bool includeInactive = false}) async {
    try {
      return await repository.getCategories(includeInactive: includeInactive);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener las categorías: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
