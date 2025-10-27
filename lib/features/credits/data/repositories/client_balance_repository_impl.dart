// lib/features/credits/data/repositories/client_balance_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/client_balance.dart';
import '../../domain/entities/client_balance_transaction.dart';
import '../../domain/repositories/client_balance_repository.dart';
import '../datasources/client_balance_remote_datasource.dart';

class ClientBalanceRepositoryImpl implements ClientBalanceRepository {
  final ClientBalanceRemoteDataSource remoteDataSource;

  ClientBalanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ClientBalance>>> getAllClientBalances() async {
    try {
      final balanceModels = await remoteDataSource.getAllClientBalances();
      final balances = balanceModels.map((model) => model.toEntity()).toList();
      return Right(balances);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener saldos: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ClientBalance?>> getClientBalance(
      String clientId) async {
    try {
      final balanceModel = await remoteDataSource.getClientBalance(clientId);
      if (balanceModel == null) {
        return const Right(null);
      }
      return Right(balanceModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener saldo del cliente: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ClientBalanceTransaction>>> getClientTransactions(
      String clientId) async {
    try {
      final transactionModels =
          await remoteDataSource.getClientTransactions(clientId);
      final transactions =
          transactionModels.map((model) => model.toEntity()).toList();
      return Right(transactions);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener transacciones: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ClientBalance>> useBalance({
    required String clientId,
    required double amount,
    required String description,
    String? relatedCreditId,
    String? relatedOrderId,
  }) async {
    try {
      final balanceModel = await remoteDataSource.useBalance(
        clientId: clientId,
        amount: amount,
        description: description,
        relatedCreditId: relatedCreditId,
        relatedOrderId: relatedOrderId,
      );
      return Right(balanceModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al usar saldo: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ClientBalance>> refundBalance({
    required String clientId,
    required double amount,
    required String description,
  }) async {
    try {
      final balanceModel = await remoteDataSource.refundBalance(
        clientId: clientId,
        amount: amount,
        description: description,
      );
      return Right(balanceModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al devolver saldo: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ClientBalance>> adjustBalance({
    required String clientId,
    required double amount,
    required String description,
  }) async {
    try {
      final balanceModel = await remoteDataSource.adjustBalance(
        clientId: clientId,
        amount: amount,
        description: description,
      );
      return Right(balanceModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al ajustar saldo: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
