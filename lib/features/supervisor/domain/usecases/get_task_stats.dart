import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../data/models/product_update_task_model.dart';
import '../repositories/supervisor_repository.dart';

class GetTaskStats implements UseCase<TaskStatsModel, NoParams> {
  final SupervisorRepository repository;

  GetTaskStats(this.repository);

  @override
  Future<Either<Failure, TaskStatsModel>> call(NoParams params) async {
    return await repository.getTaskStats();
  }
}