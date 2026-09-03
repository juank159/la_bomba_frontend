import 'package:equatable/equatable.dart';
import 'vegetable_category.dart';

/// How a vegetable item is priced: by weight (scale) or a fixed unit price.
enum VegetablePricingType {
  weight('weight'),
  fixed('fixed');

  const VegetablePricingType(this.value);
  final String value;

  static VegetablePricingType fromString(String value) {
    switch (value) {
      case 'weight':
        return VegetablePricingType.weight;
      case 'fixed':
        return VegetablePricingType.fixed;
      default:
        return VegetablePricingType.weight;
    }
  }

  bool get isWeight => this == VegetablePricingType.weight;
  bool get isFixed => this == VegetablePricingType.fixed;
}

/// A catalog entry in the vegetables (verduras) module: either sold by
/// weight (e.g. potatoes, priced per kg and read from the electronic scale)
/// or at a fixed unit price (e.g. a bagged/packaged item like an apple).
class VegetableItem extends Equatable {
  final String id;
  final String name;
  final String? categoryId;
  final VegetableCategory? category;
  final VegetablePricingType pricingType;
  final double? pricePerKg;
  final double? fixedPrice;
  final bool isActive;
  /// Cloudinary URL of the product's photo, or null if it doesn't have one.
  final String? imageUrl;
  /// Current inventory balance: kg if pricingType is weight, units if fixed.
  final double stock;

  const VegetableItem({
    required this.id,
    required this.name,
    this.categoryId,
    this.category,
    required this.pricingType,
    this.pricePerKg,
    this.fixedPrice,
    required this.isActive,
    this.imageUrl,
    this.stock = 0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    categoryId,
    category,
    pricingType,
    pricePerKg,
    fixedPrice,
    isActive,
    imageUrl,
    stock,
  ];

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isOutOfStock => stock <= 0;
  String get stockUnitLabel => pricingType.isWeight ? 'kg' : 'unid.';

  VegetableItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    VegetableCategory? category,
    VegetablePricingType? pricingType,
    double? pricePerKg,
    double? fixedPrice,
    bool? isActive,
    String? imageUrl,
    double? stock,
  }) {
    return VegetableItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      pricingType: pricingType ?? this.pricingType,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
    );
  }
}
