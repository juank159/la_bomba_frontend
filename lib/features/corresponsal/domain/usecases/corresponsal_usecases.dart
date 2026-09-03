// lib/features/corresponsal/domain/usecases/corresponsal_usecases.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/corresponsal_entry.dart';
import '../repositories/corresponsal_repository.dart';

class GetCorresponsalEntriesUseCase implements UseCase<List<CorresponsalEntry>, NoParams> {
  final CorresponsalRepository repository;

  GetCorresponsalEntriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CorresponsalEntry>>> call([NoParams? params]) async {
    return await repository.getEntries();
  }
}

class CreateCorresponsalEntryUseCase implements UseCase<CorresponsalEntry, CreateCorresponsalEntryParams> {
  final CorresponsalRepository repository;

  CreateCorresponsalEntryUseCase(this.repository);

  @override
  Future<Either<Failure, CorresponsalEntry>> call(CreateCorresponsalEntryParams params) async {
    return await repository.createEntry(amount: params.amount, note: params.note);
  }
}

class CreateCorresponsalEntryParams extends Equatable {
  final double amount;
  final String? note;

  const CreateCorresponsalEntryParams({required this.amount, this.note});

  @override
  List<Object?> get props => [amount, note];
}

class DeleteCorresponsalEntryUseCase implements UseCase<void, DeleteCorresponsalEntryParams> {
  final CorresponsalRepository repository;

  DeleteCorresponsalEntryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCorresponsalEntryParams params) async {
    return await repository.deleteEntry(params.id);
  }
}

class DeleteCorresponsalEntryParams extends Equatable {
  final String id;

  const DeleteCorresponsalEntryParams({required this.id});

  @override
  List<Object?> get props => [id];
}
