import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/order_item.dart';
import '../repositories/orders_repository.dart';

/// Parameters for getting order grouped by supplier
class GetOrderGroupedBySupplierParams {
  final String orderId;

  const GetOrderGroupedBySupplierParams({required this.orderId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetOrderGroupedBySupplierParams && other.orderId == orderId;
  }

  @override
  int get hashCode => orderId.hashCode;

  @override
  String toString() {
    return 'GetOrderGroupedBySupplierParams(orderId: $orderId)';
  }
}

/// Use case for getting order items grouped by supplier
/// This is useful for generating separate PDFs per supplier
class GetOrderGroupedBySupplierUseCase {
  final OrdersRepository repository;

  GetOrderGroupedBySupplierUseCase(this.repository);

  /// Execute the use case to get order items grouped by supplier
  ///
  /// [params] - Parameters containing the order ID
  ///
  /// Returns a map of supplier ID to list of order items or a failure
  /// The map key 'unassigned' contains items without a supplier
  Future<Either<Failure, Map<String, List<OrderItem>>>> call(
    GetOrderGroupedBySupplierParams params,
  ) async {
    try {
      if (params.orderId.trim().isEmpty) {
        return Left(ValidationFailure.required('orderId', 'El ID del pedido es requerido'));
      }

      return await repository.getOrderGroupedBySupplier(params.orderId.trim());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener pedido agrupado por proveedor: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
