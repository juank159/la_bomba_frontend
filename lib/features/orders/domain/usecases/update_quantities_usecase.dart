import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/orders_repository.dart';

/// Use case for updating requested quantities in order items (admin only)
class UpdateQuantitiesUseCase {
  final OrdersRepository repository;

  UpdateQuantitiesUseCase(this.repository);

  /// Execute the use case to update requested quantities
  /// 
  /// [params] - Parameters containing items with updated quantities
  /// 
  /// Returns success (true) or a failure
  Future<Either<Failure, bool>> call(UpdateQuantitiesParams params) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return Left(validationFailure);
      }

      return await repository.updateRequestedQuantities(params);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al actualizar las cantidades: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Validate update quantities parameters
  ValidationFailure? _validateParams(UpdateQuantitiesParams params) {
    if (params.items.isEmpty) {
      return ValidationFailure.required('Artículos', 'Debe especificar al menos un artículo para actualizar');
    }

    // Validate each item
    for (int i = 0; i < params.items.length; i++) {
      final item = params.items[i];
      
      if (item.id.trim().isEmpty) {
        return ValidationFailure.required('ID del artículo ${i + 1}', 'El ID del artículo es requerido');
      }

      if (item.requestedQuantity < 0) {
        return ValidationFailure('La cantidad solicitada ${i + 1} debe ser mayor o igual a 0', code: 'INVALID_QUANTITY');
      }
    }

    // Check for duplicate item IDs
    final itemIds = params.items.map((item) => item.id).toList();
    final uniqueItemIds = itemIds.toSet();
    if (itemIds.length != uniqueItemIds.length) {
      return const ValidationFailure('No se pueden actualizar artículos duplicados', code: 'DUPLICATE_ITEMS');
    }

    return null;
  }
}