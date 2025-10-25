// lib/features/credits/data/models/credit_transaction_model.dart

import '../../domain/entities/credit_transaction.dart';

/// CreditTransactionModel - Data model for credit transactions
class CreditTransactionModel extends CreditTransaction {
  const CreditTransactionModel({
    required super.id,
    required super.creditId,
    required super.type,
    required super.amount,
    super.description,
    super.createdBy,
    required super.createdAt,
  });

  /// Create from JSON
  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    // Parse amount - handle both string and num
    double amount;
    if (json['amount'] is String) {
      amount = double.parse(json['amount'] as String);
    } else {
      amount = (json['amount'] as num).toDouble();
    }

    return CreditTransactionModel(
      id: json['id'] as String,
      creditId: json['creditId'] as String,
      type: TransactionType.fromString(json['type'] as String),
      amount: amount,
      description: json['description'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditId': creditId,
      'type': type.toBackendString(),
      'amount': amount,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert entity to model
  factory CreditTransactionModel.fromEntity(CreditTransaction entity) {
    return CreditTransactionModel(
      id: entity.id,
      creditId: entity.creditId,
      type: entity.type,
      amount: entity.amount,
      description: entity.description,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }
}
