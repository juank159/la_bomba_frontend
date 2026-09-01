import 'package:equatable/equatable.dart';
import 'vegetable_item.dart';

/// A single line of a completed vegetable sale (snapshot: price/description
/// at the time of sale, independent from the current catalog values).
class VegetableSaleItem extends Equatable {
  final String id;
  final String saleId;
  final String? vegetableItemId;
  final String description;
  final VegetablePricingType pricingType;
  final double? weightKg;
  final int? quantity;
  final double unitPrice;
  final double total;

  const VegetableSaleItem({
    required this.id,
    required this.saleId,
    this.vegetableItemId,
    required this.description,
    required this.pricingType,
    this.weightKg,
    this.quantity,
    required this.unitPrice,
    required this.total,
  });

  @override
  List<Object?> get props => [
    id,
    saleId,
    vegetableItemId,
    description,
    pricingType,
    weightKg,
    quantity,
    unitPrice,
    total,
  ];

  /// Human readable amount sold, e.g. "0.350 kg" or "2 un"
  String get quantityLabel {
    if (pricingType.isWeight) {
      return '${(weightKg ?? 0).toStringAsFixed(3)} kg';
    }
    return '${quantity ?? 0} un';
  }
}
