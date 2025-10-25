import '../../domain/entities/supplier.dart';

/// Supplier model for data layer that extends Supplier entity
/// Handles JSON serialization/deserialization matching backend structure
class SupplierModel extends Supplier {
  const SupplierModel({
    required super.id,
    required super.nombre,
    super.celular,
    super.email,
    super.direccion,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create SupplierModel from JSON
  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    try {
      return SupplierModel(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        celular: json['celular'] as String?,
        email: json['email'] as String?,
        direccion: json['direccion'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      throw FormatException('Error parsing SupplierModel from JSON: $e', json);
    }
  }

  /// Convert SupplierModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'celular': celular,
      'email': email,
      'direccion': direccion,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert SupplierModel to Supplier entity
  Supplier toEntity() {
    return Supplier(
      id: id,
      nombre: nombre,
      celular: celular,
      email: email,
      direccion: direccion,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create SupplierModel from Supplier entity
  factory SupplierModel.fromEntity(Supplier supplier) {
    return SupplierModel(
      id: supplier.id,
      nombre: supplier.nombre,
      celular: supplier.celular,
      email: supplier.email,
      direccion: supplier.direccion,
      isActive: supplier.isActive,
      createdAt: supplier.createdAt,
      updatedAt: supplier.updatedAt,
    );
  }

  /// Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'SupplierModel(id: $id, nombre: $nombre, celular: $celular, email: $email, direccion: $direccion, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Create a copy of SupplierModel with updated fields
  SupplierModel copyWith({
    String? id,
    String? nombre,
    String? celular,
    String? email,
    String? direccion,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      celular: celular ?? this.celular,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
