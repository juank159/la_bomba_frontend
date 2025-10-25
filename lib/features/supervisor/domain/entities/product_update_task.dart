import 'package:equatable/equatable.dart';
import '../../../products/domain/entities/product.dart';
import '../../../auth/domain/entities/user.dart';

/// Task status enumeration
enum TaskStatus {
  pending,
  completed,
  expired;

  /// Convert string to TaskStatus
  static TaskStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TaskStatus.pending;
      case 'completed':
        return TaskStatus.completed;
      case 'expired':
        return TaskStatus.expired;
      default:
        throw ArgumentError('Invalid task status: $status');
    }
  }

  /// Convert TaskStatus to string
  String get value {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.expired:
        return 'expired';
    }
  }

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.completed:
        return 'Completado';
      case TaskStatus.expired:
        return 'Expirado';
    }
  }

  /// Get color for status
  String get color {
    switch (this) {
      case TaskStatus.pending:
        return 'orange';
      case TaskStatus.completed:
        return 'green';
      case TaskStatus.expired:
        return 'red';
    }
  }
}

/// Change type enumeration
enum ChangeType {
  price,
  info,
  inventory,
  arrival;

  /// Convert string to ChangeType
  static ChangeType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'price':
        return ChangeType.price;
      case 'info':
        return ChangeType.info;
      case 'inventory':
        return ChangeType.inventory;
      case 'arrival':
        return ChangeType.arrival;
      default:
        throw ArgumentError('Invalid change type: $type');
    }
  }

  /// Convert ChangeType to string
  String get value {
    switch (this) {
      case ChangeType.price:
        return 'price';
      case ChangeType.info:
        return 'info';
      case ChangeType.inventory:
        return 'inventory';
      case ChangeType.arrival:
        return 'arrival';
    }
  }

  /// Get display name for the type
  String get displayName {
    switch (this) {
      case ChangeType.price:
        return 'Precio';
      case ChangeType.info:
        return 'Información';
      case ChangeType.inventory:
        return 'Inventario';
      case ChangeType.arrival:
        return 'Llegada de Producto';
    }
  }

  /// Get icon for change type
  String get icon {
    switch (this) {
      case ChangeType.price:
        return 'monetization_on';
      case ChangeType.info:
        return 'info';
      case ChangeType.inventory:
        return 'inventory';
      case ChangeType.arrival:
        return 'local_shipping';
    }
  }
}

/// Product Update Task entity
class ProductUpdateTask extends Equatable {
  final String id;
  final Product product;
  final String productId;
  final ChangeType changeType;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final TaskStatus status;
  final String? description;
  final User createdBy;
  final String createdById;
  final User? completedBy;
  final String? completedById;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? notes;

  const ProductUpdateTask({
    required this.id,
    required this.product,
    required this.productId,
    required this.changeType,
    this.oldValue,
    this.newValue,
    required this.status,
    this.description,
    required this.createdBy,
    required this.createdById,
    this.completedBy,
    this.completedById,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        product,
        productId,
        changeType,
        oldValue,
        newValue,
        status,
        description,
        createdBy,
        createdById,
        completedBy,
        completedById,
        createdAt,
        updatedAt,
        completedAt,
        notes,
      ];

  /// Copy with method for creating modified instances
  ProductUpdateTask copyWith({
    String? id,
    Product? product,
    String? productId,
    ChangeType? changeType,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    TaskStatus? status,
    String? description,
    User? createdBy,
    String? createdById,
    User? completedBy,
    String? completedById,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return ProductUpdateTask(
      id: id ?? this.id,
      product: product ?? this.product,
      productId: productId ?? this.productId,
      changeType: changeType ?? this.changeType,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      status: status ?? this.status,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      completedBy: completedBy ?? this.completedBy,
      completedById: completedById ?? this.completedById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Check if task is pending
  bool get isPending => status == TaskStatus.pending;

  /// Check if task is completed
  bool get isCompleted => status == TaskStatus.completed;

  /// Check if task is expired
  bool get isExpired => status == TaskStatus.expired;

  /// Get time since creation
  Duration get timeSinceCreation => DateTime.now().difference(createdAt);

  /// Get formatted time since creation
  String get formattedTimeSinceCreation {
    final duration = timeSinceCreation;
    if (duration.inDays > 0) {
      return 'hace ${duration.inDays} día${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return 'hace ${duration.inHours} hora${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return 'hace ${duration.inMinutes} minuto${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace unos segundos';
    }
  }

  /// Get formatted old values for display (only changed fields)
  String get formattedOldValues {
    if (oldValue == null || oldValue!.isEmpty) return 'Sin valor anterior';

    final buffer = StringBuffer();
    final changedKeys = _getChangedKeys();

    changedKeys.forEach((key) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write('${_getPriceDisplayName(key)}: ${_formatPrice(oldValue![key])}');
    });

    return buffer.isEmpty ? 'Sin cambios' : buffer.toString();
  }

  /// Get formatted new values for display (only changed fields)
  String get formattedNewValues {
    if (newValue == null || newValue!.isEmpty) return 'Sin valor nuevo';

    final buffer = StringBuffer();
    final changedKeys = _getChangedKeys();

    changedKeys.forEach((key) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write('${_getPriceDisplayName(key)}: ${_formatPrice(newValue![key])}');
    });

    return buffer.isEmpty ? 'Sin cambios' : buffer.toString();
  }

  /// Get list of keys that have changed values (excluding iva)
  List<String> _getChangedKeys() {
    if (oldValue == null || newValue == null) return [];

    final changedKeys = <String>[];

    // Comparar todos los campos excepto iva
    newValue!.forEach((key, newVal) {
      // Siempre incluir iva
      if (key == 'iva') {
        changedKeys.add(key);
        return;
      }

      // Para otros campos, solo incluir si cambiaron
      if (oldValue!.containsKey(key)) {
        final oldVal = oldValue![key];
        if (_valuesAreDifferent(oldVal, newVal)) {
          changedKeys.add(key);
        }
      } else if (newVal != null) {
        // Campo nuevo que no existía antes
        changedKeys.add(key);
      }
    });

    return changedKeys;
  }

  /// Check if two values are different
  bool _valuesAreDifferent(dynamic oldVal, dynamic newVal) {
    if (oldVal == null && newVal == null) return false;
    if (oldVal == null || newVal == null) return true;

    // Convertir a string para comparar
    final oldStr = oldVal.toString();
    final newStr = newVal.toString();

    // Para números, comparar como double
    final oldNum = double.tryParse(oldStr);
    final newNum = double.tryParse(newStr);

    if (oldNum != null && newNum != null) {
      return (oldNum - newNum).abs() > 0.01; // Tolerancia para decimales
    }

    return oldStr != newStr;
  }

  /// Get display name for price field
  String _getPriceDisplayName(String fieldName) {
    switch (fieldName) {
      case 'precioA':
        return 'Público';
      case 'precioB':
        return 'Mayor';
      case 'precioC':
        return 'Super';
      default:
        return fieldName;
    }
  }

  /// Format price value for display
  String _formatPrice(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return '\$${parsed.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
      }
      return value;
    }
    if (value is num) {
      return '\$${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return value.toString();
  }

  /// Get formatted description for display
  String get formattedDescription {
    if (description == null || description!.isEmpty) return 'Sin descripción';
    
    String formatted = description!;
    
    // Reemplazar nombres técnicos con nombres amigables
    formatted = formatted.replaceAll('precioA', 'Público');
    formatted = formatted.replaceAll('precioB', 'Mayor');  
    formatted = formatted.replaceAll('precioC', 'Super');
    
    return formatted;
  }

  @override
  String toString() {
    return 'ProductUpdateTask(id: $id, productId: $productId, status: $status, changeType: $changeType)';
  }
}