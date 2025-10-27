// lib/features/credits/domain/repositories/client_balance_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/client_balance.dart';
import '../entities/client_balance_transaction.dart';

/// Repositorio para operaciones de saldo de clientes
abstract class ClientBalanceRepository {
  /// Obtiene todos los saldos de clientes (con saldo > 0)
  Future<Either<Failure, List<ClientBalance>>> getAllClientBalances();

  /// Obtiene el saldo de un cliente específico
  Future<Either<Failure, ClientBalance?>> getClientBalance(String clientId);

  /// Obtiene el historial de transacciones de un cliente
  Future<Either<Failure, List<ClientBalanceTransaction>>> getClientTransactions(
      String clientId);

  /// Usa saldo del cliente para pagar crédito u orden
  Future<Either<Failure, ClientBalance>> useBalance({
    required String clientId,
    required double amount,
    required String description,
    String? relatedCreditId,
    String? relatedOrderId,
  });

  /// Devuelve saldo al cliente (reembolso)
  Future<Either<Failure, ClientBalance>> refundBalance({
    required String clientId,
    required double amount,
    required String description,
  });

  /// Ajusta saldo manualmente (corrección)
  Future<Either<Failure, ClientBalance>> adjustBalance({
    required String clientId,
    required double amount,
    required String description,
  });
}
