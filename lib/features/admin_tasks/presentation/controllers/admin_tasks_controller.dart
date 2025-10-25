// lib/features/admin_tasks/presentation/controllers/admin_tasks_controller.dart

import 'package:get/get.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../products/domain/repositories/products_repository.dart';
import '../../domain/entities/temporary_product.dart';
import '../../data/models/temporary_product_model.dart';

class AdminTasksController extends GetxController {
  final ProductsRepository _productsRepository = getIt<ProductsRepository>();

  // Observable lists
  final RxList<TemporaryProduct> _allTasks = <TemporaryProduct>[].obs;
  final RxList<TemporaryProduct> _pendingTasks = <TemporaryProduct>[].obs;
  final RxList<TemporaryProduct> _completedTasks = <TemporaryProduct>[].obs;

  // Loading states
  final RxBool _isLoadingAll = false.obs;
  final RxBool _isLoadingPending = false.obs;
  final RxBool _isLoadingCompleted = false.obs;
  final RxBool _isCompletingTask = false.obs;
  final RxBool _isCancellingTask = false.obs;

  // Getters
  List<TemporaryProduct> get allTasks => _allTasks;
  List<TemporaryProduct> get pendingTasks => _pendingTasks;
  List<TemporaryProduct> get completedTasks => _completedTasks;

  bool get isLoadingAll => _isLoadingAll.value;
  bool get isLoadingPending => _isLoadingPending.value;
  bool get isLoadingCompleted => _isLoadingCompleted.value;
  bool get isCompletingTask => _isCompletingTask.value;
  bool get isCancellingTask => _isCancellingTask.value;

  // Stats
  int get pendingCount => _pendingTasks.length;
  int get completedCount => _completedTasks
      .where((t) => t.isCompleted || t.isPendingSupervisor)
      .length;
  int get cancelledCount => _completedTasks.where((t) => t.isCancelled).length;

  @override
  void onInit() {
    super.onInit();
    loadPendingTasks();
  }

  /// Load all tasks
  Future<void> loadAllTasks() async {
    _isLoadingAll.value = true;

    final result = await _productsRepository.getAllTemporaryProducts();

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudieron cargar las tareas: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
        );
        _isLoadingAll.value = false;
      },
      (tasksData) {
        final tasks = tasksData
            .map((data) => TemporaryProductModel.fromJson(data).toEntity())
            .toList();

        _allTasks.assignAll(tasks);
        _isLoadingAll.value = false;
      },
    );
  }

  /// Load pending tasks (pending_admin status)
  Future<void> loadPendingTasks() async {
    _isLoadingPending.value = true;

    final result = await _productsRepository.getAllTemporaryProducts();

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudieron cargar las tareas pendientes: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
        );
        _isLoadingPending.value = false;
      },
      (tasksData) {
        final tasks = tasksData
            .map((data) => TemporaryProductModel.fromJson(data).toEntity())
            .toList();

        // Filter only pending_admin tasks
        final pending = tasks.where((t) => t.isPendingAdmin).toList();

        _pendingTasks.assignAll(pending);
        _isLoadingPending.value = false;
      },
    );
  }

  /// Load completed/cancelled tasks
  Future<void> loadCompletedTasks() async {
    _isLoadingCompleted.value = true;

    final result = await _productsRepository.getAllTemporaryProducts();

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudieron cargar las tareas completadas: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
        );
        _isLoadingCompleted.value = false;
      },
      (tasksData) {
        final tasks = tasksData
            .map((data) => TemporaryProductModel.fromJson(data).toEntity())
            .toList();

        // Filter completed, cancelled, or pending_supervisor
        final completed = tasks
            .where(
              (t) => t.isCompleted || t.isCancelled || t.isPendingSupervisor,
            )
            .toList();

        _completedTasks.assignAll(completed);
        _isLoadingCompleted.value = false;
      },
    );
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      loadPendingTasks(),
      if (_completedTasks.isNotEmpty) loadCompletedTasks(),
    ]);
  }

  /// Complete task (product arrived - add prices and IVA)
  Future<void> completeTask({
    required String taskId,
    required double precioA,
    required double iva,
    double? precioB,
    double? precioC,
    double? costo,
    String? description,
    String? barcode,
  }) async {
    _isCompletingTask.value = true;

    final updateData = {
      'precioA': precioA,
      'iva': iva,
      if (precioB != null) 'precioB': precioB,
      if (precioC != null) 'precioC': precioC,
      if (costo != null) 'costo': costo,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
    };

    final result = await _productsRepository.updateTemporaryProduct(
      taskId,
      updateData,
    );

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudo completar la tarea: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
        _isCompletingTask.value = false;
      },
      (updatedTask) {
        Get.snackbar(
          'Tarea completada',
          'Se agregaron los precios e IVA. El supervisor recibirá una notificación.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.primary,
        );
        _isCompletingTask.value = false;

        // Refresh tasks
        refreshData();
      },
    );
  }

  /// Cancel task (product did NOT arrive)
  Future<void> cancelTask({required String taskId, String? reason}) async {
    _isCancellingTask.value = true;

    final result = await _productsRepository.cancelTemporaryProduct(
      taskId,
      reason: reason,
    );

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudo cancelar la tarea: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
        _isCancellingTask.value = false;
      },
      (cancelledTask) {
        Get.snackbar(
          'Tarea cancelada',
          'El producto fue marcado como "no llegó".',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.primary,
        );
        _isCancellingTask.value = false;

        // Refresh tasks
        refreshData();
      },
    );
  }
}
