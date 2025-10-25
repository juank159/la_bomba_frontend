import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_update_task.dart';
import '../repositories/supervisor_repository.dart';

class CompleteTask implements UseCase<ProductUpdateTask, CompleteTaskParams> {
  final SupervisorRepository repository;

  CompleteTask(this.repository);

  @override
  Future<Either<Failure, ProductUpdateTask>> call(CompleteTaskParams params) async {
    return await repository.completeTask(params.taskId, params.notes);
  }
}

class CompleteTaskParams extends Equatable {
  final String taskId;
  final String? notes;

  const CompleteTaskParams({
    required this.taskId,
    this.notes,
  });

  @override
  List<Object?> get props => [taskId, notes];
}