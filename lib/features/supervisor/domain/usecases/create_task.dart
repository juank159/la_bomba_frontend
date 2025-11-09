import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/product_update_task.dart';
import '../repositories/supervisor_repository.dart';

class CreateTask implements UseCase<ProductUpdateTask, CreateTaskParams> {
  final SupervisorRepository repository;

  CreateTask(this.repository);

  @override
  Future<Either<Failure, ProductUpdateTask>> call(CreateTaskParams params) async {
    return await repository.createTask(
      productId: params.productId,
      changeType: params.changeType,
      oldValue: params.oldValue,
      newValue: params.newValue,
      description: params.description,
      adminNotes: params.adminNotes,
    );
  }
}

class CreateTaskParams {
  final String productId;
  final ChangeType changeType;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String? description;
  final String? adminNotes;

  CreateTaskParams({
    required this.productId,
    required this.changeType,
    this.oldValue,
    this.newValue,
    this.description,
    this.adminNotes,
  });
}