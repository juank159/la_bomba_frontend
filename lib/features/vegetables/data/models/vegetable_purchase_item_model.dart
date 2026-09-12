import '../../domain/entities/vegetable_purchase_item.dart';

class VegetablePurchaseItemModel extends VegetablePurchaseItem {
  const VegetablePurchaseItemModel({
    required super.id,
    required super.purchaseId,
    super.vegetableItemId,
    required super.description,
    super.quantity,
    super.unitCost,
    required super.total,
  });

  factory VegetablePurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return VegetablePurchaseItemModel(
      id: json['id'] as String,
      purchaseId: json['purchaseId'] as String? ?? '',
      vegetableItemId: json['vegetableItemId'] as String?,
      description: json['description'] as String? ?? '',
      quantity: _parseDouble(json['quantity']),
      unitCost: _parseDouble(json['unitCost']),
      total: _parseDouble(json['total']) ?? 0,
    );
  }

  VegetablePurchaseItem toEntity() {
    return VegetablePurchaseItem(
      id: id,
      purchaseId: purchaseId,
      vegetableItemId: vegetableItemId,
      description: description,
      quantity: quantity,
      unitCost: unitCost,
      total: total,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
