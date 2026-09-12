import 'package:equatable/equatable.dart';

/// A single line of a completed purchase (snapshot: description/cost at
/// the time of purchase, independent from the current catalog values).
/// Either references a catalog product ([vegetableItemId]/[quantity]/
/// [unitCost] set) or is a "compra libre" line - a one-off total amount
/// with a free description, not tied to any catalog product and not
/// affecting inventory ([vegetableItemId]/[quantity]/[unitCost] null).
class VegetablePurchaseItem extends Equatable {
  final String id;
  final String purchaseId;
  final String? vegetableItemId;
  final String description;
  final double? quantity;
  final double? unitCost;
  final double total;

  const VegetablePurchaseItem({
    required this.id,
    required this.purchaseId,
    this.vegetableItemId,
    required this.description,
    this.quantity,
    this.unitCost,
    required this.total,
  });

  @override
  List<Object?> get props => [id, purchaseId, vegetableItemId, description, quantity, unitCost, total];

  bool get isFreePurchase => vegetableItemId == null;
}
