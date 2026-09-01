import 'package:equatable/equatable.dart';
import 'vegetable_sale_item.dart';

/// A completed sale from the vegetables (verduras) module. Independent from
/// Invoice: produce has no IVA and is managed by its own role (verdulero).
class VegetableSale extends Equatable {
  final String id;
  final int number;
  final double total;
  final String soldBy;
  final List<VegetableSaleItem> items;
  final DateTime createdAt;

  const VegetableSale({
    required this.id,
    required this.number,
    required this.total,
    required this.soldBy,
    required this.items,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, number, total, soldBy, items, createdAt];

  /// Formatted sale number with leading zeros (e.g. #000042)
  String get formattedNumber => '#${number.toString().padLeft(6, '0')}';

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
