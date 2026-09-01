import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_item.dart';
import '../repositories/vegetables_repository.dart';

class GetVegetableItemsUseCase {
  final VegetablesRepository repository;

  GetVegetableItemsUseCase(this.repository);

  Future<Either<Failure, List<VegetableItem>>> call({bool includeInactive = false}) async {
    try {
      return await repository.getItems(includeInactive: includeInactive);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener el catálogo de verduras: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
