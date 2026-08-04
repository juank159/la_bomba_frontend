import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';

enum TemporaryProductStatus {
  pendingAdmin,
  pendingSupervisor,
  completed,
  cancelled,
}

extension TemporaryProductStatusExtension on TemporaryProductStatus {
  String get value {
    switch (this) {
      case TemporaryProductStatus.pendingAdmin:
        return 'pending_admin';
      case TemporaryProductStatus.pendingSupervisor:
        return 'pending_supervisor';
      case TemporaryProductStatus.completed:
        return 'completed';
      case TemporaryProductStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case TemporaryProductStatus.pendingAdmin:
        return 'Pendiente Admin';
      case TemporaryProductStatus.pendingSupervisor:
        return 'Pendiente Supervisor';
      case TemporaryProductStatus.completed:
        return 'Completado';
      case TemporaryProductStatus.cancelled:
        return 'Cancelado';
    }
  }

  static TemporaryProductStatus fromString(String status) {
    switch (status) {
      case 'pending_admin':
        return TemporaryProductStatus.pendingAdmin;
      case 'pending_supervisor':
        return TemporaryProductStatus.pendingSupervisor;
      case 'completed':
        return TemporaryProductStatus.completed;
      case 'cancelled':
        return TemporaryProductStatus.cancelled;
      default:
        throw ArgumentError('Unknown status: $status');
    }
  }
}

class TemporaryProduct extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? barcode;
  final bool isActive;
  final double? precioA;
  final double? precioB;
  final double? precioC;
  final double? costo;
  final double? iva;
  final String? notes;
  final String? productId;
  final TemporaryProductStatus status;
  final String createdBy;
  final String? completedByAdmin;
  final User? completedByAdminUser;
  final DateTime? completedByAdminAt;
  final String? completedBySupervisor;
  final User? completedBySupervisorUser;
  final DateTime? completedBySupervisorAt;
  final String? completedByDigitador;
  final User? completedByDigitadorUser;
  final DateTime? completedByDigitadorAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemporaryProduct({
    required this.id,
    required this.name,
    this.description,
    this.barcode,
    required this.isActive,
    this.precioA,
    this.precioB,
    this.precioC,
    this.costo,
    this.iva,
    this.notes,
    this.productId,
    required this.status,
    required this.createdBy,
    this.completedByAdmin,
    this.completedByAdminUser,
    this.completedByAdminAt,
    this.completedBySupervisor,
    this.completedBySupervisorUser,
    this.completedBySupervisorAt,
    this.completedByDigitador,
    this.completedByDigitadorUser,
    this.completedByDigitadorAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPendingAdmin => status == TemporaryProductStatus.pendingAdmin;
  bool get isPendingSupervisor => status == TemporaryProductStatus.pendingSupervisor;
  bool get isCompleted => status == TemporaryProductStatus.completed;
  bool get isCancelled => status == TemporaryProductStatus.cancelled;

  /// Supervisor y digitador confirman por separado: que uno complete no
  /// completa la tarea del otro. Usa estos getters (en vez de [isCompleted],
  /// que solo es true cuando AMBOS confirmaron) para saber si un rol
  /// específico ya hizo su parte.
  bool get isCompletedBySupervisor => completedBySupervisor != null;
  bool get isCompletedByDigitador => completedByDigitador != null;

  /// Pendiente para supervisor: sigue en el flujo de revisión (no cancelado,
  /// no completado por ambos) y supervisor todavía no confirmó su parte.
  /// Nota: productos ya completados antes de esta versión (sin el campo
  /// completedByDigitador) tienen status=completed y NO deben reaparecer
  /// como pendientes solo porque ese campo histórico esté vacío.
  bool get isPendingForSupervisor => isPendingSupervisor && !isCompletedBySupervisor;

  /// Pendiente para digitador: mismo criterio que [isPendingForSupervisor].
  bool get isPendingForDigitador => isPendingSupervisor && !isCompletedByDigitador;

  bool get hasAllRequiredFields => precioA != null && iva != null;

  String get formattedTimeSinceCreation {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace unos segundos';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        barcode,
        isActive,
        precioA,
        precioB,
        precioC,
        costo,
        iva,
        notes,
        productId,
        status,
        createdBy,
        completedByAdmin,
        completedByAdminUser,
        completedByAdminAt,
        completedBySupervisor,
        completedBySupervisorUser,
        completedBySupervisorAt,
        completedByDigitador,
        completedByDigitadorUser,
        completedByDigitadorAt,
        createdAt,
        updatedAt,
      ];
}
