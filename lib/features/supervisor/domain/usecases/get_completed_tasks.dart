import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_update_task.dart';
import '../repositories/supervisor_repository.dart';

class GetCompletedTasks implements UseCase<List<ProductUpdateTask>, GetCompletedTasksParams> {
  final SupervisorRepository repository;

  GetCompletedTasks(this.repository);

  @override
  Future<Either<Failure, List<ProductUpdateTask>>> call(GetCompletedTasksParams params) async {
    return await repository.getCompletedTasks(page: params.page, limit: params.limit);
  }
}

class GetCompletedTasksParams extends Equatable {
  final int page;
  final int limit;

  const GetCompletedTasksParams({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}