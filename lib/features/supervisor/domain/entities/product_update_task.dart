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
  info, // legado: cambios genéricos. Tareas nuevas usan los tipos granulares
  inventory,
  arrival,
  name,
  iva,
  barcode,
  description;

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
      case 'name':
        return ChangeType.name;
      case 'iva':
        return ChangeType.iva;
      case 'barcode':
        return ChangeType.barcode;
      case 'description':
        return ChangeType.description;
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
      case ChangeType.name:
        return 'name';
      case ChangeType.iva:
        return 'iva';
      case ChangeType.barcode:
        return 'barcode';
      case ChangeType.description:
        return 'description';
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
      case ChangeType.name:
        return 'Nombre';
      case ChangeType.iva:
        return 'IVA';
      case ChangeType.barcode:
        return 'Código de Barras';
      case ChangeType.description:
        return 'Descripción';
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
      case ChangeType.name:
        return 'badge';
      case ChangeType.iva:
        return 'percent';
      case ChangeType.barcode:
        return 'qr_code';
      case ChangeType.description:
        return 'description';
    }
  }
}

/// Rol al que se asigna una tarea (subset de UserRole: solo roles que reciben tareas)
enum AssignedRole {
  supervisor,
  digitador;

  static AssignedRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'supervisor':
        return AssignedRole.supervisor;
      case 'digitador':
        return AssignedRole.digitador;
      default:
        return AssignedRole.supervisor; // legacy fallback
    }
  }

  String get value {
    switch (this) {
      case AssignedRole.supervisor:
        return 'supervisor';
      case AssignedRole.digitador:
        return 'digitador';
    }
  }

  String get displayName {
    switch (this) {
      case AssignedRole.supervisor:
        return 'Supervisor';
      case AssignedRole.digitador:
        return 'Digitador';
    }
  }
}

/// Product Update Task entity
class ProductUpdateTask extends Equatable {
  final String id;
  final Product product;
  final String productId;
  final ChangeType changeType;
  final AssignedRole assignedRole;
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
  final String? adminNotes;
  final String? notes;

  const ProductUpdateTask({
    required this.id,
    required this.product,
    required this.productId,
    required this.changeType,
    this.assignedRole = AssignedRole.supervisor,
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
    this.adminNotes,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        product,
        productId,
        changeType,
        assignedRole,
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
        adminNotes,
        notes,
      ];

  /// Copy with method for creating modified instances
  ProductUpdateTask copyWith({
    String? id,
    Product? product,
    String? productId,
    ChangeType? changeType,
    AssignedRole? assignedRole,
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
    String? adminNotes,
    String? notes,
  }) {
    return ProductUpdateTask(
      id: id ?? this.id,
      product: product ?? this.product,
      productId: productId ?? this.productId,
      changeType: changeType ?? this.changeType,
      assignedRole: assignedRole ?? this.assignedRole,
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
      adminNotes: adminNotes ?? this.adminNotes,
      notes: notes ?? this.notes,
    );
  }

  /// Check if task is pending
  bool get isPending => status == TaskStatus.pending;

  /// Check if task is completed
  bool get isCompleted => status == TaskStatus.completed;

  /// Check if task is expired
  bool get isExpired => status == TaskStatus.expired;

  /// True cuando la tarea agrupa varios cambios (típicamente del digitador):
  /// changeType=INFO con descripción que lista cambios separados por coma.
  bool get hasMultipleChanges =>
      changeType == ChangeType.info &&
      (description?.contains(',') ?? false);

  /// Label que se muestra en el chip de la card. Si la tarea agrupa varios
  /// cambios, mostramos "Edición múltiple" en vez del genérico "Información".
  String get chipLabel =>
      hasMultipleChanges ? 'Edición múltiple' : changeType.displayName;

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
    for (final change in changedFields) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write('${change.label}: ${change.oldDisplay}');
    }

    return buffer.isEmpty ? 'Sin cambios' : buffer.toString();
  }

  /// Get formatted new values for display (only changed fields)
  String get formattedNewValues {
    if (newValue == null || newValue!.isEmpty) return 'Sin valor nuevo';

    final buffer = StringBuffer();
    for (final change in changedFields) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write('${change.label}: ${change.newDisplay}');
    }

    return buffer.isEmpty ? 'Sin cambios' : buffer.toString();
  }

  /// Lista estructurada de cambios para renderizar en el detalle (label/antes/después).
  /// Solo incluye campos que cambiaron entre oldValue y newValue.
  List<FieldChange> get changedFields {
    if (newValue == null || newValue!.isEmpty) return const [];

    final List<FieldChange> result = [];

    // Orden estable de presentación, agrupado por sección.
    const fieldOrder = [
      'description', // Nombre del producto
      'iva',
      'barcode',
      'precioA',
      'precioB',
      'precioC',
      'costo',
    ];

    // Defensa en profundidad: aunque el backend mande un payload con campos
    // de otro rol (tareas viejas), filtramos para que cada rol solo vea sus
    // campos. Esto garantiza coherencia con la card y la notificación.
    final allowed = _allowedFieldsForRole(assignedRole);

    for (final key in fieldOrder) {
      if (!allowed.contains(key)) continue;
      if (!newValue!.containsKey(key)) continue;
      final oldVal = oldValue?[key];
      final newVal = newValue![key];
      if (!_valuesAreDifferent(oldVal, newVal)) continue;

      result.add(FieldChange(
        field: key,
        label: _fieldDisplayName(key),
        oldDisplay: _formatFieldValue(key, oldVal),
        newDisplay: _formatFieldValue(key, newVal),
      ));
    }

    return result;
  }

  /// Campos del producto que cada rol controla. Se usa para filtrar el detalle
  /// y NO mostrarle a un rol cambios que pertenecen al otro.
  static const _supervisorFields = {'precioA', 'precioB', 'precioC', 'costo'};
  static const _digitadorFields = {
    'description',
    'iva',
    'barcode',
    'precioA',
    'precioB',
    'precioC',
    'costo',
  };

  Set<String> _allowedFieldsForRole(AssignedRole role) {
    switch (role) {
      case AssignedRole.supervisor:
        return _supervisorFields;
      case AssignedRole.digitador:
        return _digitadorFields;
    }
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

  /// Display name legible para cualquier campo del producto
  String _fieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'description':
        return 'Nombre';
      case 'iva':
        return 'IVA';
      case 'barcode':
        return 'Código de barras';
      case 'precioA':
        return 'Precio Público';
      case 'precioB':
        return 'Precio Mayor';
      case 'precioC':
        return 'Precio Super';
      case 'costo':
        return 'Costo';
      default:
        return fieldName;
    }
  }

  /// Formatea el valor según el tipo de campo (precio con $, IVA con %, texto, etc)
  String _formatFieldValue(String fieldName, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) return '—';

    // Campos numéricos de precio/costo
    if (fieldName == 'precioA' ||
        fieldName == 'precioB' ||
        fieldName == 'precioC' ||
        fieldName == 'costo') {
      return _formatPrice(value);
    }

    // IVA con porcentaje
    if (fieldName == 'iva') {
      final n = value is num
          ? value.toDouble()
          : double.tryParse(value.toString()) ?? 0;
      // Si es entero, mostrar sin decimales
      final txt = n == n.truncateToDouble()
          ? n.toInt().toString()
          : n.toStringAsFixed(2);
      return '$txt%';
    }

    // Texto plano (description, barcode)
    return value.toString();
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

/// Un cambio de campo dentro de una tarea (para renderizar en el detalle)
class FieldChange {
  final String field; // clave técnica: 'description', 'iva', 'precioA', etc.
  final String label; // legible: 'Nombre', 'IVA', 'Precio Público'
  final String oldDisplay;
  final String newDisplay;

  const FieldChange({
    required this.field,
    required this.label,
    required this.oldDisplay,
    required this.newDisplay,
  });
}