import 'package:equatable/equatable.dart';
import 'vegetable_order_item.dart';

/// A restock/shopping list ("pedido") for the vegetables module. Simpler
/// than the regular Order: no supplier, no status - just a printable list
/// with a history of what was ordered and when.
class VegetableOrder extends Equatable {
  final String id;
  final int number;
  final String createdBy;
  final List<VegetableOrderItem> items;
  final DateTime createdAt;

  const VegetableOrder({
    required this.id,
    required this.number,
    required this.createdBy,
    required this.items,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, number, createdBy, items, createdAt];

  /// Formatted order number with leading zeros (e.g. #000042)
  String get formattedNumber => '#${number.toString().padLeft(6, '0')}';

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedCreatedAtWithTime {
    final localTime = createdAt.toLocal();
    int hour = localTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    return '${localTime.day}/${localTime.month}/${localTime.year} $hour:${localTime.minute.toString().padLeft(2, '0')} $period';
  }
}
