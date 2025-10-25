// lib/features/expenses/domain/repositories/expenses_repository.dart

import 'package:dartz/dartz.dart';
import 'package:pedidos_frontend/app/core/errors/failures.dart';

import '../entities/expense.dart';

/// Expenses repository interface - Domain layer
abstract class ExpensesRepository {
  /// Get all expenses
  Future<Either<Failure, List<Expense>>> getExpenses();

  /// Get expense by ID
  Future<Either<Failure, Expense>> getExpenseById(String id);

  /// Create a new expense
  Future<Either<Failure, Expense>> createExpense({
    required String description,
    required double amount,
  });

  /// Update an expense
  Future<Either<Failure, Expense>> updateExpense({
    required String id,
    String? description,
    double? amount,
  });

  /// Delete an expense
  Future<Either<Failure, void>> deleteExpense(String id);
}
