import 'package:equatable/equatable.dart';
import 'order_item.dart';
import 'user.dart';

/// Order status enum matching backend
enum OrderStatus {
  pending('pending'),
  completed('completed');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'completed':
        return OrderStatus.completed;
      default:
        return OrderStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.completed:
        return 'Completado';
    }
  }
}

/// Order entity representing an order in the domain layer
/// Matches the backend Order entity structure
class Order extends Equatable {
  final String id;
  final String description;
  final String? provider;
  final OrderStatus status;
  final String createdById;
  final User? createdBy;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.description,
    this.provider,
    required this.status,
    required this.createdById,
    this.createdBy,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    description,
    provider,
    status,
    createdById,
    createdBy,
    items,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Order(id: $id, description: $description, provider: $provider, status: $status, createdById: $createdById, items: ${items.length}, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Copy with method for creating modified instances
  Order copyWith({
    String? id,
    String? description,
    String? provider,
    OrderStatus? status,
    String? createdById,
    User? createdBy,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
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

  /// Get total number of items in the order
  int get totalItems => items.length;

  /// Get total requested quantity across all items
  int get totalRequestedQuantity {
    return items.fold(0, (sum, item) => sum + (item.requestedQuantity ?? 0));
  }

  /// Get total existing quantity across all items
  int get totalExistingQuantity {
    return items.fold(0, (sum, item) => sum + item.existingQuantity);
  }

  /// Check if the order has a provider
  bool get hasProvider => provider != null && provider!.trim().isNotEmpty;

  /// Get formatted status text
  String get statusText => status.displayName;

  /// Check if the order is pending
  bool get isPending => status == OrderStatus.pending;

  /// Check if the order is completed
  bool get isCompleted => status == OrderStatus.completed;

  /// Get display-friendly created date
  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get display-friendly created date and time with AM/PM
  String get formattedCreatedAtWithTime {
    // Convert to local timezone
    final localTime = createdAt.toLocal();

    // Get hour in 12-hour format
    int hour = localTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12; // Midnight
    } else if (hour > 12) {
      hour = hour - 12;
    }

    return '${localTime.day}/${localTime.month}/${localTime.year} ${hour.toString()}:${localTime.minute.toString().padLeft(2, '0')} $period';
  }
}