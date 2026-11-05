import 'package:equatable/equatable.dart';
import 'vegetable_sale_item.dart';
import '../../../breb/domain/breb_payment_info.dart';
import '../../../breb/domain/payment_part.dart';

/// A completed sale from the vegetables (verduras) module. Independent from
/// Invoice: produce has no IVA and is managed by its own role (verdulero).
class VegetableSale extends Equatable {
  final String id;
  final int number;
  final double total;
  final String soldBy;
  final String paymentMethodId;
  final String paymentMethodName;
  final List<VegetableSaleItem> items;
  final DateTime createdAt;
  final bool isActive;
  /// Datos del pago si se cobró con Bre-B (pagador, banco, llave).
  final BrebPaymentInfo? breb;
  /// Partes del pago (mixto: ej. Bre-B $20.000 + Efectivo $30.000).
  final List<PaymentPart> payments;

  const VegetableSale({
    required this.id,
    required this.number,
    required this.total,
    required this.soldBy,
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.items,
    required this.createdAt,
    this.isActive = true,
    this.breb,
    this.payments = const [],
  });

  @override
  List<Object?> get props =>
      [id, number, total, soldBy, paymentMethodId, paymentMethodName, items, createdAt, isActive, breb, payments];

  VegetableSale copyWith({bool? isActive}) {
    return VegetableSale(
      id: id,
      number: number,
      total: total,
      soldBy: soldBy,
      paymentMethodId: paymentMethodId,
      paymentMethodName: paymentMethodName,
      items: items,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      breb: breb,
      payments: payments,
    );
  }

  /// "Efectivo", o en un pago mixto "Bre-B $20.000 + Efectivo $30.000".
  String get paymentLabel => payments.isSplit ? payments.summary : paymentMethodName;

  /// "Efectivo", o en un pago mixto "Bre-B + Efectivo".
  String get paymentShortLabel => payments.isSplit ? payments.names : paymentMethodName;

  /// Formatted sale number with leading zeros (e.g. #000042)
  String get formattedNumber => '#${number.toString().padLeft(6, '0')}';

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
