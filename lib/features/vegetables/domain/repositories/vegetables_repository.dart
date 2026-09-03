import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_category.dart';
import '../entities/vegetable_item.dart';
import '../entities/vegetable_order.dart';
import '../entities/vegetable_order_item.dart';
import '../entities/vegetable_sale.dart';
import '../entities/vegetable_stock_movement.dart';
import '../entities/vegetable_purchase.dart';

/// Parameters for creating/updating a category
class VegetableCategoryParams {
  final String name;

  const VegetableCategoryParams({required this.name});
}

/// Parameters for creating/updating a catalog item
class VegetableItemParams {
  final String name;
  final String? categoryId;
  final VegetablePricingType pricingType;
  final double? pricePerKg;
  final double? fixedPrice;
  /// Base64 (no data: prefix), already resized/compressed client-side.
  /// Null means "leave the photo as is" on update; pass an empty string
  /// to explicitly remove it.
  final String? image;

  const VegetableItemParams({
    required this.name,
    this.categoryId,
    required this.pricingType,
    this.pricePerKg,
    this.fixedPrice,
    this.image,
  });
}

/// Parameters for a single line item when creating a sale
class CreateVegetableSaleItemParams {
  final String vegetableItemId;
  final double? weightKg;
  final int? quantity;

  const CreateVegetableSaleItemParams({
    required this.vegetableItemId,
    this.weightKg,
    this.quantity,
  });
}

/// Parameters for a single line item when creating an order (pedido).
/// Either [vegetableItemId] (catalog product) or [description] (one-off
/// manual item) must be provided.
class CreateVegetableOrderItemParams {
  final String? vegetableItemId;
  final String? description;
  final double quantity;
  final VegetableOrderUnit unit;

  const CreateVegetableOrderItemParams({
    this.vegetableItemId,
    this.description,
    required this.quantity,
    required this.unit,
  });
}

/// Parameters to register a stock movement. [type] must be `in`, `merma`
/// or `adjustment` - `sale` is created only by the backend itself.
/// [quantity] is a positive magnitude for `in`/`merma`; for `adjustment`
/// it's a signed delta (the backend applies it as-is).
class RegisterStockMovementParams {
  final StockMovementType type;
  final double quantity;
  final String? reason;

  const RegisterStockMovementParams({
    required this.type,
    required this.quantity,
    this.reason,
  });
}

/// Parameters for a single line item when creating a purchase. Only
/// products already in the catalog - unlike orders (pedidos), a purchase
/// always affects real inventory.
class CreateVegetablePurchaseItemParams {
  final String vegetableItemId;
  final double quantity;
  final double unitCost;

  const CreateVegetablePurchaseItemParams({
    required this.vegetableItemId,
    required this.quantity,
    required this.unitCost,
  });
}

abstract class VegetablesRepository {
  // ---- Categorías ----
  Future<Either<Failure, List<VegetableCategory>>> getCategories({bool includeInactive = false});
  Future<Either<Failure, VegetableCategory>> createCategory(VegetableCategoryParams params);
  Future<Either<Failure, VegetableCategory>> updateCategory(String id, VegetableCategoryParams params);
  Future<Either<Failure, void>> deleteCategory(String id);

  // ---- Catálogo ----
  Future<Either<Failure, List<VegetableItem>>> getItems({bool includeInactive = false});
  Future<Either<Failure, VegetableItem>> createItem(VegetableItemParams params);
  Future<Either<Failure, VegetableItem>> updateItem(String id, VegetableItemParams params);
  Future<Either<Failure, void>> deleteItem(String id);

  // ---- Ventas ----
  Future<Either<Failure, VegetableSale>> createSale(List<CreateVegetableSaleItemParams> items, String paymentMethodId);
  Future<Either<Failure, List<VegetableSale>>> getSales();
  Future<Either<Failure, VegetableSale>> getSaleById(String id);

  // ---- Pedidos ----
  Future<Either<Failure, VegetableOrder>> createOrder(List<CreateVegetableOrderItemParams> items);
  Future<Either<Failure, List<VegetableOrder>>> getOrders();
  Future<Either<Failure, VegetableOrder>> getOrderById(String id);

  // ---- Inventario / Merma ----
  Future<Either<Failure, VegetableItem>> registerStockMovement(String itemId, RegisterStockMovementParams params);
  Future<Either<Failure, List<VegetableStockMovement>>> getStockMovements(String itemId);

  // ---- Compras ----
  Future<Either<Failure, VegetablePurchase>> createPurchase(List<CreateVegetablePurchaseItemParams> items);
  Future<Either<Failure, List<VegetablePurchase>>> getPurchases();
  Future<Either<Failure, VegetablePurchase>> getPurchaseById(String id);
}
