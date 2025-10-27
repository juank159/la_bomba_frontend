import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/order.dart' as order_entity;
import '../entities/order_item.dart';

/// Parameters for creating a new order
class CreateOrderParams {
  final String description;
  final String? provider;
  final List<CreateOrderItemParams> items;

  const CreateOrderParams({
    required this.description,
    this.provider,
    required this.items,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateOrderParams &&
        other.description == description &&
        other.provider == provider &&
        other.items.length == items.length;
  }

  @override
  int get hashCode => description.hashCode ^ provider.hashCode ^ items.hashCode;

  @override
  String toString() {
    return 'CreateOrderParams(description: $description, provider: $provider, items: ${items.length})';
  }
}

/// Parameters for creating an order item
class CreateOrderItemParams {
  final String? productId;
  final String? temporaryProductId;
  final String? supplierId;
  final int existingQuantity;
  final int? requestedQuantity;
  final String measurementUnit;

  const CreateOrderItemParams({
    this.productId,
    this.temporaryProductId,
    this.supplierId,
    required this.existingQuantity,
    this.requestedQuantity,
    required this.measurementUnit,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateOrderItemParams &&
        other.productId == productId &&
        other.temporaryProductId == temporaryProductId &&
        other.supplierId == supplierId &&
        other.existingQuantity == existingQuantity &&
        other.requestedQuantity == requestedQuantity &&
        other.measurementUnit == measurementUnit;
  }

  @override
  int get hashCode {
    return productId.hashCode ^
        temporaryProductId.hashCode ^
        supplierId.hashCode ^
        existingQuantity.hashCode ^
        requestedQuantity.hashCode ^
        measurementUnit.hashCode;
  }
}

/// Parameters for updating an order
class UpdateOrderParams {
  final String id;
  final String? description;
  final String? provider;
  final String? status;

  const UpdateOrderParams({
    required this.id,
    this.description,
    this.provider,
    this.status,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateOrderParams &&
        other.id == id &&
        other.description == description &&
        other.provider == provider &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        description.hashCode ^
        provider.hashCode ^
        status.hashCode;
  }
}

/// Parameters for updating order item quantities (admin only)
class UpdateQuantitiesParams {
  final List<UpdateQuantityItem> items;

  const UpdateQuantitiesParams({
    required this.items,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateQuantitiesParams &&
        other.items.length == items.length;
  }

  @override
  int get hashCode => items.hashCode;
}

/// Individual item for updating quantities
class UpdateQuantityItem {
  final String id;
  final int requestedQuantity;

  const UpdateQuantityItem({
    required this.id,
    required this.requestedQuantity,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateQuantityItem &&
        other.id == id &&
        other.requestedQuantity == requestedQuantity;
  }

  @override
  int get hashCode => id.hashCode ^ requestedQuantity.hashCode;
}

/// order_entity.Orders repository interface defining the contract for orders data operations
abstract class OrdersRepository {
  /// Get all orders with optional pagination and search
  /// 
  /// [page] - The page number (0-based)
  /// [limit] - The number of items per page
  /// [search] - Optional search query to filter orders by description or provider
  /// [status] - Optional status filter
  /// 
  /// Returns a list of orders or a failure
  Future<Either<Failure, List<order_entity.Order>>> getAllOrders({
    int page = 0,
    int limit = 20,
    String? search,
    String? status,
  });

  /// Get a specific order by its ID
  /// 
  /// [id] - The unique identifier of the order
  /// 
  /// Returns the order with its items or a failure
  Future<Either<Failure, order_entity.Order>> getOrderById(String id);

  /// Create a new order
  /// 
  /// [params] - The order creation parameters
  /// 
  /// Returns the created order or a failure
  Future<Either<Failure, order_entity.Order>> createOrder(CreateOrderParams params);

  /// Update an existing order
  /// 
  /// [params] - The order update parameters
  /// 
  /// Returns the updated order or a failure
  Future<Either<Failure, order_entity.Order>> updateOrder(UpdateOrderParams params);

  /// Delete an order
  /// 
  /// [id] - The unique identifier of the order to delete
  /// 
  /// Returns success (true) or a failure
  Future<Either<Failure, bool>> deleteOrder(String id);

  /// Update requested quantities for order items (admin only)
  /// 
  /// [params] - The quantity update parameters
  /// 
  /// Returns success (true) or a failure
  Future<Either<Failure, bool>> updateRequestedQuantities(UpdateQuantitiesParams params);

  /// Search orders by description or provider
  /// 
  /// [query] - The search query to filter orders
  /// [page] - The page number (0-based)  
  /// [limit] - The number of items per page
  /// [status] - Optional status filter
  /// 
  /// Returns a list of matching orders or a failure
  Future<Either<Failure, List<order_entity.Order>>> searchOrders(
    String query, {
    int page = 0,
    int limit = 20,
    String? status,
  });

  /// Get total count of orders (for pagination)
  /// 
  /// [search] - Optional search query to count filtered results
  /// [status] - Optional status filter
  /// 
  /// Returns the total count or a failure
  Future<Either<Failure, int>> getOrdersCount({
    String? search,
    String? status,
  });

  /// Get orders by status
  /// 
  /// [status] - The status to filter by ('pending' or 'completed')
  /// [page] - The page number (0-based)
  /// [limit] - The number of items per page
  /// 
  /// Returns a list of orders with the specified status or a failure
  Future<Either<Failure, List<order_entity.Order>>> getOrdersByStatus(
    String status, {
    int page = 0,
    int limit = 20,
  });

  /// Add product to existing order
  ///
  /// [orderId] - The ID of the order to add the product to
  /// [productId] - The ID of the product to add (optional if temporaryProductId is provided)
  /// [temporaryProductId] - The ID of the temporary product to add (optional if productId is provided)
  /// [existingQuantity] - The existing quantity of the product
  /// [requestedQuantity] - The optional requested quantity
  /// [measurementUnit] - The measurement unit for the product
  ///
  /// Returns the updated order or a failure
  Future<Either<Failure, order_entity.Order>> addProductToOrder(
    String orderId,
    String? productId,
    int existingQuantity,
    int? requestedQuantity,
    String measurementUnit, {
    String? temporaryProductId,
    String? supplierId,
  });

  /// Remove product from existing order
  /// 
  /// [orderId] - The ID of the order to remove the product from
  /// [itemId] - The ID of the order item to remove
  /// 
  /// Returns the updated order or a failure
  Future<Either<Failure, order_entity.Order>> removeProductFromOrder(
    String orderId,
    String itemId,
  );

  /// Update quantities for specific order item
  ///
  /// [orderId] - The ID of the order containing the item
  /// [itemId] - The ID of the order item to update
  /// [existingQuantity] - The optional new existing quantity
  /// [requestedQuantity] - The optional new requested quantity
  ///
  /// Returns the updated order or a failure
  Future<Either<Failure, order_entity.Order>> updateOrderItemQuantity(
    String orderId,
    String itemId,
    int? existingQuantity,
    int? requestedQuantity,
    MeasurementUnit? measurementUnit, {
    String? supplierId,
  });

  /// Get order items grouped by supplier
  ///
  /// [orderId] - The ID of the order to group items by supplier
  ///
  /// Returns a map of supplier ID to list of order items or a failure
  Future<Either<Failure, Map<String, List<OrderItem>>>> getOrderGroupedBySupplier(
    String orderId,
  );

  /// Assign a supplier to an order item (admin only)
  ///
  /// [orderId] - The ID of the order containing the item
  /// [itemId] - The ID of the order item to assign supplier to
  /// [supplierId] - The ID of the supplier to assign
  ///
  /// Returns the updated order or a failure
  Future<Either<Failure, order_entity.Order>> assignSupplierToItem(
    String orderId,
    String itemId,
    String supplierId,
  );
}