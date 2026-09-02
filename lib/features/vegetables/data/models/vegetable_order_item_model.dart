import '../../domain/entities/vegetable_order_item.dart';

class VegetableOrderItemModel extends VegetableOrderItem {
  const VegetableOrderItemModel({
    required super.id,
    required super.orderId,
    super.vegetableItemId,
    required super.description,
    required super.quantity,
    required super.unit,
  });

  factory VegetableOrderItemModel.fromJson(Map<String, dynamic> json) {
    return VegetableOrderItemModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      vegetableItemId: json['vegetableItemId'] as String?,
      description: json['description'] as String? ?? '',
      quantity: _parseDouble(json['quantity']) ?? 0.0,
      unit: VegetableOrderUnit.fromString(json['unit'] as String? ?? 'unidad'),
    );
  }

  VegetableOrderItem toEntity() {
    return VegetableOrderItem(
      id: id,
      orderId: orderId,
      vegetableItemId: vegetableItemId,
      description: description,
      quantity: quantity,
      unit: unit,
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
