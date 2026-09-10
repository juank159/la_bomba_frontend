import 'package:equatable/equatable.dart';
import 'vegetable_purchase_item.dart';

/// Where the money for the purchase came from: CAJA deducts it from the
/// currently open cash session's expected cash (there must be one open);
/// EXTERNAL is money that never passed through the register's cash. Mirrors
/// ExpenseFundingSource (vegetable_expenses feature) - own enum per module
/// instead of sharing one, to keep the two decoupled.
enum PurchaseFundingSource {
  caja('caja'),
  external('external');

  const PurchaseFundingSource(this.value);
  final String value;

  static PurchaseFundingSource fromString(String value) {
    return value == 'caja' ? PurchaseFundingSource.caja : PurchaseFundingSource.external;
  }

  String get label => this == PurchaseFundingSource.caja ? 'Caja' : 'Dinero externo';
}

/// A completed purchase of produce: what was bought and its cost. Increases
/// inventory automatically (see VegetablesController.createPurchase).
class VegetablePurchase extends Equatable {
  final String id;
  final int number;
  final double total;
  final String createdBy;
  final PurchaseFundingSource fundingSource;
  final String? cashSessionId;
  final bool isActive;
  final List<VegetablePurchaseItem> items;
  final DateTime createdAt;

  const VegetablePurchase({
    required this.id,
    required this.number,
    required this.total,
    required this.createdBy,
    required this.fundingSource,
    this.cashSessionId,
    this.isActive = true,
    required this.items,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, number, total, createdBy, fundingSource, cashSessionId, isActive, items, createdAt];

  VegetablePurchase copyWith({bool? isActive}) {
    return VegetablePurchase(
      id: id,
      number: number,
      total: total,
      createdBy: createdBy,
      fundingSource: fundingSource,
      cashSessionId: cashSessionId,
      isActive: isActive ?? this.isActive,
      items: items,
      createdAt: createdAt,
    );
  }

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
