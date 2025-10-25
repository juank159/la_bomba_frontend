// lib/features/credits/domain/entities/credit_transaction.dart

import 'package:equatable/equatable.dart';

/// Transaction type enum
enum TransactionType {
  charge,        // Cargo inicial / Deuda inicial
  debtIncrease,  // Aumento de deuda
  payment;       // Pago

  String get displayName {
    switch (this) {
      case TransactionType.charge:
        return 'Deuda Inicial';
      case TransactionType.debtIncrease:
        return 'Aumento de Deuda';
      case TransactionType.payment:
        return 'Pago';
    }
  }

  static TransactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'charge':
        return TransactionType.charge;
      case 'debt_increase':
        return TransactionType.debtIncrease;
      case 'payment':
        return TransactionType.payment;
      default:
        return TransactionType.payment;
    }
  }

  String toBackendString() {
    switch (this) {
      case TransactionType.charge:
        return 'charge';
      case TransactionType.debtIncrease:
        return 'debt_increase';
      case TransactionType.payment:
        return 'payment';
    }
  }
}

/// CreditTransaction entity representing a transaction in a credit
class CreditTransaction extends Equatable {
  final String id;
  final String creditId;
  final TransactionType type;
  final double amount;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;

  const CreditTransaction({
    required this.id,
    required this.creditId,
    required this.type,
    required this.amount,
    this.description,
    this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        creditId,
        type,
        amount,
        description,
        createdBy,
        createdAt,
      ];

  /// Check if transaction is initial charge
  bool get isCharge => type == TransactionType.charge;

  /// Check if transaction is a debt increase
  bool get isDebtIncrease => type == TransactionType.debtIncrease;

  /// Check if transaction is a payment
  bool get isPayment => type == TransactionType.payment;
}
