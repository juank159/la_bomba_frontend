// lib/features/credits/domain/entities/client_balance_transaction.dart

import 'package:equatable/equatable.dart';

/// Tipo de transacción de saldo
enum BalanceTransactionType {
  deposit, // Dinero agregado al saldo (sobrepago, depósito directo)
  usage, // Saldo usado en pago de crédito/pedido
  refund, // Devolución de saldo al cliente
  adjustment, // Ajuste manual (corrección)
}

/// Extensión para obtener el nombre legible del tipo de transacción
extension BalanceTransactionTypeExtension on BalanceTransactionType {
  String get displayName {
    switch (this) {
      case BalanceTransactionType.deposit:
        return 'Depósito';
      case BalanceTransactionType.usage:
        return 'Uso';
      case BalanceTransactionType.refund:
        return 'Reembolso';
      case BalanceTransactionType.adjustment:
        return 'Ajuste';
    }
  }

  String get value {
    switch (this) {
      case BalanceTransactionType.deposit:
        return 'deposit';
      case BalanceTransactionType.usage:
        return 'usage';
      case BalanceTransactionType.refund:
        return 'refund';
      case BalanceTransactionType.adjustment:
        return 'adjustment';
    }
  }

  /// Parsea un string a BalanceTransactionType
  static BalanceTransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'deposit':
        return BalanceTransactionType.deposit;
      case 'usage':
        return BalanceTransactionType.usage;
      case 'refund':
        return BalanceTransactionType.refund;
      case 'adjustment':
        return BalanceTransactionType.adjustment;
      default:
        throw ArgumentError('Unknown transaction type: $value');
    }
  }
}

/// Entidad que representa una transacción de saldo de cliente
class ClientBalanceTransaction extends Equatable {
  final String id;
  final BalanceTransactionType type;
  final double amount;
  final String description;
  final double balanceAfter;
  final String? relatedCreditId;
  final String? relatedOrderId;
  final String createdBy;
  final DateTime createdAt;

  const ClientBalanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.balanceAfter,
    this.relatedCreditId,
    this.relatedOrderId,
    required this.createdBy,
    required this.createdAt,
  });

  /// Formatea el monto como moneda
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  /// Formatea el saldo después de la transacción como moneda
  String get formattedBalanceAfter => '\$${balanceAfter.toStringAsFixed(2)}';

  /// Indica si la transacción es positiva (incrementa saldo)
  bool get isPositive =>
      type == BalanceTransactionType.deposit ||
      type == BalanceTransactionType.adjustment;

  /// Indica si la transacción es negativa (reduce saldo)
  bool get isNegative =>
      type == BalanceTransactionType.usage ||
      type == BalanceTransactionType.refund;

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        description,
        balanceAfter,
        relatedCreditId,
        relatedOrderId,
        createdBy,
        createdAt,
      ];
}
