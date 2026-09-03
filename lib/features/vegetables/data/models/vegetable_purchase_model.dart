import '../../domain/entities/vegetable_purchase.dart';
import 'vegetable_purchase_item_model.dart';

class VegetablePurchaseModel extends VegetablePurchase {
  const VegetablePurchaseModel({
    required super.id,
    required super.number,
    required super.total,
    required super.createdBy,
    required super.items,
    required super.createdAt,
  });

  factory VegetablePurchaseModel.fromJson(Map<String, dynamic> json) {
    return VegetablePurchaseModel(
      id: json['id'] as String,
      number: _parseInt(json['number']) ?? 0,
      total: _parseDouble(json['total']) ?? 0.0,
      createdBy: json['createdBy'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => VegetablePurchaseItemModel.fromJson(item as Map<String, dynamic>).toEntity())
              .toList() ??
          [],
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  VegetablePurchase toEntity() {
    return VegetablePurchase(
      id: id,
      number: number,
      total: total,
      createdBy: createdBy,
      items: items,
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
