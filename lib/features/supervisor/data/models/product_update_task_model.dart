import '../../domain/entities/product_update_task.dart';
import '../../../products/data/models/product_model.dart';
import '../../../auth/data/models/user_model.dart';

/// Data model for ProductUpdateTask
class ProductUpdateTaskModel extends ProductUpdateTask {
  const ProductUpdateTaskModel({
    required super.id,
    required super.product,
    required super.productId,
    required super.changeType,
    super.oldValue,
    super.newValue,
    required super.status,
    super.description,
    required super.createdBy,
    required super.createdById,
    super.completedBy,
    super.completedById,
    required super.createdAt,
    required super.updatedAt,
    super.completedAt,
    super.notes,
  });

  /// Factory constructor from JSON
  factory ProductUpdateTaskModel.fromJson(Map<String, dynamic> json) {
    return ProductUpdateTaskModel(
      id: json['id'] as String,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      productId: json['productId'] as String,
      changeType: ChangeType.fromString(json['changeType'] as String),
      oldValue: json['oldValue'] != null
          ? json['oldValue'] as Map<String, dynamic>
          : null,
      newValue: json['newValue'] != null
          ? json['newValue'] as Map<String, dynamic>
          : null,
      status: TaskStatus.fromString(json['status'] as String),
      description: json['description'] as String?,
      createdBy: UserModel.fromJson(json['createdBy'] as Map<String, dynamic>),
      createdById: json['createdById'] as String,
      completedBy: json['completedBy'] != null
          ? UserModel.fromJson(json['completedBy'] as Map<String, dynamic>)
          : null,
      completedById: json['completedById'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': (product as ProductModel).toJson(),
      'productId': productId,
      'changeType': changeType.value,
      'oldValue': oldValue,
      'newValue': newValue,
      'status': status.value,
      'description': description,
      'createdBy': (createdBy as UserModel).toJson(),
      'createdById': createdById,
      'completedBy': completedBy != null ? (completedBy! as UserModel).toJson() : null,
      'completedById': completedById,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Create model from domain entity
  factory ProductUpdateTaskModel.fromEntity(ProductUpdateTask entity) {
    return ProductUpdateTaskModel(
      id: entity.id,
      product: entity.product,
      productId: entity.productId,
      changeType: entity.changeType,
      oldValue: entity.oldValue,
      newValue: entity.newValue,
      status: entity.status,
      description: entity.description,
      createdBy: entity.createdBy,
      createdById: entity.createdById,
      completedBy: entity.completedBy,
      completedById: entity.completedById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      completedAt: entity.completedAt,
      notes: entity.notes,
    );
  }
}

/// Task statistics model
class TaskStatsModel {
  final int pendingCount;
  final int completedCount;
  final int totalCount;

  const TaskStatsModel({
    required this.pendingCount,
    required this.completedCount,
    required this.totalCount,
  });

  factory TaskStatsModel.fromJson(Map<String, dynamic> json) {
    return TaskStatsModel(
      pendingCount: (json['pendingCount'] as int?) ?? 0,
      completedCount: (json['completedCount'] as int?) ?? 0,
      totalCount: (json['totalCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendingCount': pendingCount,
      'completedCount': completedCount,
      'totalCount': totalCount,
    };
  }
}