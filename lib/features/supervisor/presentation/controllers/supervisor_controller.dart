// lib/features/supervisor/presentation/controllers/supervisor_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../domain/entities/product_update_task.dart';
import '../../domain/usecases/get_pending_tasks.dart';
import '../../domain/usecases/get_completed_tasks.dart';
import '../../domain/usecases/complete_task.dart';
import '../../domain/usecases/get_task_stats.dart';
import '../../data/models/product_update_task_model.dart';
import '../../../admin_tasks/domain/entities/temporary_product.dart';
import '../../../admin_tasks/data/models/temporary_product_model.dart';
import '../../../products/domain/repositories/products_repository.dart';
import '../../../orders/presentation/widgets/barcode_scanner_overlay.dart';

class SupervisorController extends GetxController {
  final GetPendingTasks getPendingTasksUseCase;
  final GetCompletedTasks getCompletedTasksUseCase;
  final CompleteTask completeTaskUseCase;
  final GetTaskStats getTaskStatsUseCase;
  final ProductsRepository _productsRepository = getIt<ProductsRepository>();

  SupervisorController({
    required this.getPendingTasksUseCase,
    required this.getCompletedTasksUseCase,
    required this.completeTaskUseCase,
    required this.getTaskStatsUseCase,
  });

  // Observable lists for ProductUpdateTask
  final RxList<ProductUpdateTask> _pendingTasks = <ProductUpdateTask>[].obs;
  final RxList<ProductUpdateTask> _completedTasks = <ProductUpdateTask>[].obs;
  final Rx<TaskStatsModel?> _taskStats = Rx<TaskStatsModel?>(null);

  // Observable lists for TemporaryProduct
  final RxList<TemporaryProduct> _pendingTemporaryProducts =
      <TemporaryProduct>[].obs;
  final RxList<TemporaryProduct> _completedTemporaryProducts =
      <TemporaryProduct>[].obs;

  // Loading states for ProductUpdateTask
  final RxBool _isLoadingPending = false.obs;
  final RxBool _isLoadingCompleted = false.obs;
  final RxBool _isLoadingStats = false.obs;
  final RxBool _isCompletingTask = false.obs;

  // Loading states for TemporaryProduct
  final RxBool _isLoadingTemporaryProducts = false.obs;
  final RxBool _isCompletingTemporaryProduct = false.obs;

  // Error states
  final RxString _errorMessage = ''.obs;

  // Getters for ProductUpdateTask
  List<ProductUpdateTask> get pendingTasks => _pendingTasks;
  List<ProductUpdateTask> get completedTasks => _completedTasks;
  TaskStatsModel? get taskStats => _taskStats.value;
  bool get isLoadingPending => _isLoadingPending.value;
  bool get isLoadingCompleted => _isLoadingCompleted.value;
  bool get isLoadingStats => _isLoadingStats.value;
  bool get isCompletingTask => _isCompletingTask.value;
  String get errorMessage => _errorMessage.value;

  // Getters for TemporaryProduct
  List<TemporaryProduct> get pendingTemporaryProducts =>
      _pendingTemporaryProducts;
  List<TemporaryProduct> get completedTemporaryProducts =>
      _completedTemporaryProducts;
  bool get isLoadingTemporaryProducts => _isLoadingTemporaryProducts.value;
  bool get isCompletingTemporaryProduct => _isCompletingTemporaryProduct.value;

  // Stats for TemporaryProduct
  int get pendingTemporaryProductsCount => _pendingTemporaryProducts.length;
  int get completedTemporaryProductsCount => _completedTemporaryProducts.length;

  // Filter states
  final RxString _selectedFilter = 'all'.obs;
  final RxString _searchQuery = ''.obs;

  String get selectedFilter => _selectedFilter.value;
  String get searchQuery => _searchQuery.value;

  // Filtered lists
  List<ProductUpdateTask> get filteredPendingTasks {
    var tasks = _pendingTasks.toList();

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      tasks = tasks
          .where(
            (task) =>
                task.product.description.toLowerCase().contains(
                  _searchQuery.value.toLowerCase(),
                ) ||
                task.product.barcode.toLowerCase().contains(
                  _searchQuery.value.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply type filter
    if (_selectedFilter.value != 'all') {
      final filterType = ChangeType.fromString(_selectedFilter.value);
      tasks = tasks.where((task) => task.changeType == filterType).toList();
    }

    return tasks;
  }

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  /// Load all supervisor data
  Future<void> loadAllData() async {
    await Future.wait([
      loadPendingTasks(),
      loadTaskStats(),
      loadPendingTemporaryProducts(),
    ]);
  }

  /// Load pending tasks
  Future<void> loadPendingTasks() async {
    _isLoadingPending.value = true;
    _errorMessage.value = '';

    final result = await getPendingTasksUseCase(NoParams());
    result.fold(
      (failure) {
        _errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          'No se pudieron cargar las tareas pendientes: ${failure.message}',
          snackPosition: SnackPosition.TOP,
        );
      },
      (tasks) {
        _pendingTasks.value = tasks;
      },
    );

    _isLoadingPending.value = false;
  }

  /// Load completed tasks
  Future<void> loadCompletedTasks() async {
    _isLoadingCompleted.value = true;
    _errorMessage.value = '';

    final result = await getCompletedTasksUseCase(NoParams());
    result.fold(
      (failure) {
        _errorMessage.value = failure.message;
        Get.snackbar(
          'Error',
          'No se pudieron cargar las tareas completadas: ${failure.message}',
          snackPosition: SnackPosition.TOP,
        );
      },
      (tasks) {
        _completedTasks.value = tasks;
      },
    );

    _isLoadingCompleted.value = false;
  }

  /// Load task statistics
  Future<void> loadTaskStats() async {
    _isLoadingStats.value = true;

    final result = await getTaskStatsUseCase(NoParams());
    result.fold(
      (failure) {
        // Stats failure is not critical, don't show error
        _taskStats.value = null;
      },
      (stats) {
        _taskStats.value = stats;
      },
    );

    _isLoadingStats.value = false;
  }

  /// Complete a task
  Future<void> completeTask(String taskId, {String? notes}) async {
    _isCompletingTask.value = true;

    final params = CompleteTaskParams(taskId: taskId, notes: notes);
    final result = await completeTaskUseCase(params);

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudo completar la tarea: ${failure.message}',
          snackPosition: SnackPosition.TOP,
        );
      },
      (completedTask) {
        // Remove from pending tasks
        _pendingTasks.removeWhere((task) => task.id == taskId);

        // Add to completed tasks
        _completedTasks.insert(0, completedTask);

        // Update stats
        loadTaskStats();

        Get.snackbar(
          'Éxito',
          'Tarea completada correctamente',
          snackPosition: SnackPosition.TOP,
        );
      },
    );

    _isCompletingTask.value = false;
  }

  /// Approve a task (same as complete for supervisor)
  Future<void> approveTask(String taskId, {String? notes}) async {
    await completeTask(taskId, notes: notes);
  }

  /// Set filter
  void setFilter(String filter) {
    _selectedFilter.value = filter;
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery.value = query;
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await loadAllData();
  }

  /// Get task by ID
  ProductUpdateTask? getTaskById(String taskId) {
    try {
      return _pendingTasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      try {
        return _completedTasks.firstWhere((task) => task.id == taskId);
      } catch (e) {
        return null;
      }
    }
  }

  /// Get pending tasks count by type
  int getPendingCountByType(ChangeType type) {
    return _pendingTasks.where((task) => task.changeType == type).length;
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  // ===== Temporary Products Methods =====

  /// Load pending temporary products (status = pending_supervisor)
  Future<void> loadPendingTemporaryProducts() async {
    _isLoadingTemporaryProducts.value = true;

    final result = await _productsRepository.getAllTemporaryProducts();

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudieron cargar los productos nuevos: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
        );
        _isLoadingTemporaryProducts.value = false;
      },
      (productsData) {
        final products = productsData
            .map((data) => TemporaryProductModel.fromJson(data).toEntity())
            .toList();

        // Filter only pending_supervisor products
        final pending = products.where((p) => p.isPendingSupervisor).toList();

        _pendingTemporaryProducts.assignAll(pending);
        _isLoadingTemporaryProducts.value = false;
      },
    );
  }

  /// Load completed temporary products
  Future<void> loadCompletedTemporaryProducts() async {
    _isLoadingTemporaryProducts.value = true;

    final result = await _productsRepository.getAllTemporaryProducts();

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudieron cargar los productos completados: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
        );
        _isLoadingTemporaryProducts.value = false;
      },
      (productsData) {
        final products = productsData
            .map((data) => TemporaryProductModel.fromJson(data).toEntity())
            .toList();

        // Filter only completed products
        final completed = products.where((p) => p.isCompleted).toList();

        _completedTemporaryProducts.assignAll(completed);
        _isLoadingTemporaryProducts.value = false;
      },
    );
  }

  /// Complete temporary product with barcode check dialog
  /// This method checks if barcode is missing and shows optional dialog
  Future<void> completeTemporaryProductWithBarcodeCheck(
    String productId, {
    String? notes,
  }) async {
    // Find the product
    final product = getTemporaryProductById(productId);
    if (product == null) {
      Get.snackbar(
        'Error',
        'No se encontró el producto temporal',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return;
    }

    // If barcode is empty or null, ask user if they want to add it
    if (product.barcode == null || product.barcode!.trim().isEmpty) {
      final result = await Get.dialog<Map<String, dynamic>>(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.qr_code, color: Get.theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Código de Barras Opcional')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El producto "${product.name}" no tiene código de barras.',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Deseas agregar un código de barras antes de registrar el producto?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Este campo es opcional. Puedes agregarlo ahora o dejarlo vacío.',
                style: TextStyle(
                  fontSize: 12,
                  color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Get.back(result: {'skip': true}),
              icon: const Icon(Icons.skip_next),
              label: const Text('Omitir y Continuar'),
              style: TextButton.styleFrom(
                foregroundColor: Get.theme.colorScheme.onSurface.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showBarcodeInputDialog(productId, notes),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Agregar Código'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (result != null && result['skip'] == true) {
        // User chose to skip, complete without barcode
        await completeTemporaryProduct(productId, notes: notes, barcode: null);
      }
    } else {
      // Barcode already exists, proceed directly with existing barcode
      await completeTemporaryProduct(
        productId,
        notes: notes,
        barcode: product.barcode,
      );
    }
  }

  /// Show barcode input dialog
  Future<void> _showBarcodeInputDialog(String productId, String? notes) async {
    final barcodeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isScanning = false.obs;

    Get.back(); // Close the previous dialog

    // Handle barcode scanned
    void handleBarcodeScanned(String barcode) {
      print('📊 [SupervisorController] Barcode scanned: $barcode');

      // Stop scanning
      isScanning.value = false;

      // Set the barcode in the text field
      barcodeController.text = barcode;

      // Show feedback
      Get.snackbar(
        'Código Escaneado',
        'Código de barras: $barcode',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
        icon: Icon(
          Icons.qr_code_scanner,
          color: Get.theme.colorScheme.primary,
        ),
      );
    }

    final result = await Get.dialog<String>(
      Stack(
        children: [
          AlertDialog(
            title: const Text('Ingrese Código de Barras'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Código de Barras',
                      hintText: 'Ej: 7501234567890',
                      prefixIcon: const Icon(Icons.qr_code),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: 'Escanear código de barras',
                        onPressed: () {
                          print('📷 [SupervisorController] Starting barcode scanning');
                          isScanning.value = true;
                        },
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese un código de barras válido';
                      }
                      if (value.trim().length < 8) {
                        return 'El código debe tener al menos 8 dígitos';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Get.back(result: barcodeController.text.trim());
                  }
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
          // Barcode Scanner Overlay
          Obx(() {
            if (isScanning.value) {
              return BarcodeScannerOverlay(
                onBarcodeDetected: handleBarcodeScanned,
                onClose: () {
                  print('🛑 [SupervisorController] Stopping barcode scanning');
                  isScanning.value = false;
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      barrierDismissible: false,
    );

    if (result != null) {
      // User entered a barcode, complete with it
      await completeTemporaryProduct(productId, notes: notes, barcode: result);
    } else {
      // User cancelled, show the original dialog again
      await completeTemporaryProductWithBarcodeCheck(productId, notes: notes);
    }
  }

  /// Complete temporary product (supervisor confirms product is applied)
  /// This will automatically register the product in the products table
  Future<void> completeTemporaryProduct(
    String productId, {
    String? notes,
    String? barcode,
  }) async {
    _isCompletingTemporaryProduct.value = true;

    final result = await _productsRepository
        .completeTemporaryProductBySupervisor(
          productId,
          notes: notes,
          barcode: barcode,
        );

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudo completar el producto: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
        _isCompletingTemporaryProduct.value = false;
      },
      (completedProduct) {
        // Remove from pending list
        _pendingTemporaryProducts.removeWhere((p) => p.id == productId);

        // Add to completed list (convert back to entity)
        final entity = TemporaryProductModel.fromJson(
          completedProduct,
        ).toEntity();
        _completedTemporaryProducts.insert(0, entity);

        Get.snackbar(
          'Producto Registrado',
          'El producto ha sido registrado exitosamente en el sistema.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.primary,
          duration: const Duration(seconds: 4),
          icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.primary),
        );
        _isCompletingTemporaryProduct.value = false;
      },
    );
  }

  /// Refresh temporary products data
  Future<void> refreshTemporaryProducts() async {
    await loadPendingTemporaryProducts();
  }

  /// Get temporary product by ID
  TemporaryProduct? getTemporaryProductById(String productId) {
    try {
      return _pendingTemporaryProducts.firstWhere((p) => p.id == productId);
    } catch (e) {
      try {
        return _completedTemporaryProducts.firstWhere((p) => p.id == productId);
      } catch (e) {
        return null;
      }
    }
  }
}
