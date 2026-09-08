import 'package:equatable/equatable.dart';

/// Same values as the regular orders module's MeasurementUnit (kilogramos,
/// libras, unidad), plus units specific to how produce actually gets
/// ordered from a supplier (cajas, bultos, etc.) - one shared vocabulary
/// for the first three, extended for this module's own needs.
enum VegetableOrderUnit {
  kilogramos('kilogramos'),
  libras('libras'),
  unidad('unidad'),
  caja('caja'),
  bolsa('bolsa'),
  bandeja('bandeja'),
  cesta('cesta'),
  bulto('bulto'),
  rollo('rollo'),
  docena('docena'),
  canasta('canasta');

  const VegetableOrderUnit(this.value);
  final String value;

  static VegetableOrderUnit fromString(String value) {
    return VegetableOrderUnit.values.firstWhere(
      (u) => u.value == value,
      orElse: () => VegetableOrderUnit.unidad,
    );
  }

  String get displayName {
    switch (this) {
      case VegetableOrderUnit.kilogramos:
        return 'Kilogramos';
      case VegetableOrderUnit.libras:
        return 'Libras';
      case VegetableOrderUnit.unidad:
        return 'Unidades';
      case VegetableOrderUnit.caja:
        return 'Cajas';
      case VegetableOrderUnit.bolsa:
        return 'Bolsas';
      case VegetableOrderUnit.bandeja:
        return 'Bandejas';
      case VegetableOrderUnit.cesta:
        return 'Cestas';
      case VegetableOrderUnit.bulto:
        return 'Bultos';
      case VegetableOrderUnit.rollo:
        return 'Rollos';
      case VegetableOrderUnit.docena:
        return 'Docenas';
      case VegetableOrderUnit.canasta:
        return 'Canastas';
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
      case VegetableOrderUnit.caja:
        return 'caja';
      case VegetableOrderUnit.bolsa:
        return 'bolsa';
      case VegetableOrderUnit.bandeja:
        return 'bandeja';
      case VegetableOrderUnit.cesta:
        return 'cesta';
      case VegetableOrderUnit.bulto:
        return 'bulto';
      case VegetableOrderUnit.rollo:
        return 'rollo';
      case VegetableOrderUnit.docena:
        return 'docena';
      case VegetableOrderUnit.canasta:
        return 'canasta';
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
