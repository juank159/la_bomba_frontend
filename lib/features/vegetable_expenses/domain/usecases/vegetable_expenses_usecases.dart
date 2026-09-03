// lib/features/vegetable_expenses/domain/usecases/vegetable_expenses_usecases.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/vegetable_expense.dart';
import '../repositories/vegetable_expenses_repository.dart';

class GetVegetableExpensesUseCase implements UseCase<List<VegetableExpense>, NoParams> {
  final VegetableExpensesRepository repository;

  GetVegetableExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<VegetableExpense>>> call([NoParams? params]) async {
    return await repository.getExpenses();
  }
}

class CreateVegetableExpenseUseCase implements UseCase<VegetableExpense, CreateVegetableExpenseParams> {
  final VegetableExpensesRepository repository;

  CreateVegetableExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, VegetableExpense>> call(CreateVegetableExpenseParams params) async {
    return await repository.createExpense(
      description: params.description,
      amount: params.amount,
      fundingSource: params.fundingSource,
    );
  }
}

class CreateVegetableExpenseParams extends Equatable {
  final String description;
  final double amount;
  final ExpenseFundingSource fundingSource;

  const CreateVegetableExpenseParams({required this.description, required this.amount, required this.fundingSource});

  @override
  List<Object?> get props => [description, amount, fundingSource];
}

class UpdateVegetableExpenseUseCase implements UseCase<VegetableExpense, UpdateVegetableExpenseParams> {
  final VegetableExpensesRepository repository;

  UpdateVegetableExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, VegetableExpense>> call(UpdateVegetableExpenseParams params) async {
    return await repository.updateExpense(id: params.id, description: params.description, amount: params.amount);
  }
}

class UpdateVegetableExpenseParams extends Equatable {
  final String id;
  final String? description;
  final double? amount;

  const UpdateVegetableExpenseParams({required this.id, this.description, this.amount});

  @override
  List<Object?> get props => [id, description, amount];
}

class DeleteVegetableExpenseUseCase implements UseCase<void, DeleteVegetableExpenseParams> {
  final VegetableExpensesRepository repository;

  DeleteVegetableExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteVegetableExpenseParams params) async {
    return await repository.deleteExpense(params.id);
  }
}

class DeleteVegetableExpenseParams extends Equatable {
  final String id;

  const DeleteVegetableExpenseParams({required this.id});

  @override
  List<Object?> get props => [id];
}
