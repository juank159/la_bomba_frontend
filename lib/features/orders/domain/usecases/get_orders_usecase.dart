import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/order.dart' as order_entity;
import '../repositories/orders_repository.dart';

/// Parameters for the get orders use case
class GetOrdersParams {
  final int page;
  final int limit;
  final String? search;
  final String? status;

  const GetOrdersParams({
    this.page = 0,
    this.limit = 20,
    this.search,
    this.status,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetOrdersParams &&
        other.page == page &&
        other.limit == limit &&
        other.search == search &&
        other.status == status;
  }

  @override
  int get hashCode => page.hashCode ^ limit.hashCode ^ search.hashCode ^ status.hashCode;

  @override
  String toString() {
    return 'GetOrdersParams(page: $page, limit: $limit, search: $search, status: $status)';
  }

  GetOrdersParams copyWith({
    int? page,
    int? limit,
    String? search,
    String? status,
  }) {
    return GetOrdersParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
    );
  }
}

/// Use case for getting orders with pagination, search, and status filtering
class GetOrdersUseCase {
  final OrdersRepository repository;

  GetOrdersUseCase(this.repository);

  /// Execute the use case to get orders
  /// 
  /// [params] - Optional parameters for pagination, search, and filtering
  /// 
  /// Returns a list of orders or a failure
  Future<Either<Failure, List<order_entity.Order>>> call([GetOrdersParams? params]) async {
    final parameters = params ?? const GetOrdersParams();
    
    try {
      // Always use getAllOrders method with all parameters to ensure consistency
      return await repository.getAllOrders(
        page: parameters.page,
        limit: parameters.limit,
        search: parameters.search?.trim().isNotEmpty == true ? parameters.search!.trim() : null,
        status: parameters.status?.trim().isNotEmpty == true ? parameters.status!.trim() : null,
      );
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener pedidos: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Get orders count for pagination
  Future<Either<Failure, int>> getCount([String? search, String? status]) async {
    try {
      return await repository.getOrdersCount(
        search: search,
        status: status,
      );
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener el conteo de pedidos: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

/// Parameters for getting a single order by ID
class GetOrderByIdParams {
  final String id;

  const GetOrderByIdParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetOrderByIdParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GetOrderByIdParams(id: $id)';
  }
}

/// Use case for getting a single order by ID
class GetOrderByIdUseCase {
  final OrdersRepository repository;

  GetOrderByIdUseCase(this.repository);

  /// Execute the use case to get an order by ID
  /// 
  /// [params] - Parameters containing the order ID
  /// 
  /// Returns the order with items or a failure
  Future<Either<Failure, order_entity.Order>> call(GetOrderByIdParams params) async {
    try {
      if (params.id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del pedido es requerido'));
      }

      return await repository.getOrderById(params.id.trim());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener el pedido: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}