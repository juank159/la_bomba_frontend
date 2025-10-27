// lib/features/credits/data/models/client_balance_model.dart

import '../../domain/entities/client_balance.dart';
import 'client_balance_transaction_model.dart';

class ClientBalanceModel extends ClientBalance {
  const ClientBalanceModel({
    required super.id,
    required super.clientId,
    required super.clientName,
    required super.balance,
    required super.transactions,
    required super.createdBy,
    super.updatedBy,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Crea una instancia desde JSON
  factory ClientBalanceModel.fromJson(Map<String, dynamic> json) {
    return ClientBalanceModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      balance: (json['balance'] as num).toDouble(),
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((t) =>
                  ClientBalanceTransactionModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['createdBy'] as String,
      updatedBy: json['updatedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'balance': balance,
      'transactions': transactions
          .map((t) => (t as ClientBalanceTransactionModel).toJson())
          .toList(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convierte el modelo a entidad
  ClientBalance toEntity() {
    return ClientBalance(
      id: id,
      clientId: clientId,
      clientName: clientName,
      balance: balance,
      transactions: transactions
          .map((t) => (t as ClientBalanceTransactionModel).toEntity())
          .toList(),
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
