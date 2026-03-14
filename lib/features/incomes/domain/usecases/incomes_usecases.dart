import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:pedidos_frontend/app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/income.dart';
import '../repositories/incomes_repository.dart';

class GetIncomesUseCase implements UseCase<List<Income>, NoParams> {
  final IncomesRepository repository;
  GetIncomesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Income>>> call([NoParams? params]) async {
    return await repository.getIncomes();
  }
}

class GetIncomeByIdUseCase implements UseCase<Income, GetIncomeByIdParams> {
  final IncomesRepository repository;
  GetIncomeByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Income>> call(GetIncomeByIdParams params) async {
    return await repository.getIncomeById(params.id);
  }
}

class GetIncomeByIdParams extends Equatable {
  final String id;
  const GetIncomeByIdParams({required this.id});
  @override
  List<Object?> get props => [id];
}

class CreateIncomeUseCase implements UseCase<Income, CreateIncomeParams> {
  final IncomesRepository repository;
  CreateIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, Income>> call(CreateIncomeParams params) async {
    return await repository.createIncome(description: params.description, amount: params.amount);
  }
}

class CreateIncomeParams extends Equatable {
  final String description;
  final double amount;
  const CreateIncomeParams({required this.description, required this.amount});
  @override
  List<Object?> get props => [description, amount];
}

class UpdateIncomeUseCase implements UseCase<Income, UpdateIncomeParams> {
  final IncomesRepository repository;
  UpdateIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, Income>> call(UpdateIncomeParams params) async {
    return await repository.updateIncome(id: params.id, description: params.description, amount: params.amount);
  }
}

class UpdateIncomeParams extends Equatable {
  final String id;
  final String? description;
  final double? amount;
  const UpdateIncomeParams({required this.id, this.description, this.amount});
  @override
  List<Object?> get props => [id, description, amount];
}

class DeleteIncomeUseCase implements UseCase<void, DeleteIncomeParams> {
  final IncomesRepository repository;
  DeleteIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteIncomeParams params) async {
    return await repository.deleteIncome(params.id);
  }
}

class DeleteIncomeParams extends Equatable {
  final String id;
  const DeleteIncomeParams({required this.id});
  @override
  List<Object?> get props => [id];
}
