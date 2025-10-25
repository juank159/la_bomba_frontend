import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';
import '../../../admin_tasks/domain/entities/temporary_product.dart';
import '../../../suppliers/domain/entities/supplier.dart';

/// Measurement unit enum matching backend
enum MeasurementUnit {
  unidad('unidad'),
  bultos('bultos'),
  fardos('fardos'),
  cajas('cajas'),
  paquetes('paquetes'),
  libras('libras'),
  kilogramos('kilogramos'),
  litros('litros'),
  metros('metros'),
  docenas('docenas');

  const MeasurementUnit(this.value);
  final String value;

  static MeasurementUnit fromString(String value) {
    switch (value) {
      case 'unidad':
        return MeasurementUnit.unidad;
      case 'bultos':
        return MeasurementUnit.bultos;
      case 'fardos':
        return MeasurementUnit.fardos;
      case 'cajas':
        return MeasurementUnit.cajas;
      case 'paquetes':
        return MeasurementUnit.paquetes;
      case 'libras':
        return MeasurementUnit.libras;
      case 'kilogramos':
        return MeasurementUnit.kilogramos;
      case 'litros':
        return MeasurementUnit.litros;
      case 'metros':
        return MeasurementUnit.metros;
      case 'docenas':
        return MeasurementUnit.docenas;
      default:
        return MeasurementUnit.unidad;
    }
  }

  String get displayName {
    switch (this) {
      case MeasurementUnit.unidad:
        return 'Unidad';
      case MeasurementUnit.bultos:
        return 'Bultos';
      case MeasurementUnit.fardos:
        return 'Fardos';
      case MeasurementUnit.cajas:
        return 'Cajas';
      case MeasurementUnit.paquetes:
        return 'Paquetes';
      case MeasurementUnit.libras:
        return 'Libras';
      case MeasurementUnit.kilogramos:
        return 'Kilogramos';
      case MeasurementUnit.litros:
        return 'Litros';
      case MeasurementUnit.metros:
        return 'Metros';
      case MeasurementUnit.docenas:
        return 'Docenas';
    }
  }

  String get shortDisplayName {
    switch (this) {
      case MeasurementUnit.unidad:
        return 'Ud';
      case MeasurementUnit.bultos:
        return 'Bultos';
      case MeasurementUnit.fardos:
        return 'Fardos';
      case MeasurementUnit.cajas:
        return 'Cajas';
      case MeasurementUnit.paquetes:
        return 'Pqts';
      case MeasurementUnit.libras:
        return 'Lb';
      case MeasurementUnit.kilogramos:
        return 'Kg';
      case MeasurementUnit.litros:
        return 'Lt';
      case MeasurementUnit.metros:
        return 'Mt';
      case MeasurementUnit.docenas:
        return 'Docenas';
    }
  }
}

/// OrderItem entity representing an order item in the domain layer
/// Matches the backend OrderItem entity structure
class OrderItem extends Equatable {
  final String id;
  final String orderId;
  final String? productId;
  final String? temporaryProductId;
  final String? supplierId;
  final Product? product;
  final TemporaryProduct? temporaryProduct;
  final Supplier? supplier;
  final int existingQuantity;
  final int? requestedQuantity;
  final MeasurementUnit measurementUnit;

  const OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    this.temporaryProductId,
    this.supplierId,
    this.product,
    this.temporaryProduct,
    this.supplier,
    required this.existingQuantity,
    this.requestedQuantity,
    required this.measurementUnit,
  });

  @override
  List<Object?> get props => [
    id,
    orderId,
    productId,
    temporaryProductId,
    supplierId,
    product,
    temporaryProduct,
    supplier,
    existingQuantity,
    requestedQuantity,
    measurementUnit,
  ];

  @override
  String toString() {
    return 'OrderItem(id: $id, orderId: $orderId, productId: $productId, temporaryProductId: $temporaryProductId, existingQuantity: $existingQuantity, requestedQuantity: $requestedQuantity, measurementUnit: ${measurementUnit.value})';
  }

  /// Copy with method for creating modified instances
  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? temporaryProductId,
    String? supplierId,
    Product? product,
    TemporaryProduct? temporaryProduct,
    Supplier? supplier,
    int? existingQuantity,
    int? requestedQuantity,
    MeasurementUnit? measurementUnit,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      temporaryProductId: temporaryProductId ?? this.temporaryProductId,
      supplierId: supplierId ?? this.supplierId,
      product: product ?? this.product,
      temporaryProduct: temporaryProduct ?? this.temporaryProduct,
      supplier: supplier ?? this.supplier,
      existingQuantity: existingQuantity ?? this.existingQuantity,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      measurementUnit: measurementUnit ?? this.measurementUnit,
    );
  }

  /// Check if the item has a product loaded
  bool get hasProduct => product != null;

  /// Check if this is a temporary product
  bool get isTemporaryProduct => temporaryProductId != null;

  /// Get the actual product/temporary product ID
  String get actualProductId => temporaryProductId ?? productId ?? '';

  /// Get product description or fallback
  String get productDescription {
    if (temporaryProduct != null) {
      return '${temporaryProduct!.name} (Nuevo)';
    }
    return product?.description ?? 'Producto no disponible';
  }

  /// Get product barcode or fallback
  String get productBarcode {
    if (temporaryProduct != null) {
      return temporaryProduct!.barcode ?? 'N/A';
    }
    return product?.barcode ?? 'N/A';
  }

  /// Get formatted existing quantity with unit
  String get formattedExistingQuantity {
    return '$existingQuantity ${measurementUnit.shortDisplayName}';
  }

  /// Get formatted requested quantity with unit
  String get formattedRequestedQuantity {
    final quantity = requestedQuantity ?? 0;
    return '$quantity ${measurementUnit.shortDisplayName}';
  }

  /// Check if there's a difference between existing and requested quantity
  bool get hasQuantityDifference {
    return requestedQuantity != null && requestedQuantity != existingQuantity;
  }

  /// Get quantity difference (requested - existing)
  int get quantityDifference {
    return (requestedQuantity ?? 0) - existingQuantity;
  }

  /// Get formatted quantity difference
  String get formattedQuantityDifference {
    final diff = quantityDifference;
    final sign = diff >= 0 ? '+' : '';
    return '$sign$diff ${measurementUnit.shortDisplayName}';
  }

  /// Check if requested quantity is greater than existing
  bool get isQuantityIncreasing {
    return quantityDifference > 0;
  }

  /// Check if requested quantity is less than existing
  bool get isQuantityDecreasing {
    return quantityDifference < 0;
  }
}