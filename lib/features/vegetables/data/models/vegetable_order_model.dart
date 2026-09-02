import '../../domain/entities/vegetable_order.dart';
import 'vegetable_order_item_model.dart';

class VegetableOrderModel extends VegetableOrder {
  const VegetableOrderModel({
    required super.id,
    required super.number,
    required super.createdBy,
    required super.items,
    required super.createdAt,
  });

  factory VegetableOrderModel.fromJson(Map<String, dynamic> json) {
    return VegetableOrderModel(
      id: json['id'] as String,
      number: _parseInt(json['number']) ?? 0,
      createdBy: json['createdBy'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => VegetableOrderItemModel.fromJson(item as Map<String, dynamic>).toEntity())
              .toList() ??
          [],
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  VegetableOrder toEntity() {
    return VegetableOrder(
      id: id,
      number: number,
      createdBy: createdBy,
      items: items,
      createdAt: createdAt,
    );
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
