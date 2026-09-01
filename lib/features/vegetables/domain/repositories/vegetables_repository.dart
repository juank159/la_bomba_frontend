import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_item.dart';
import '../entities/vegetable_sale.dart';

/// Parameters for creating/updating a catalog item
class VegetableItemParams {
  final String name;
  final VegetablePricingType pricingType;
  final double? pricePerKg;
  final double? fixedPrice;

  const VegetableItemParams({
    required this.name,
    required this.pricingType,
    this.pricePerKg,
    this.fixedPrice,
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

abstract class VegetablesRepository {
  // ---- Catálogo ----
  Future<Either<Failure, List<VegetableItem>>> getItems({bool includeInactive = false});
  Future<Either<Failure, VegetableItem>> createItem(VegetableItemParams params);
  Future<Either<Failure, VegetableItem>> updateItem(String id, VegetableItemParams params);
  Future<Either<Failure, void>> deleteItem(String id);

  // ---- Ventas ----
  Future<Either<Failure, VegetableSale>> createSale(List<CreateVegetableSaleItemParams> items);
  Future<Either<Failure, List<VegetableSale>>> getSales();
  Future<Either<Failure, VegetableSale>> getSaleById(String id);
}
