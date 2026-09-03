// lib/features/vegetable_expenses/data/repositories/vegetable_expenses_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/vegetable_expense.dart';
import '../../domain/repositories/vegetable_expenses_repository.dart';
import '../datasources/vegetable_expenses_remote_datasource.dart';

class VegetableExpensesRepositoryImpl implements VegetableExpensesRepository {
  final VegetableExpensesRemoteDataSource remoteDataSource;

  VegetableExpensesRepositoryImpl({required this.remoteDataSource});

  Failure _mapException(Object e, String fallbackMessage) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ValidationException) return ValidationFailure(e.message, code: 'VALIDATION_ERROR');
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return ServerFailure.notFound(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return UnexpectedFailure(
      '$fallbackMessage: ${e.toString()}',
      exception: e is Exception ? e : Exception(e.toString()),
    );
  }

  @override
  Future<Either<Failure, List<VegetableExpense>>> getExpenses() async {
    try {
      final models = await remoteDataSource.getExpenses();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener los gastos'));
    }
  }

  @override
  Future<Either<Failure, VegetableExpense>> getExpenseById(String id) async {
    try {
      final model = await remoteDataSource.getExpenseById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener el gasto'));
    }
  }

  @override
  Future<Either<Failure, VegetableExpense>> createExpense({
    required String description,
    required double amount,
    required ExpenseFundingSource fundingSource,
  }) async {
    try {
      final model = await remoteDataSource.createExpense(description: description, amount: amount, fundingSource: fundingSource);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al crear el gasto'));
    }
  }

  @override
  Future<Either<Failure, VegetableExpense>> updateExpense({required String id, String? description, double? amount}) async {
    try {
      final model = await remoteDataSource.updateExpense(id: id, description: description, amount: amount);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al actualizar el gasto'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      await remoteDataSource.deleteExpense(id);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al eliminar el gasto'));
    }
  }
}
