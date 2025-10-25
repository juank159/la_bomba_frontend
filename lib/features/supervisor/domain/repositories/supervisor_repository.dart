import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/product_update_task.dart';
import '../../data/models/product_update_task_model.dart';

abstract class SupervisorRepository {
  Future<Either<Failure, List<ProductUpdateTask>>> getPendingTasks();
  Future<Either<Failure, List<ProductUpdateTask>>> getCompletedTasks();
  Future<Either<Failure, ProductUpdateTask>> completeTask(String taskId, String? notes);
  Future<Either<Failure, TaskStatsModel>> getTaskStats();
  Future<Either<Failure, ProductUpdateTask>> createTask({
    required String productId,
    required ChangeType changeType,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? description,
  });
}