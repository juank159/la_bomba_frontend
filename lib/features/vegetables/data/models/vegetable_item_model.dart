import '../../domain/entities/vegetable_item.dart';

class VegetableItemModel extends VegetableItem {
  const VegetableItemModel({
    required super.id,
    required super.name,
    required super.pricingType,
    super.pricePerKg,
    super.fixedPrice,
    required super.isActive,
  });

  factory VegetableItemModel.fromJson(Map<String, dynamic> json) {
    return VegetableItemModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      pricingType: VegetablePricingType.fromString(json['pricingType'] as String? ?? 'weight'),
      pricePerKg: _parseDouble(json['pricePerKg']),
      fixedPrice: _parseDouble(json['fixedPrice']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'pricingType': pricingType.value,
      if (pricingType.isWeight) 'pricePerKg': pricePerKg,
      if (pricingType.isFixed) 'fixedPrice': fixedPrice,
    };
  }

  VegetableItem toEntity() {
    return VegetableItem(
      id: id,
      name: name,
      pricingType: pricingType,
      pricePerKg: pricePerKg,
      fixedPrice: fixedPrice,
      isActive: isActive,
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
