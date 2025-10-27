// lib/features/credits/data/models/client_balance_transaction_model.dart

import '../../domain/entities/client_balance_transaction.dart';

class ClientBalanceTransactionModel extends ClientBalanceTransaction {
  const ClientBalanceTransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.description,
    required super.balanceAfter,
    super.relatedCreditId,
    super.relatedOrderId,
    required super.createdBy,
    required super.createdAt,
  });

  /// Crea una instancia desde JSON
  factory ClientBalanceTransactionModel.fromJson(Map<String, dynamic> json) {
    return ClientBalanceTransactionModel(
      id: json['id'] as String,
      type: BalanceTransactionTypeExtension.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      relatedCreditId: json['relatedCreditId'] as String?,
      relatedOrderId: json['relatedOrderId'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'amount': amount,
      'description': description,
      'balanceAfter': balanceAfter,
      'relatedCreditId': relatedCreditId,
      'relatedOrderId': relatedOrderId,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convierte el modelo a entidad
  ClientBalanceTransaction toEntity() {
    return ClientBalanceTransaction(
      id: id,
      type: type,
      amount: amount,
      description: description,
      balanceAfter: balanceAfter,
      relatedCreditId: relatedCreditId,
      relatedOrderId: relatedOrderId,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
