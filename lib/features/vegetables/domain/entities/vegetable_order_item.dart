import 'package:equatable/equatable.dart';

/// Same values as the regular orders module's MeasurementUnit (kilogramos,
/// libras, unidad) - one shared vocabulary for units across the whole app.
enum VegetableOrderUnit {
  kilogramos('kilogramos'),
  libras('libras'),
  unidad('unidad');

  const VegetableOrderUnit(this.value);
  final String value;

  static VegetableOrderUnit fromString(String value) {
    switch (value) {
      case 'kilogramos':
        return VegetableOrderUnit.kilogramos;
      case 'libras':
        return VegetableOrderUnit.libras;
      case 'unidad':
        return VegetableOrderUnit.unidad;
      default:
        return VegetableOrderUnit.unidad;
    }
  }

  String get displayName {
    switch (this) {
      case VegetableOrderUnit.kilogramos:
        return 'Kilogramos';
      case VegetableOrderUnit.libras:
        return 'Libras';
      case VegetableOrderUnit.unidad:
        return 'Unidades';
    }
  }

  String get shortDisplayName {
    switch (this) {
      case VegetableOrderUnit.kilogramos:
        return 'kg';
      case VegetableOrderUnit.libras:
        return 'lb';
      case VegetableOrderUnit.unidad:
        return 'un';
    }
  }
}

/// A line in a vegetable restock order: just a product name, quantity and
/// unit - no pricing, this is a shopping list, not a sale.
class VegetableOrderItem extends Equatable {
  final String id;
  final String orderId;
  final String? vegetableItemId;
  final String description;
  final double quantity;
  final VegetableOrderUnit unit;

  const VegetableOrderItem({
    required this.id,
    required this.orderId,
    this.vegetableItemId,
    required this.description,
    required this.quantity,
    required this.unit,
  });

  @override
  List<Object?> get props => [id, orderId, vegetableItemId, description, quantity, unit];

  /// Human readable quantity, e.g. "10 kg", "12 un"
  String get quantityLabel {
    final formatted = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(3);
    return '$formatted ${unit.shortDisplayName}';
  }
}
