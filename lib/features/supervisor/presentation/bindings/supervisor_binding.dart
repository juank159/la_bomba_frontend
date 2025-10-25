import 'package:get/get.dart';
import '../controllers/supervisor_controller.dart';
import '../../domain/usecases/get_pending_tasks.dart';
import '../../domain/usecases/get_completed_tasks.dart';
import '../../domain/usecases/complete_task.dart';
import '../../domain/usecases/get_task_stats.dart';
import '../../domain/repositories/supervisor_repository.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../../data/datasources/supervisor_remote_data_source.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/di/service_locator.dart';

class SupervisorBinding extends Bindings {
  @override
  void dependencies() {
    // Network Info
    if (!Get.isRegistered<NetworkInfo>()) {
      Get.lazyPut<NetworkInfo>(() => getIt<NetworkInfo>());
    }

    // DioClient
    if (!Get.isRegistered<DioClient>()) {
      Get.lazyPut<DioClient>(() => getIt<DioClient>());
    }

    // Data Sources
    Get.lazyPut<SupervisorRemoteDataSource>(
      () => SupervisorRemoteDataSourceImpl(
        dioClient: Get.find<DioClient>(),
      ),
    );

    // Repository
    Get.lazyPut<SupervisorRepository>(
      () => SupervisorRepositoryImpl(
        remoteDataSource: Get.find<SupervisorRemoteDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
    );

    // Use Cases
    Get.lazyPut<GetPendingTasks>(
      () => GetPendingTasks(Get.find<SupervisorRepository>()),
    );

    Get.lazyPut<GetCompletedTasks>(
      () => GetCompletedTasks(Get.find<SupervisorRepository>()),
    );

    Get.lazyPut<CompleteTask>(
      () => CompleteTask(Get.find<SupervisorRepository>()),
    );

    Get.lazyPut<GetTaskStats>(
      () => GetTaskStats(Get.find<SupervisorRepository>()),
    );

    // Controller
    Get.lazyPut<SupervisorController>(
      () => SupervisorController(
        getPendingTasksUseCase: Get.find<GetPendingTasks>(),
        getCompletedTasksUseCase: Get.find<GetCompletedTasks>(),
        completeTaskUseCase: Get.find<CompleteTask>(),
        getTaskStatsUseCase: Get.find<GetTaskStats>(),
      ),
    );
  }
}