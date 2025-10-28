// lib/features/credits/domain/entities/refund_history.dart

/// Entidad que representa una devolución de dinero a un cliente
class RefundHistory {
  final String id;
  final String type; // 'refund'
  final double amount;
  final String description;
  final double balanceAfter;
  final String? paymentMethodId;
  final PaymentMethodInfo? paymentMethod;
  final String? clientId;
  final String clientName;
  final String? clientPhone;
  final String createdBy;
  final DateTime createdAt;

  RefundHistory({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.balanceAfter,
    this.paymentMethodId,
    this.paymentMethod,
    this.clientId,
    required this.clientName,
    this.clientPhone,
    required this.createdBy,
    required this.createdAt,
  });
}

/// Información del método de pago usado en la devolución
class PaymentMethodInfo {
  final String id;
  final String name;
  final String? icon;

  PaymentMethodInfo({
    required this.id,
    required this.name,
    this.icon,
  });

  /// Obtiene el emoji del método de pago
  String get displayIcon {
    switch (icon) {
      case 'cash':
        return '💵';
      case 'bank_transfer':
        return '🏦';
      case 'mobile_payment':
        return '📱';
      case 'debit_card':
      case 'credit_card':
        return '💳';
      default:
        return '💰';
    }
  }
}
