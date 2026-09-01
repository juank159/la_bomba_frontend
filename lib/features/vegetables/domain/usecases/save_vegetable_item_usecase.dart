import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_item.dart';
import '../repositories/vegetables_repository.dart';

/// Handles both create (id == null) and update (id != null) of a catalog item.
class SaveVegetableItemUseCase {
  final VegetablesRepository repository;

  SaveVegetableItemUseCase(this.repository);

  Future<Either<Failure, VegetableItem>> call({
    String? id,
    required VegetableItemParams params,
  }) async {
    try {
      final validationFailure = _validate(params);
      if (validationFailure != null) return Left(validationFailure);

      if (id == null) {
        return await repository.createItem(params);
      }
      return await repository.updateItem(id, params);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al guardar el producto: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  ValidationFailure? _validate(VegetableItemParams params) {
    if (params.name.trim().isEmpty) {
      return ValidationFailure.required('Nombre', 'El nombre del producto es requerido');
    }
    if (params.pricingType.isWeight && (params.pricePerKg == null || params.pricePerKg! <= 0)) {
      return ValidationFailure.required('Precio por kilo', 'Indica el precio por kilo');
    }
    if (params.pricingType.isFixed && (params.fixedPrice == null || params.fixedPrice! <= 0)) {
      return ValidationFailure.required('Precio', 'Indica el precio fijo del producto');
    }
    return null;
  }
}
