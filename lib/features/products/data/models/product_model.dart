//lib/features/products/data/models/product_model.dart

import '../../domain/entities/product.dart';

/// Product model for data layer that extends Product entity
/// Handles JSON serialization/deserialization matching backend structure
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.description,
    required super.barcode,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.precioA,
    super.precioB,
    super.precioC,
    super.costo,
    required super.iva,
  });

  /// Create ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      // DEBUG: Log the JSON response to see exactly what the backend is sending
      print('🔍 ProductModel.fromJson called with JSON: $json');
      print('🔍 IVA field in JSON: ${json['iva']}');
      print('🔍 IVA field type: ${json['iva'].runtimeType}');
      print('🔍 Parsed IVA: ${_parseDouble(json['iva'])}');

      final parsedIva = _parseDouble(json['iva']);
      print('🔍 Final IVA value: $parsedIva');

      return ProductModel(
        id: json['id'] as String,
        description: json['description'] as String? ?? '',
        barcode: json['barcode'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        precioA: _parseDouble(json['precioA']) ?? 0.0,
        precioB: _parseDouble(json['precioB']),
        precioC: _parseDouble(json['precioC']),
        costo: _parseDouble(json['costo']),
        iva:
            parsedIva ??
            (throw FormatException(
              'IVA is required in JSON response. Backend must always return IVA field. JSON: $json',
            )),
      );
    } catch (e) {
      throw FormatException('Error parsing ProductModel from JSON: $e', json);
    }
  }

  /// Convert ProductModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'barcode': barcode,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'precioA': precioA,
      'precioB': precioB,
      'precioC': precioC,
      'costo': costo,
      'iva': iva,
    };
  }

  /// Convert ProductModel to Product entity
  Product toEntity() {
    return Product(
      id: id,
      description: description,
      barcode: barcode,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      precioA: precioA,
      precioB: precioB,
      precioC: precioC,
      costo: costo,
      iva: iva,
    );
  }

  /// Create ProductModel from Product entity
  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      description: product.description,
      barcode: product.barcode,
      isActive: product.isActive,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      precioA: product.precioA,
      precioB: product.precioB,
      precioC: product.precioC,
      costo: product.costo,
      iva: product.iva,
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now();
    }

    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        // Try parsing ISO format with timezone
        try {
          return DateTime.parse(dateTime).toLocal();
        } catch (e2) {
          // Fallback to current time if parsing fails
          return DateTime.now();
        }
      }
    }

    if (dateTime is DateTime) {
      return dateTime;
    }

    if (dateTime is int) {
      // Assume Unix timestamp in milliseconds
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    }

    // Fallback to current time
    return DateTime.now();
  }

  /// Helper method to parse double from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Create a copy with updated values
  @override
  ProductModel copyWith({
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
    return ProductModel(
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

  @override
  String toString() {
    return 'ProductModel(id: $id, description: $description, barcode: $barcode, isActive: $isActive, precioA: $precioA, precioB: $precioB, precioC: $precioC, costo: $costo, iva: $iva, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Create empty ProductModel for testing or initial state
  factory ProductModel.empty() {
    final now = DateTime.now();
    return ProductModel(
      id: '',
      description: '',
      barcode: '',
      isActive: true,
      createdAt: now,
      updatedAt: now,
      precioA: 0.0,
      precioB: null,
      precioC: null,
      costo: null,
      iva: 0.0,
    );
  }

  /// Validate if the ProductModel has valid data
  bool get isValid {
    return id.isNotEmpty &&
        description.isNotEmpty &&
        barcode.isNotEmpty &&
        precioA > 0;
  }
}
