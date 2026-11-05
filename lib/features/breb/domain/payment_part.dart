// lib/features/breb/domain/payment_part.dart

import '../../../app/core/utils/number_formatter.dart';

/// Una parte del pago de una venta/factura. Una cuenta de $50.000 pagada
/// mixta tiene dos: Bre-B $20.000 + Efectivo $30.000. Las ventas pagadas
/// con un solo método tienen una sola parte por el total.
class PaymentPart {
  final String paymentMethodId;
  final String name;
  final bool isCash;
  final bool isBreb;
  final double amount;

  const PaymentPart({
    required this.paymentMethodId,
    required this.name,
    required this.isCash,
    required this.isBreb,
    required this.amount,
  });

  /// Lee `payments` tal cual lo devuelve el backend (con `paymentMethod`
  /// anidado) o la versión plana del reporte de caja.
  factory PaymentPart.fromJson(Map<String, dynamic> json) {
    final pm = json['paymentMethod'] as Map<String, dynamic>?;
    return PaymentPart(
      paymentMethodId: (json['paymentMethodId'] ?? pm?['id'] ?? '') as String,
      name: (json['paymentMethodName'] ?? pm?['name'] ?? '') as String,
      isCash: (json['isCash'] ?? pm?['isCash'] ?? false) as bool,
      isBreb: (json['isBreb'] as bool?) ?? pm?['code'] == 'breb',
      amount: double.tryParse('${json['amount']}') ?? 0,
    );
  }

  static List<PaymentPart> listFromJson(dynamic raw) => raw is List
      ? raw.map((e) => PaymentPart.fromJson(Map<String, dynamic>.from(e as Map))).toList()
      : const [];

  /// "Bre-B $20.000"
  String get label => '$name ${NumberFormatter.formatCurrency(amount)}';
}

extension PaymentPartsX on List<PaymentPart> {
  /// Venta mixta: se pagó con más de un método.
  bool get isSplit => length > 1;

  /// "Bre-B $20.000 + Efectivo $30.000"
  String get summary => map((p) => p.label).join(' + ');

  /// "Bre-B + Efectivo" (sin montos, para listados).
  String get names => map((p) => p.name).join(' + ');
}

/// Cuánto se pagó por Bre-B. Ventas sin partes registradas: todo el total.
double brebPartOf(List<PaymentPart> payments, double total) {
  final breb = payments.where((p) => p.isBreb);
  return breb.isEmpty ? total : breb.fold(0.0, (a, p) => a + p.amount);
}
