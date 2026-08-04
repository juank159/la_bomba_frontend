import 'package:equatable/equatable.dart';
import 'invoice_item.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../credits/domain/entities/payment_method.dart';

/// Invoice status enum matching backend
enum InvoiceStatus {
  completed('completed'),
  cancelled('cancelled');

  const InvoiceStatus(this.value);
  final String value;

  static InvoiceStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return InvoiceStatus.completed;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.completed;
    }
  }

  String get displayName {
    switch (this) {
      case InvoiceStatus.completed:
        return 'Completada';
      case InvoiceStatus.cancelled:
        return 'Anulada';
    }
  }
}

/// Invoice entity representing a sales invoice in the domain layer
/// Matches the backend Invoice entity structure
class Invoice extends Equatable {
  final String id;
  final int number;
  final String? clientId;
  final Client? client;
  final String paymentMethodId;
  final PaymentMethod? paymentMethod;
  final double subtotal;
  final double tax;
  final double total;
  final InvoiceStatus status;
  final String createdBy;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final List<InvoiceItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.number,
    this.clientId,
    this.client,
    required this.paymentMethodId,
    this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    required this.createdBy,
    this.cancelledBy,
    this.cancelledAt,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    number,
    clientId,
    client,
    paymentMethodId,
    paymentMethod,
    subtotal,
    tax,
    total,
    status,
    createdBy,
    cancelledBy,
    cancelledAt,
    items,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Invoice(id: $id, number: $number, total: $total, status: ${status.value}, items: ${items.length})';
  }

  Invoice copyWith({
    String? id,
    int? number,
    String? clientId,
    Client? client,
    String? paymentMethodId,
    PaymentMethod? paymentMethod,
    double? subtotal,
    double? tax,
    double? total,
    InvoiceStatus? status,
    String? createdBy,
    String? cancelledBy,
    DateTime? cancelledAt,
    List<InvoiceItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      clientId: clientId ?? this.clientId,
      client: client ?? this.client,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Formatted invoice number with leading zeros (e.g. #000042)
  String get formattedNumber => '#${number.toString().padLeft(6, '0')}';

  bool get isCompleted => status == InvoiceStatus.completed;
  bool get isCancelled => status == InvoiceStatus.cancelled;

  bool get hasClient => client != null;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedCreatedAtWithTime {
    final localTime = createdAt.toLocal();
    int hour = localTime.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }
    return '${localTime.day}/${localTime.month}/${localTime.year} $hour:${localTime.minute.toString().padLeft(2, '0')} $period';
  }
}
