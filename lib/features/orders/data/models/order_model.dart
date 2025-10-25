import '../../domain/entities/order.dart' as order_entity;
import '../../domain/entities/order_item.dart';
import '../../domain/entities/user.dart';
import 'order_item_model.dart';
import 'user_model.dart';

/// Order model for data layer that extends order_entity.Order entity
/// Handles JSON serialization/deserialization matching backend structure
class OrderModel extends order_entity.Order {
  const OrderModel({
    required super.id,
    required super.description,
    super.provider,
    required super.status,
    required super.createdById,
    super.createdBy,
    required super.items,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create OrderModel from JSON
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    try {
      return OrderModel(
        id: json['id'] as String,
        description: json['description'] as String? ?? '',
        provider: json['provider'] as String?,
        status: order_entity.OrderStatus.fromString(json['status'] as String? ?? 'pending'),
        createdById: json['createdById'] as String,
        createdBy: json['createdBy'] != null 
          ? UserModel.fromJson(json['createdBy'] as Map<String, dynamic>).toEntity()
          : null,
        items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>).toEntity())
          .toList() ?? [],
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      throw FormatException('Error parsing OrderModel from JSON: $e', json);
    }
  }

  /// Convert OrderModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'provider': provider,
      'status': status.value,
      'createdById': createdById,
      'createdBy': createdBy != null ? UserModel.fromEntity(createdBy!).toJson() : null,
      'items': items.map((item) => OrderItemModel.fromEntity(item).toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert for order creation
  Map<String, dynamic> toCreateJson() {
    return {
      'description': description,
      'provider': provider,
      'items': items.map((item) => OrderItemModel.fromEntity(item).toCreateJson()).toList(),
    };
  }

  /// Convert OrderModel to Order entity
  order_entity.Order toEntity() {
    return order_entity.Order(
      id: id,
      description: description,
      provider: provider,
      status: status,
      createdById: createdById,
      createdBy: createdBy,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create OrderModel from Order entity
  factory OrderModel.fromEntity(order_entity.Order order) {
    return OrderModel(
      id: order.id,
      description: order.description,
      provider: order.provider,
      status: order.status,
      createdById: order.createdById,
      createdBy: order.createdBy,
      items: order.items,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
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

  /// Create a copy with updated values
  @override
  OrderModel copyWith({
    String? id,
    String? description,
    String? provider,
    order_entity.OrderStatus? status,
    String? createdById,
    User? createdBy,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      description: description ?? this.description,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, description: $description, provider: $provider, status: ${status.value}, createdById: $createdById, items: ${items.length}, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Create empty OrderModel for testing or initial state
  factory OrderModel.empty() {
    final now = DateTime.now();
    return OrderModel(
      id: '',
      description: '',
      provider: null,
      status: order_entity.OrderStatus.pending,
      createdById: '',
      createdBy: null,
      items: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Validate if the OrderModel has valid data
  bool get isValid {
    return id.isNotEmpty &&
           description.isNotEmpty &&
           createdById.isNotEmpty;
  }

  /// Create OrderModel for new order creation (without id)
  factory OrderModel.forCreation({
    required String description,
    String? provider,
    required List<OrderItem> items,
    required String createdById,
  }) {
    final now = DateTime.now();
    return OrderModel(
      id: '', // Will be set by backend
      description: description,
      provider: provider,
      status: order_entity.OrderStatus.pending,
      createdById: createdById,
      createdBy: null,
      items: items,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert to update format
  Map<String, dynamic> toUpdateJson({
    String? newDescription,
    String? newProvider,
    String? newStatus,
  }) {
    final Map<String, dynamic> updateData = {};
    
    if (newDescription != null) {
      updateData['description'] = newDescription;
    }
    
    if (newProvider != null) {
      updateData['provider'] = newProvider;
    }
    
    if (newStatus != null) {
      updateData['status'] = newStatus;
    }
    
    return updateData;
  }
}