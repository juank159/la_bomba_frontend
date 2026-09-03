import 'package:equatable/equatable.dart';
import 'vegetable_purchase_item.dart';

/// A completed purchase of produce: what was bought and its cost. Increases
/// inventory automatically (see VegetablesController.createPurchase).
class VegetablePurchase extends Equatable {
  final String id;
  final int number;
  final double total;
  final String createdBy;
  final List<VegetablePurchaseItem> items;
  final DateTime createdAt;

  const VegetablePurchase({
    required this.id,
    required this.number,
    required this.total,
    required this.createdBy,
    required this.items,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, number, total, createdBy, items, createdAt];

  String get formattedNumber => '#${number.toString().padLeft(6, '0')}';

  String get formattedCreatedAtWithTime {
    final localTime = createdAt.toLocal();
    int hour = localTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    return '${localTime.day}/${localTime.month}/${localTime.year} $hour:${localTime.minute.toString().padLeft(2, '0')} $period';
  }
}
