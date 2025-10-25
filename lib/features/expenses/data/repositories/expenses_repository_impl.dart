// lib/features/expenses/data/repositories/expenses_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../datasources/expenses_remote_datasource.dart';

/// Implementation of ExpensesRepository
class ExpensesRepositoryImpl implements ExpensesRepository {
  final ExpensesRemoteDataSource remoteDataSource;

  ExpensesRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Expense>>> getExpenses() async {
    try {
      final expenses = await remoteDataSource.getExpenses();
      return Right(expenses);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(String id) async {
    try {
      final expense = await remoteDataSource.getExpenseById(id);
      return Right(expense);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> createExpense({
    required String description,
    required double amount,
  }) async {
    try {
      final expense = await remoteDataSource.createExpense(
        description: description,
        amount: amount,
      );
      return Right(expense);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense({
    required String id,
    String? description,
    double? amount,
  }) async {
    try {
      final expense = await remoteDataSource.updateExpense(
        id: id,
        description: description,
        amount: amount,
      );
      return Right(expense);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      await remoteDataSource.deleteExpense(id);
      return const Right(null);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }
}
