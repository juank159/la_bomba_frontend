import 'package:get/get.dart';
import '../controllers/admin_tasks_controller.dart';

/// Dependency injection binding for AdminTasks feature
class AdminTasksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminTasksController>(
      () => AdminTasksController(),
    );
  }
}
