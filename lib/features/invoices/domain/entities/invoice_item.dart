import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';

/// InvoiceItem entity representing a line item of an invoice in the domain layer
/// Matches the backend InvoiceItem entity structure
class InvoiceItem extends Equatable {
  final String id;
  final String invoiceId;
  final String? productId;
  final Product? product;
  final String description;
  final int quantity;
  final double unitPrice;
  final double ivaPercent;
  final double subtotal;
  final double taxAmount;

  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    this.productId,
    this.product,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.ivaPercent,
    required this.subtotal,
    required this.taxAmount,
  });

  @override
  List<Object?> get props => [
    id,
    invoiceId,
    productId,
    product,
    description,
    quantity,
    unitPrice,
    ivaPercent,
    subtotal,
    taxAmount,
  ];

  @override
  String toString() {
    return 'InvoiceItem(id: $id, invoiceId: $invoiceId, description: $description, quantity: $quantity, unitPrice: $unitPrice, subtotal: $subtotal, taxAmount: $taxAmount)';
  }

  /// Total for this line item (subtotal + tax)
  double get total => subtotal + taxAmount;

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    Product? product,
    String? description,
    int? quantity,
    double? unitPrice,
    double? ivaPercent,
    double? subtotal,
    double? taxAmount,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      ivaPercent: ivaPercent ?? this.ivaPercent,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
    );
  }
}
