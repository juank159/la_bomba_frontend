import '../../../products/data/models/product_model.dart';
import '../../domain/entities/invoice_item.dart';

/// InvoiceItem model for data layer that extends InvoiceItem entity
/// Handles JSON serialization/deserialization matching backend structure
class InvoiceItemModel extends InvoiceItem {
  const InvoiceItemModel({
    required super.id,
    required super.invoiceId,
    super.productId,
    super.product,
    required super.description,
    required super.quantity,
    required super.unitPrice,
    required super.ivaPercent,
    required super.subtotal,
    required super.taxAmount,
  });

  /// Create InvoiceItemModel from JSON
  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return InvoiceItemModel(
        id: json['id'] as String,
        invoiceId: json['invoiceId'] as String? ?? '',
        productId: json['productId'] as String?,
        product: json['product'] != null
            ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
                .toEntity()
            : null,
        description: json['description'] as String? ?? '',
        quantity: _parseInt(json['quantity']) ?? 0,
        unitPrice: _parseDouble(json['unitPrice']) ?? 0.0,
        ivaPercent: _parseDouble(json['ivaPercent']) ?? 0.0,
        subtotal: _parseDouble(json['subtotal']) ?? 0.0,
        taxAmount: _parseDouble(json['taxAmount']) ?? 0.0,
      );
    } catch (e) {
      throw FormatException('Error parsing InvoiceItemModel from JSON: $e', json);
    }
  }

  /// Convert for invoice creation (only productId and quantity are sent)
  Map<String, dynamic> toCreateJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }

  /// Convert InvoiceItemModel to InvoiceItem entity
  InvoiceItem toEntity() {
    return InvoiceItem(
      id: id,
      invoiceId: invoiceId,
      productId: productId,
      product: product,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      ivaPercent: ivaPercent,
      subtotal: subtotal,
      taxAmount: taxAmount,
    );
  }

  /// Create InvoiceItemModel from InvoiceItem entity
  factory InvoiceItemModel.fromEntity(InvoiceItem item) {
    return InvoiceItemModel(
      id: item.id,
      invoiceId: item.invoiceId,
      productId: item.productId,
      product: item.product,
      description: item.description,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      ivaPercent: item.ivaPercent,
      subtotal: item.subtotal,
      taxAmount: item.taxAmount,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'InvoiceItemModel(id: $id, description: $description, quantity: $quantity, unitPrice: $unitPrice, subtotal: $subtotal, taxAmount: $taxAmount)';
  }
}
