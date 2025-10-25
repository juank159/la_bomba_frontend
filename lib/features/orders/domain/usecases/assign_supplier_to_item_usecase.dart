import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/order.dart' as order_entity;
import '../repositories/orders_repository.dart';

/// Parameters for assigning a supplier to an order item
class AssignSupplierToItemParams {
  final String orderId;
  final String itemId;
  final String supplierId;

  const AssignSupplierToItemParams({
    required this.orderId,
    required this.itemId,
    required this.supplierId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssignSupplierToItemParams &&
        other.orderId == orderId &&
        other.itemId == itemId &&
        other.supplierId == supplierId;
  }

  @override
  int get hashCode => orderId.hashCode ^ itemId.hashCode ^ supplierId.hashCode;

  @override
  String toString() {
    return 'AssignSupplierToItemParams(orderId: $orderId, itemId: $itemId, supplierId: $supplierId)';
  }
}

/// Use case for assigning a supplier to a specific order item
/// This is an admin-only operation
class AssignSupplierToItemUseCase {
  final OrdersRepository repository;

  AssignSupplierToItemUseCase(this.repository);

  /// Execute the use case to assign a supplier to an order item
  ///
  /// [params] - Parameters containing order ID, item ID, and supplier ID
  ///
  /// Returns the updated order or a failure
  /// Note: This operation requires ADMIN role on the backend
  Future<Either<Failure, order_entity.Order>> call(
    AssignSupplierToItemParams params,
  ) async {
    try {
      // Validate input parameters
      if (params.orderId.trim().isEmpty) {
        return Left(ValidationFailure.required('orderId', 'El ID del pedido es requerido'));
      }

      if (params.itemId.trim().isEmpty) {
        return Left(ValidationFailure.required('itemId', 'El ID del item es requerido'));
      }

      if (params.supplierId.trim().isEmpty) {
        return Left(ValidationFailure.required('supplierId', 'El ID del proveedor es requerido'));
      }

      return await repository.assignSupplierToItem(
        params.orderId.trim(),
        params.itemId.trim(),
        params.supplierId.trim(),
      );
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al asignar proveedor al item: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
