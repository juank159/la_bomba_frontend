// lib/features/admin_tasks/data/models/temporary_product_model.dart

import '../../domain/entities/temporary_product.dart';
import '../../../auth/data/models/user_model.dart';

class TemporaryProductModel extends TemporaryProduct {
  const TemporaryProductModel({
    required super.id,
    required super.name,
    super.description,
    super.barcode,
    required super.isActive,
    super.precioA,
    super.precioB,
    super.precioC,
    super.costo,
    super.iva,
    super.notes,
    super.productId,
    required super.status,
    required super.createdBy,
    super.completedByAdmin,
    super.completedByAdminUser,
    super.completedByAdminAt,
    super.completedBySupervisor,
    super.completedBySupervisorUser,
    super.completedBySupervisorAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TemporaryProductModel.fromJson(Map<String, dynamic> json) {
    return TemporaryProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      barcode: json['barcode'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      precioA: json['precioA'] != null
          ? _parseDouble(json['precioA'])
          : null,
      precioB: json['precioB'] != null
          ? _parseDouble(json['precioB'])
          : null,
      precioC: json['precioC'] != null
          ? _parseDouble(json['precioC'])
          : null,
      costo: json['costo'] != null ? _parseDouble(json['costo']) : null,
      iva: json['iva'] != null ? _parseDouble(json['iva']) : null,
      notes: json['notes'] as String?,
      productId: json['productId'] as String?,
      status: TemporaryProductStatusExtension.fromString(
        json['status'] as String,
      ),
      createdBy: json['createdBy'] as String,
      completedByAdmin: json['completedByAdmin'] as String?,
      completedByAdminUser: json['completedByAdminUser'] != null
          ? UserModel.fromJson(json['completedByAdminUser'] as Map<String, dynamic>)
          : null,
      completedByAdminAt: json['completedByAdminAt'] != null
          ? DateTime.parse(json['completedByAdminAt'] as String)
          : null,
      completedBySupervisor: json['completedBySupervisor'] as String?,
      completedBySupervisorUser: json['completedBySupervisorUser'] != null
          ? UserModel.fromJson(json['completedBySupervisorUser'] as Map<String, dynamic>)
          : null,
      completedBySupervisorAt: json['completedBySupervisorAt'] != null
          ? DateTime.parse(json['completedBySupervisorAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Helper method to parse a value as double
  /// Handles both num and String types
  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.parse(value);
    }
    throw FormatException('Cannot parse $value as double');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'isActive': isActive,
      'precioa': precioA,
      'preciob': precioB,
      'precioc': precioC,
      'costo': costo,
      'iva': iva,
      'notes': notes,
      'productId': productId,
      'status': status.value,
      'created_by': createdBy,
      'completed_by_admin': completedByAdmin,
      'completed_by_admin_at': completedByAdminAt?.toIso8601String(),
      'completed_by_supervisor': completedBySupervisor,
      'completed_by_supervisor_at': completedBySupervisorAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TemporaryProduct toEntity() {
    return TemporaryProduct(
      id: id,
      name: name,
      description: description,
      barcode: barcode,
      isActive: isActive,
      precioA: precioA,
      precioB: precioB,
      precioC: precioC,
      costo: costo,
      iva: iva,
      notes: notes,
      productId: productId,
      status: status,
      createdBy: createdBy,
      completedByAdmin: completedByAdmin,
      completedByAdminUser: completedByAdminUser,
      completedByAdminAt: completedByAdminAt,
      completedBySupervisor: completedBySupervisor,
      completedBySupervisorUser: completedBySupervisorUser,
      completedBySupervisorAt: completedBySupervisorAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TemporaryProductModel.fromEntity(TemporaryProduct entity) {
    return TemporaryProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      barcode: entity.barcode,
      isActive: entity.isActive,
      precioA: entity.precioA,
      precioB: entity.precioB,
      precioC: entity.precioC,
      costo: entity.costo,
      iva: entity.iva,
      notes: entity.notes,
      productId: entity.productId,
      status: entity.status,
      createdBy: entity.createdBy,
      completedByAdmin: entity.completedByAdmin,
      completedByAdminUser: entity.completedByAdminUser,
      completedByAdminAt: entity.completedByAdminAt,
      completedBySupervisor: entity.completedBySupervisor,
      completedBySupervisorUser: entity.completedBySupervisorUser,
      completedBySupervisorAt: entity.completedBySupervisorAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
