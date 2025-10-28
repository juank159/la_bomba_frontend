// lib/features/credits/data/models/payment_method_model.dart

import '../../domain/entities/payment_method.dart';

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.name,
    super.description,
    super.icon,
    required super.isActive,
    required super.createdBy,
    super.updatedBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdBy: json['createdBy'] as String? ?? json['created_by'] as String? ?? 'system',
      updatedBy: json['updatedBy'] as String? ?? json['updated_by'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isActive': isActive,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PaymentMethod toEntity() {
    return PaymentMethod(
      id: id,
      name: name,
      description: description,
      icon: icon,
      isActive: isActive,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory PaymentMethodModel.fromEntity(PaymentMethod entity) {
    return PaymentMethodModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      icon: entity.icon,
      isActive: entity.isActive,
      createdBy: entity.createdBy,
      updatedBy: entity.updatedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
