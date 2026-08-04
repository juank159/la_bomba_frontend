import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../credits/data/models/payment_method_model.dart';
import 'invoice_item_model.dart';

/// Invoice model for data layer that extends Invoice entity
/// Handles JSON serialization/deserialization matching backend structure
class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.id,
    required super.number,
    super.clientId,
    super.client,
    required super.paymentMethodId,
    super.paymentMethod,
    required super.subtotal,
    required super.tax,
    required super.total,
    required super.status,
    required super.createdBy,
    super.cancelledBy,
    super.cancelledAt,
    required super.items,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create InvoiceModel from JSON
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    try {
      return InvoiceModel(
        id: json['id'] as String,
        number: _parseInt(json['number']) ?? 0,
        clientId: json['clientId'] as String?,
        client: json['client'] != null
            ? ClientModel.fromJson(json['client'] as Map<String, dynamic>)
                .toEntity()
            : null,
        paymentMethodId: json['paymentMethodId'] as String? ?? '',
        paymentMethod: json['paymentMethod'] != null
            ? PaymentMethodModel.fromJson(
                json['paymentMethod'] as Map<String, dynamic>,
              ).toEntity()
            : null,
        subtotal: _parseDouble(json['subtotal']) ?? 0.0,
        tax: _parseDouble(json['tax']) ?? 0.0,
        total: _parseDouble(json['total']) ?? 0.0,
        status: InvoiceStatus.fromString(json['status'] as String? ?? 'completed'),
        createdBy: json['createdBy'] as String? ?? '',
        cancelledBy: json['cancelledBy'] as String?,
        cancelledAt: _parseNullableDateTime(json['cancelledAt']),
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => InvoiceItemModel.fromJson(item as Map<String, dynamic>)
                    .toEntity())
                .toList() ??
            [],
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
      );
    } catch (e) {
      throw FormatException('Error parsing InvoiceModel from JSON: $e', json);
    }
  }

  /// Convert for invoice creation
  Map<String, dynamic> toCreateJson() {
    return {
      if (clientId != null && clientId!.isNotEmpty) 'clientId': clientId,
      'paymentMethodId': paymentMethodId,
      'items': items
          .map((item) => InvoiceItemModel.fromEntity(item).toCreateJson())
          .toList(),
    };
  }

  /// Convert InvoiceModel to Invoice entity
  Invoice toEntity() {
    return Invoice(
      id: id,
      number: number,
      clientId: clientId,
      client: client,
      paymentMethodId: paymentMethodId,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      tax: tax,
      total: total,
      status: status,
      createdBy: createdBy,
      cancelledBy: cancelledBy,
      cancelledAt: cancelledAt,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create InvoiceModel for new invoice creation (without id/number)
  factory InvoiceModel.forCreation({
    String? clientId,
    required String paymentMethodId,
    required List<InvoiceItem> items,
  }) {
    final now = DateTime.now();
    return InvoiceModel(
      id: '',
      number: 0,
      clientId: clientId,
      paymentMethodId: paymentMethodId,
      subtotal: 0,
      tax: 0,
      total: 0,
      status: InvoiceStatus.completed,
      createdBy: '',
      items: items,
      createdAt: now,
      updatedAt: now,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    return _parseDateTime(dateTime);
  }

  @override
  String toString() {
    return 'InvoiceModel(id: $id, number: $number, total: $total, status: ${status.value}, items: ${items.length})';
  }
}
