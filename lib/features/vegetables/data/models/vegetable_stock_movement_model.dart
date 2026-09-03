import '../../domain/entities/vegetable_stock_movement.dart';

class VegetableStockMovementModel extends VegetableStockMovement {
  const VegetableStockMovementModel({
    required super.id,
    required super.vegetableItemId,
    required super.type,
    required super.quantity,
    required super.resultingStock,
    super.reason,
    super.saleId,
    required super.createdBy,
    required super.createdAt,
  });

  factory VegetableStockMovementModel.fromJson(Map<String, dynamic> json) {
    return VegetableStockMovementModel(
      id: json['id'] as String,
      vegetableItemId: json['vegetableItemId'] as String? ?? '',
      type: StockMovementType.fromString(json['type'] as String? ?? 'adjustment'),
      quantity: _parseDouble(json['quantity']) ?? 0,
      resultingStock: _parseDouble(json['resultingStock']) ?? 0,
      reason: json['reason'] as String?,
      saleId: json['saleId'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  VegetableStockMovement toEntity() {
    return VegetableStockMovement(
      id: id,
      vegetableItemId: vegetableItemId,
      type: type,
      quantity: quantity,
      resultingStock: resultingStock,
      reason: reason,
      saleId: saleId,
      createdBy: createdBy,
      createdAt: createdAt,
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
