import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/order.dart' as order_entity;
import '../repositories/orders_repository.dart';

/// Use case for updating an existing order
class UpdateOrderUseCase {
  final OrdersRepository repository;

  UpdateOrderUseCase(this.repository);

  /// Execute the use case to update an order
  /// 
  /// [params] - Parameters containing order ID and updated fields
  /// 
  /// Returns the updated order or a failure
  Future<Either<Failure, order_entity.Order>> call(UpdateOrderParams params) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return Left(validationFailure);
      }

      return await repository.updateOrder(params);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al actualizar el pedido: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Validate update order parameters
  ValidationFailure? _validateParams(UpdateOrderParams params) {
    if (params.id.trim().isEmpty) {
      return ValidationFailure.required('ID', 'El ID del pedido es requerido');
    }

    if (params.description != null && params.description!.trim().isEmpty) {
      return ValidationFailure.required('Descripción', 'La descripción del pedido no puede estar vacía');
    }

    if (params.description != null && params.description!.trim().length < 3) {
      return ValidationFailure.minLength('Descripción', 3, 'La descripción debe tener al menos 3 caracteres');
    }

    if (params.description != null && params.description!.trim().length > 255) {
      return ValidationFailure.maxLength('Descripción', 255, 'La descripción no puede superar los 255 caracteres');
    }

    if (params.status != null && params.status!.trim().isNotEmpty) {
      final allowedStatuses = ['pending', 'completed'];
      if (!allowedStatuses.contains(params.status!.trim())) {
        return const ValidationFailure('El estado debe ser "pending" o "completed"', code: 'INVALID_STATUS');
      }
    }

    if (params.provider != null && params.provider!.trim().length > 100) {
      return ValidationFailure.maxLength('Proveedor', 100, 'El nombre del proveedor no puede superar los 100 caracteres');
    }

    // Check if at least one field is being updated
    if (params.description == null && 
        params.provider == null && 
        params.status == null) {
      return const ValidationFailure('Debe especificar al menos un campo para actualizar', code: 'NO_FIELDS_TO_UPDATE');
    }

    return null;
  }
}