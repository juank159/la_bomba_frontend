// lib/features/vegetable_expenses/domain/repositories/vegetable_expenses_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_expense.dart';

abstract class VegetableExpensesRepository {
  Future<Either<Failure, List<VegetableExpense>>> getExpenses();
  Future<Either<Failure, VegetableExpense>> getExpenseById(String id);

  Future<Either<Failure, VegetableExpense>> createExpense({
    required String description,
    required double amount,
    required ExpenseFundingSource fundingSource,
  });

  Future<Either<Failure, VegetableExpense>> updateExpense({
    required String id,
    String? description,
    double? amount,
  });

  Future<Either<Failure, void>> deleteExpense(String id);
}
