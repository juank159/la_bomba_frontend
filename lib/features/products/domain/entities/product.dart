import 'package:equatable/equatable.dart';
import 'package:pedidos_frontend/app/core/utils/number_formatter.dart';

/// Product entity representing a product in the domain layer
/// Matches the backend Product entity structure
class Product extends Equatable {
  final String id;
  final String description;
  final String barcode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Precios
  final double precioA; // Precio obligatorio
  final double? precioB; // Precio opcional
  final double? precioC; // Precio opcional
  final double? costo; // Costo opcional
  final double iva; // IVA porcentaje

  const Product({
    required this.id,
    required this.description,
    required this.barcode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.precioA,
    this.precioB,
    this.precioC,
    this.costo,
    required this.iva,
  });

  @override
  List<Object?> get props => [
    id,
    description,
    barcode,
    isActive,
    createdAt,
    updatedAt,
    precioA,
    precioB,
    precioC,
    costo,
    iva,
  ];

  @override
  String toString() {
    return 'Product(id: $id, description: $description, barcode: $barcode, isActive: $isActive, precioA: $precioA, precioB: $precioB, precioC: $precioC, costo: $costo, iva: $iva, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Copy with method for creating modified instances
  Product copyWith({
    String? id,
    String? description,
    String? barcode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? precioA,
    double? precioB,
    double? precioC,
    double? costo,
    double? iva,
  }) {
    return Product(
      id: id ?? this.id,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      precioA: precioA ?? this.precioA,
      precioB: precioB ?? this.precioB,
      precioC: precioC ?? this.precioC,
      costo: costo ?? this.costo,
      iva: iva ?? this.iva,
    );
  }

  /// Check if the product is currently active
  bool get isCurrentlyActive => isActive;

  /// Get a display-friendly status text
  String get statusText => isActive ? 'Activo' : 'Inactivo';

  /// Calculate price with IVA included
  double getPrecioConIva(double precio) {
    return precio * (1 + (iva / 100));
  }

  /// Get formatted price string using NumberFormatter
  String getFormattedPrice(double precio) {
    return NumberFormatter.formatCurrency(precio);
  }

  /// Get formatted price with IVA using NumberFormatter
  String getFormattedPriceWithIva(double precio) {
    return NumberFormatter.formatCurrency(getPrecioConIva(precio));
  }

  /// Get primary price formatted using NumberFormatter
  String get precioAFormatted => NumberFormatter.formatCurrency(precioA);

  /// Get primary price with IVA formatted using NumberFormatter
  String get precioAWithIvaFormatted =>
      NumberFormatter.formatCurrency(getPrecioConIva(precioA));

  /// Get all available prices
  List<double> get availablePrices {
    final prices = <double>[precioA];
    if (precioB != null) prices.add(precioB!);
    if (precioC != null) prices.add(precioC!);
    return prices;
  }

  /// Get profit margin (if cost is available)
  double? get profitMargin {
    if (costo == null) return null;
    return ((precioA - costo!) / precioA) * 100;
  }

  /// Get profit margin formatted using NumberFormatter
  String get profitMarginFormatted {
    final margin = profitMargin;
    return margin != null ? NumberFormatter.formatPercentage(margin) : 'N/A';
  }

  /// Compatibility getters for supervisor feature
  String get name => description;
  String get code => barcode;
}
