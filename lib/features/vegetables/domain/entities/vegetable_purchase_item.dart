import 'package:equatable/equatable.dart';

/// A single line of a completed purchase (snapshot: description/cost at
/// the time of purchase, independent from the current catalog values).
class VegetablePurchaseItem extends Equatable {
  final String id;
  final String purchaseId;
  final String vegetableItemId;
  final String description;
  final double quantity;
  final double unitCost;
  final double total;

  const VegetablePurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.vegetableItemId,
    required this.description,
    required this.quantity,
    required this.unitCost,
    required this.total,
  });

  @override
  List<Object?> get props => [id, purchaseId, vegetableItemId, description, quantity, unitCost, total];
}
