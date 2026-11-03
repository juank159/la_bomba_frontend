// lib/features/breb/domain/breb_payment_info.dart

/// Datos del pago Bre-B con el que se cobró una venta o factura: quién pagó
/// (nombre del cliente según el banco), por qué banco/llave entró, con qué
/// referencia y cuánto llegó realmente. `null` en ventas que no son Bre-B.
class BrebPaymentInfo {
  final String? payerName;
  final String? bankLabel;
  final String? llave;
  final String? reference;
  final double? amountReceived;

  const BrebPaymentInfo({
    this.payerName,
    this.bankLabel,
    this.llave,
    this.reference,
    this.amountReceived,
  });

  /// Lee los campos `breb*` que el backend agrega a la venta/factura.
  /// Devuelve `null` si la venta no se cobró con Bre-B.
  static BrebPaymentInfo? fromSaleJson(Map<String, dynamic> json) {
    if (json['brebChargeId'] == null) return null;
    final received = json['brebAmountReceived'];
    return BrebPaymentInfo(
      payerName: json['brebPayerName'] as String?,
      bankLabel: json['brebBankLabel'] as String?,
      llave: json['brebLlave'] as String?,
      reference: json['brebReference'] as String?,
      amountReceived: received == null ? null : double.tryParse(received.toString()),
    );
  }

  /// "Nequi · @labomba" — para mostrar debajo del método de pago.
  String get originLabel => [bankLabel, llave].where((v) => v != null && v.isNotEmpty).join(' · ');
}
