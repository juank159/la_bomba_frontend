import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_update_task.dart';
import '../repositories/supervisor_repository.dart';

class GetPendingTasks implements UseCase<List<ProductUpdateTask>, GetPendingTasksParams> {
  final SupervisorRepository repository;

  GetPendingTasks(this.repository);

  @override
  Future<Either<Failure, List<ProductUpdateTask>>> call(GetPendingTasksParams params) async {
    return await repository.getPendingTasks(page: params.page, limit: params.limit);
  }
}

class GetPendingTasksParams extends Equatable {
  final int page;
  final int limit;

  const GetPendingTasksParams({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}