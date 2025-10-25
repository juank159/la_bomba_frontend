// lib/features/expenses/domain/usecases/expenses_usecases.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:pedidos_frontend/app/core/errors/failures.dart';

import '../../../../app/core/usecases/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expenses_repository.dart';

/// Get all expenses use case
class GetExpensesUseCase implements UseCase<List<Expense>, NoParams> {
  final ExpensesRepository repository;

  GetExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Expense>>> call([NoParams? params]) async {
    return await repository.getExpenses();
  }
}

/// Get expense by ID use case
class GetExpenseByIdUseCase implements UseCase<Expense, GetExpenseByIdParams> {
  final ExpensesRepository repository;

  GetExpenseByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(GetExpenseByIdParams params) async {
    return await repository.getExpenseById(params.id);
  }
}

class GetExpenseByIdParams extends Equatable {
  final String id;

  const GetExpenseByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Create expense use case
class CreateExpenseUseCase implements UseCase<Expense, CreateExpenseParams> {
  final ExpensesRepository repository;

  CreateExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(CreateExpenseParams params) async {
    return await repository.createExpense(
      description: params.description,
      amount: params.amount,
    );
  }
}

class CreateExpenseParams extends Equatable {
  final String description;
  final double amount;

  const CreateExpenseParams({required this.description, required this.amount});

  @override
  List<Object?> get props => [description, amount];
}

/// Update expense use case
class UpdateExpenseUseCase implements UseCase<Expense, UpdateExpenseParams> {
  final ExpensesRepository repository;

  UpdateExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(UpdateExpenseParams params) async {
    return await repository.updateExpense(
      id: params.id,
      description: params.description,
      amount: params.amount,
    );
  }
}

class UpdateExpenseParams extends Equatable {
  final String id;
  final String? description;
  final double? amount;

  const UpdateExpenseParams({required this.id, this.description, this.amount});

  @override
  List<Object?> get props => [id, description, amount];
}

/// Delete expense use case
class DeleteExpenseUseCase implements UseCase<void, DeleteExpenseParams> {
  final ExpensesRepository repository;

  DeleteExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteExpenseParams params) async {
    return await repository.deleteExpense(params.id);
  }
}

class DeleteExpenseParams extends Equatable {
  final String id;

  const DeleteExpenseParams({required this.id});

  @override
  List<Object?> get props => [id];
}
