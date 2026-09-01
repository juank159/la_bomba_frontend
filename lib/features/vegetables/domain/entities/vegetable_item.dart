import 'package:equatable/equatable.dart';

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
  final VegetablePricingType pricingType;
  final double? pricePerKg;
  final double? fixedPrice;
  final bool isActive;

  const VegetableItem({
    required this.id,
    required this.name,
    required this.pricingType,
    this.pricePerKg,
    this.fixedPrice,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, pricingType, pricePerKg, fixedPrice, isActive];

  VegetableItem copyWith({
    String? id,
    String? name,
    VegetablePricingType? pricingType,
    double? pricePerKg,
    double? fixedPrice,
    bool? isActive,
  }) {
    return VegetableItem(
      id: id ?? this.id,
      name: name ?? this.name,
      pricingType: pricingType ?? this.pricingType,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      isActive: isActive ?? this.isActive,
    );
  }
}
