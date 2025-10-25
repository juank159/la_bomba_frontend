import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_update_task.dart';
import '../repositories/supervisor_repository.dart';

class GetCompletedTasks implements UseCase<List<ProductUpdateTask>, NoParams> {
  final SupervisorRepository repository;

  GetCompletedTasks(this.repository);

  @override
  Future<Either<Failure, List<ProductUpdateTask>>> call(NoParams params) async {
    return await repository.getCompletedTasks();
  }
}