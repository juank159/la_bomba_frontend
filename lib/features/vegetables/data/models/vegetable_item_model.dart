import '../../domain/entities/vegetable_item.dart';
import 'vegetable_category_model.dart';

class VegetableItemModel extends VegetableItem {
  const VegetableItemModel({
    required super.id,
    required super.name,
    super.categoryId,
    super.category,
    required super.pricingType,
    super.pricePerKg,
    super.fixedPrice,
    required super.isActive,
  });

  factory VegetableItemModel.fromJson(Map<String, dynamic> json) {
    return VegetableItemModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      category: json['category'] != null
          ? VegetableCategoryModel.fromJson(json['category'] as Map<String, dynamic>).toEntity()
          : null,
      pricingType: VegetablePricingType.fromString(json['pricingType'] as String? ?? 'weight'),
      pricePerKg: _parseDouble(json['pricePerKg']),
      fixedPrice: _parseDouble(json['fixedPrice']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
      'pricingType': pricingType.value,
      if (pricingType.isWeight) 'pricePerKg': pricePerKg,
      if (pricingType.isFixed) 'fixedPrice': fixedPrice,
    };
  }

  VegetableItem toEntity() {
    return VegetableItem(
      id: id,
      name: name,
      categoryId: categoryId,
      category: category,
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
