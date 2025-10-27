// lib/features/credits/domain/entities/client_balance.dart

import 'package:equatable/equatable.dart';
import 'client_balance_transaction.dart';

/// Entidad que representa el saldo a favor de un cliente
class ClientBalance extends Equatable {
  final String id;
  final String clientId;
  final String clientName;
  final double balance;
  final List<ClientBalanceTransaction> transactions;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientBalance({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.balance,
    required this.transactions,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Verifica si el cliente tiene saldo disponible
  bool get hasBalance => balance > 0;

  /// Formatea el saldo como moneda
  String get formattedBalance => '\$${balance.toStringAsFixed(2)}';

  /// Obtiene la última transacción
  ClientBalanceTransaction? get lastTransaction =>
      transactions.isNotEmpty ? transactions.first : null;

  @override
  List<Object?> get props => [
        id,
        clientId,
        clientName,
        balance,
        transactions,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
      ];
}
