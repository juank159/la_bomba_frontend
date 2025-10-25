import '../../../products/domain/entities/product.dart';
import '../../../products/data/models/product_model.dart';
import '../../../admin_tasks/domain/entities/temporary_product.dart';
import '../../../admin_tasks/data/models/temporary_product_model.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../suppliers/data/models/supplier_model.dart';
import '../../domain/entities/order_item.dart';

/// OrderItem model for data layer that extends OrderItem entity
/// Handles JSON serialization/deserialization matching backend structure
class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.orderId,
    super.productId,
    super.temporaryProductId,
    super.supplierId,
    super.product,
    super.temporaryProduct,
    super.supplier,
    required super.existingQuantity,
    super.requestedQuantity,
    required super.measurementUnit,
  });

  /// Create OrderItemModel from JSON
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return OrderItemModel(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        productId: json['productId'] as String?,
        temporaryProductId: json['temporaryProductId'] as String?,
        supplierId: json['supplierId'] as String?,
        product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>).toEntity()
          : null,
        temporaryProduct: json['temporaryProduct'] != null
          ? TemporaryProductModel.fromJson(json['temporaryProduct'] as Map<String, dynamic>).toEntity()
          : null,
        supplier: json['supplier'] != null
          ? SupplierModel.fromJson(json['supplier'] as Map<String, dynamic>).toEntity()
          : null,
        existingQuantity: json['existingQuantity'] as int? ?? 0,
        requestedQuantity: json['requestedQuantity'] as int?,
        measurementUnit: MeasurementUnit.fromString(
          json['measurementUnit'] as String? ?? 'unidad'
        ),
      );
    } catch (e) {
      throw FormatException('Error parsing OrderItemModel from JSON: $e', json);
    }
  }

  /// Convert OrderItemModel to JSON
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'orderId': orderId,
      'existingQuantity': existingQuantity,
      'requestedQuantity': requestedQuantity,
      'measurementUnit': measurementUnit.value,
    };

    if (productId != null) {
      json['productId'] = productId!;
    }

    if (temporaryProductId != null) {
      json['temporaryProductId'] = temporaryProductId!;
    }

    if (supplierId != null) {
      json['supplierId'] = supplierId!;
    }

    if (product != null) {
      json['product'] = ProductModel.fromEntity(product!).toJson();
    }

    if (temporaryProduct != null) {
      json['temporaryProduct'] = TemporaryProductModel.fromEntity(temporaryProduct!).toJson();
    }

    if (supplier != null) {
      json['supplier'] = SupplierModel.fromEntity(supplier!).toJson();
    }

    return json;
  }

  /// Convert for order creation (without id and orderId)
  Map<String, dynamic> toCreateJson() {
    final json = {
      'existingQuantity': existingQuantity,
      'requestedQuantity': requestedQuantity,
      'measurementUnit': measurementUnit.value,
    };

    if (productId != null) {
      json['productId'] = productId!;
    }

    if (temporaryProductId != null) {
      json['temporaryProductId'] = temporaryProductId!;
    }

    if (supplierId != null) {
      json['supplierId'] = supplierId!;
    }

    return json;
  }

  /// Convert OrderItemModel to OrderItem entity
  OrderItem toEntity() {
    return OrderItem(
      id: id,
      orderId: orderId,
      productId: productId,
      temporaryProductId: temporaryProductId,
      supplierId: supplierId,
      product: product,
      temporaryProduct: temporaryProduct,
      supplier: supplier,
      existingQuantity: existingQuantity,
      requestedQuantity: requestedQuantity,
      measurementUnit: measurementUnit,
    );
  }

  /// Create OrderItemModel from OrderItem entity
  factory OrderItemModel.fromEntity(OrderItem orderItem) {
    return OrderItemModel(
      id: orderItem.id,
      orderId: orderItem.orderId,
      productId: orderItem.productId,
      temporaryProductId: orderItem.temporaryProductId,
      supplierId: orderItem.supplierId,
      product: orderItem.product,
      temporaryProduct: orderItem.temporaryProduct,
      supplier: orderItem.supplier,
      existingQuantity: orderItem.existingQuantity,
      requestedQuantity: orderItem.requestedQuantity,
      measurementUnit: orderItem.measurementUnit,
    );
  }

  /// Create a copy with updated values
  @override
  OrderItemModel copyWith({
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
    return OrderItemModel(
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

  @override
  String toString() {
    return 'OrderItemModel(id: $id, orderId: $orderId, productId: $productId, temporaryProductId: $temporaryProductId, existingQuantity: $existingQuantity, requestedQuantity: $requestedQuantity, measurementUnit: ${measurementUnit.value})';
  }

  /// Create empty OrderItemModel for testing or initial state
  factory OrderItemModel.empty() {
    return const OrderItemModel(
      id: '',
      orderId: '',
      productId: '',
      product: null,
      existingQuantity: 0,
      requestedQuantity: null,
      measurementUnit: MeasurementUnit.unidad,
    );
  }

  /// Validate if the OrderItemModel has valid data
  bool get isValid {
    return id.isNotEmpty &&
           orderId.isNotEmpty &&
           (productId != null && productId!.isNotEmpty || temporaryProductId != null && temporaryProductId!.isNotEmpty) &&
           existingQuantity >= 0 &&
           (requestedQuantity == null || requestedQuantity! >= 0);
  }

  /// Create OrderItemModel for new order creation (without id and orderId)
  factory OrderItemModel.forCreation({
    String? productId,
    String? temporaryProductId,
    String? supplierId,
    required int existingQuantity,
    int? requestedQuantity,
    required MeasurementUnit measurementUnit,
    Product? product,
    TemporaryProduct? temporaryProduct,
    Supplier? supplier,
  }) {
    return OrderItemModel(
      id: '', // Will be set by backend
      orderId: '', // Will be set by backend
      productId: productId,
      temporaryProductId: temporaryProductId,
      supplierId: supplierId,
      product: product,
      temporaryProduct: temporaryProduct,
      supplier: supplier,
      existingQuantity: existingQuantity,
      requestedQuantity: requestedQuantity,
      measurementUnit: measurementUnit,
    );
  }

  /// Convert to quantity update format
  Map<String, dynamic> toQuantityUpdateJson() {
    return {
      'id': id,
      'requestedQuantity': requestedQuantity ?? 0,
    };
  }
}