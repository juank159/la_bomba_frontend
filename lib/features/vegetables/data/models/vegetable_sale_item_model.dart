import '../../domain/entities/vegetable_item.dart';
import '../../domain/entities/vegetable_sale_item.dart';

class VegetableSaleItemModel extends VegetableSaleItem {
  const VegetableSaleItemModel({
    required super.id,
    required super.saleId,
    super.vegetableItemId,
    required super.description,
    required super.pricingType,
    super.weightKg,
    super.quantity,
    required super.unitPrice,
    required super.total,
  });

  factory VegetableSaleItemModel.fromJson(Map<String, dynamic> json) {
    return VegetableSaleItemModel(
      id: json['id'] as String,
      saleId: json['saleId'] as String? ?? '',
      vegetableItemId: json['vegetableItemId'] as String?,
      description: json['description'] as String? ?? '',
      pricingType: VegetablePricingType.fromString(json['pricingType'] as String? ?? 'weight'),
      weightKg: _parseDouble(json['weightKg']),
      quantity: _parseInt(json['quantity']),
      unitPrice: _parseDouble(json['unitPrice']) ?? 0.0,
      total: _parseDouble(json['total']) ?? 0.0,
    );
  }

  VegetableSaleItem toEntity() {
    return VegetableSaleItem(
      id: id,
      saleId: saleId,
      vegetableItemId: vegetableItemId,
      description: description,
      pricingType: pricingType,
      weightKg: weightKg,
      quantity: quantity,
      unitPrice: unitPrice,
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
