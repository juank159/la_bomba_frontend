import 'package:dartz/dartz.dart';
import '../../domain/repositories/supervisor_repository.dart';
import '../../domain/entities/product_update_task.dart';
import '../models/product_update_task_model.dart';
import '../datasources/supervisor_remote_data_source.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';

class SupervisorRepositoryImpl implements SupervisorRepository {
  final SupervisorRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SupervisorRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ProductUpdateTask>>> getPendingTasks() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteTasks = await remoteDataSource.getPendingTasks();
        return Right(remoteTasks);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<ProductUpdateTask>>> getCompletedTasks() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteTasks = await remoteDataSource.getCompletedTasks();
        return Right(remoteTasks);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ProductUpdateTask>> completeTask(String taskId, String? notes) async {
    if (await networkInfo.isConnected) {
      try {
        final task = await remoteDataSource.completeTask(taskId, notes);
        return Right(task);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TaskStatsModel>> getTaskStats() async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getTaskStats();
        return Right(stats);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ProductUpdateTask>> createTask({
    required String productId,
    required ChangeType changeType,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? description,
    String? adminNotes,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final task = await remoteDataSource.createTask(
          productId: productId,
          changeType: changeType,
          oldValue: oldValue,
          newValue: newValue,
          description: description,
          adminNotes: adminNotes,
        );
        return Right(task);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}