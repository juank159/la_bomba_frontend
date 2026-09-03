import 'package:equatable/equatable.dart';

/// How a stock movement changed the balance. `sale` is created
/// automatically by the backend when a sale happens - it's never created
/// directly from the app, only the other three are user-initiated.
enum StockMovementType {
  in_('in'),
  sale('sale'),
  merma('merma'),
  adjustment('adjustment');

  const StockMovementType(this.value);
  final String value;

  static StockMovementType fromString(String value) {
    return StockMovementType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => StockMovementType.adjustment,
    );
  }

  String get label => switch (this) {
        StockMovementType.in_ => 'Entrada',
        StockMovementType.sale => 'Venta',
        StockMovementType.merma => 'Merma',
        StockMovementType.adjustment => 'Ajuste',
      };
}

/// A single change to a [VegetableItem]'s stock balance: an entry, an
/// automatic deduction from a sale, a merma (damaged/spoiled write-off), or
/// a manual correction. `quantity` is signed (negative = stock went down).
class VegetableStockMovement extends Equatable {
  final String id;
  final String vegetableItemId;
  final StockMovementType type;
  final double quantity;
  final double resultingStock;
  final String? reason;
  final String? saleId;
  final String createdBy;
  final DateTime createdAt;

  const VegetableStockMovement({
    required this.id,
    required this.vegetableItemId,
    required this.type,
    required this.quantity,
    required this.resultingStock,
    this.reason,
    this.saleId,
    required this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        vegetableItemId,
        type,
        quantity,
        resultingStock,
        reason,
        saleId,
        createdBy,
        createdAt,
      ];

  bool get isPositive => quantity > 0;

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
