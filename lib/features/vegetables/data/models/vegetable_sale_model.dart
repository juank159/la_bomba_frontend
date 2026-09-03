import '../../domain/entities/vegetable_sale.dart';
import 'vegetable_sale_item_model.dart';

class VegetableSaleModel extends VegetableSale {
  const VegetableSaleModel({
    required super.id,
    required super.number,
    required super.total,
    required super.soldBy,
    required super.paymentMethodId,
    required super.paymentMethodName,
    required super.items,
    required super.createdAt,
  });

  factory VegetableSaleModel.fromJson(Map<String, dynamic> json) {
    final paymentMethod = json['paymentMethod'] as Map<String, dynamic>?;

    return VegetableSaleModel(
      id: json['id'] as String,
      number: _parseInt(json['number']) ?? 0,
      total: _parseDouble(json['total']) ?? 0.0,
      soldBy: json['soldBy'] as String? ?? '',
      paymentMethodId: json['paymentMethodId'] as String? ?? '',
      paymentMethodName: paymentMethod?['name'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => VegetableSaleItemModel.fromJson(item as Map<String, dynamic>).toEntity())
              .toList() ??
          [],
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  VegetableSale toEntity() {
    return VegetableSale(
      id: id,
      number: number,
      total: total,
      soldBy: soldBy,
      paymentMethodId: paymentMethodId,
      paymentMethodName: paymentMethodName,
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
