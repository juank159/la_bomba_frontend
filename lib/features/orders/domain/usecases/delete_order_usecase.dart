import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/orders_repository.dart';

/// Parameters for the delete order use case
class DeleteOrderParams {
  final String id;

  const DeleteOrderParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeleteOrderParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeleteOrderParams(id: $id)';
  }
}

/// Use case for deleting an order
class DeleteOrderUseCase {
  final OrdersRepository repository;

  DeleteOrderUseCase(this.repository);

  /// Execute the use case to delete an order
  /// 
  /// [params] - Parameters containing the order ID to delete
  /// 
  /// Returns success (true) or a failure
  Future<Either<Failure, bool>> call(DeleteOrderParams params) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return Left(validationFailure);
      }

      return await repository.deleteOrder(params.id.trim());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al eliminar el pedido: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Validate delete order parameters
  ValidationFailure? _validateParams(DeleteOrderParams params) {
    if (params.id.trim().isEmpty) {
      return ValidationFailure.required('ID', 'El ID del pedido es requerido');
    }

    return null;
  }
}