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

  // Pagination states for pending tasks
  final RxBool _isLoadingMorePending = false.obs;
  final RxInt _pendingCurrentPage = 1.obs;
  final RxBool _hasMorePendingTasks = true.obs;

  // Pagination states for completed tasks
  final RxBool _isLoadingMoreCompleted = false.obs;
  final RxInt _completedCurrentPage = 1.obs;
  final RxBool _hasMoreCompletedTasks = true.obs;

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

  // Getters for pagination states
  bool get isLoadingMorePending => _isLoadingMorePending.value;
  bool get hasMorePendingTasks => _hasMorePendingTasks.value;
  bool get isLoadingMoreCompleted => _isLoadingMoreCompleted.value;
  bool get hasMoreCompletedTasks => _hasMoreCompletedTasks.value;

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

  /// Load pending tasks (first page)
  Future<void> loadPendingTasks() async {
    _isLoadingPending.value = true;
    _errorMessage.value = '';
    _pendingCurrentPage.value = 1;
    _hasMorePendingTasks.value = true;

    final result = await getPendingTasksUseCase(
      const GetPendingTasksParams(page: 1, limit: 20),
    );
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
        // If we got less than 20 tasks, there are no more pages
        if (tasks.length < 20) {
          _hasMorePendingTasks.value = false;
        }
      },
    );

    _isLoadingPending.value = false;
  }

  /// Load more pending tasks (next page)
  Future<void> loadMorePendingTasks() async {
    if (_isLoadingMorePending.value || !_hasMorePendingTasks.value) return;

    _isLoadingMorePending.value = true;
    final nextPage = _pendingCurrentPage.value + 1;

    final result = await getPendingTasksUseCase(
      GetPendingTasksParams(page: nextPage, limit: 20),
    );

    result.fold(
      (failure) {
        // Silently fail for loading more
        _isLoadingMorePending.value = false;
      },
      (tasks) {
        if (tasks.isEmpty || tasks.length < 20) {
          _hasMorePendingTasks.value = false;
        }

        if (tasks.isNotEmpty) {
          _pendingTasks.addAll(tasks);
          _pendingCurrentPage.value = nextPage;
        }

        _isLoadingMorePending.value = false;
      },
    );
  }

  /// Load completed tasks (first page)
  Future<void> loadCompletedTasks() async {
    _isLoadingCompleted.value = true;
    _errorMessage.value = '';
    _completedCurrentPage.value = 1;
    _hasMoreCompletedTasks.value = true;

    final result = await getCompletedTasksUseCase(
      const GetCompletedTasksParams(page: 1, limit: 20),
    );
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
        // If we got less than 20 tasks, there are no more pages
        if (tasks.length < 20) {
          _hasMoreCompletedTasks.value = false;
        }
      },
    );

    _isLoadingCompleted.value = false;
  }

  /// Load more completed tasks (next page)
  Future<void> loadMoreCompletedTasks() async {
    if (_isLoadingMoreCompleted.value || !_hasMoreCompletedTasks.value) return;

    _isLoadingMoreCompleted.value = true;
    final nextPage = _completedCurrentPage.value + 1;

    final result = await getCompletedTasksUseCase(
      GetCompletedTasksParams(page: nextPage, limit: 20),
    );

    result.fold(
      (failure) {
        // Silently fail for loading more
        _isLoadingMoreCompleted.value = false;
      },
      (tasks) {
        if (tasks.isEmpty || tasks.length < 20) {
          _hasMoreCompletedTasks.value = false;
        }

        if (tasks.isNotEmpty) {
          _completedTasks.addAll(tasks);
          _completedCurrentPage.value = nextPage;
        }

        _isLoadingMoreCompleted.value = false;
      },
    );
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

        // Filter only completed products by THIS supervisor
        // Only show tasks completed by supervisor, not by admin
        final completed = products
            .where((p) => p.isCompleted && p.completedBySupervisor != null)
            .toList();

        _completedTemporaryProducts.assignAll(completed);
        _isLoadingTemporaryProducts.value = false;
      },
    );
  }

  /// Complete temporary product with unified barcode dialog
  /// Shows a single dialog with barcode input, option to skip, and close button
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

    // If barcode already exists, proceed directly
    if (product.barcode != null && product.barcode!.trim().isNotEmpty) {
      await completeTemporaryProductIntelligent(
        productId,
        notes: notes,
        barcode: product.barcode,
      );
      return;
    }

    // Show unified barcode input dialog
    final barcodeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isScanning = false.obs;

    // Handle barcode scanned
    void handleBarcodeScanned(String barcode) {
      print('📊 [SupervisorController] Barcode scanned: $barcode');
      isScanning.value = false;
      barcodeController.text = barcode;

      Get.snackbar(
        'Código Escaneado',
        'Código de barras: $barcode',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
        icon: Icon(Icons.qr_code_scanner, color: Get.theme.colorScheme.primary),
      );
    }

    final result = await Get.dialog<Map<String, dynamic>>(
      Stack(
        children: [
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.qr_code, color: Get.theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Código de Barras',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(), // Close without completing
                  tooltip: 'Cerrar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producto: "${product.name}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Get.theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Get.theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El código de barras es opcional. Puedes agregarlo ahora o continuar sin él.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Get.theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      // Only validate if user is trying to save
                      if (value != null && value.trim().isNotEmpty) {
                        if (value.trim().length < 8) {
                          return 'El código debe tener al menos 8 dígitos';
                        }
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Get.back(result: {'skip': true}),
                icon: const Icon(Icons.skip_next),
                label: const Text('Omitir y Continuar'),
                style: TextButton.styleFrom(
                  foregroundColor: Get.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final barcodeValue = barcodeController.text.trim();

                  // If field is empty, show error
                  if (barcodeValue.isEmpty) {
                    Get.snackbar(
                      'Campo vacío',
                      'Ingresa un código de barras o presiona "Omitir y Continuar"',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Get.theme.colorScheme.errorContainer,
                      colorText: Get.theme.colorScheme.onErrorContainer,
                      duration: const Duration(seconds: 3),
                      margin: const EdgeInsets.all(16),
                    );
                    return;
                  }

                  // Validate form
                  if (formKey.currentState!.validate()) {
                    Get.back(result: {'barcode': barcodeValue});
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
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

    // Handle result
    if (result != null) {
      if (result['skip'] == true) {
        // User chose to skip or closed dialog
        await completeTemporaryProductIntelligent(productId, notes: notes, barcode: null);
      } else if (result['barcode'] != null) {
        // User entered a barcode
        await completeTemporaryProductIntelligent(
          productId,
          notes: notes,
          barcode: result['barcode'] as String,
        );
      }
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

  /// Update barcode of existing product directly in products table
  /// This is for when admin creates a product WITHOUT barcode (Scenario 2 - Real Products)
  Future<void> updateProductBarcode(
    String temporaryProductId,
    String productId,
    String barcode,
  ) async {
    _isCompletingTemporaryProduct.value = true;

    // Call the new endpoint that updates products table directly
    final result = await _productsRepository.updateProductBarcode(productId, barcode);

    result.fold(
      (failure) {
        Get.snackbar(
          'Error',
          'No se pudo actualizar el código de barras: ${failure.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
        _isCompletingTemporaryProduct.value = false;
      },
      (result) {
        // Remove from pending list
        _pendingTemporaryProducts.removeWhere((p) => p.id == temporaryProductId);

        // We don't need to add to completed list since this was a real product
        // The temporary product is just for notification purposes

        Get.snackbar(
          'Código de Barras Agregado',
          'El código de barras ha sido agregado al producto exitosamente.',
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

  /// Intelligently complete temporary product based on whether it has a productId
  /// - If productId exists → updates existing product's barcode
  /// - If productId is null → creates new product
  Future<void> completeTemporaryProductIntelligent(
    String temporaryProductId, {
    String? notes,
    String? barcode,
  }) async {
    // Get the temporary product to check if it has productId
    final tempProduct = getTemporaryProductById(temporaryProductId);

    if (tempProduct == null) {
      Get.snackbar(
        'Error',
        'Producto temporal no encontrado',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return;
    }

    // Check if this temporary product is linked to a real product
    final hasRealProduct = tempProduct.productId != null && tempProduct.productId!.isNotEmpty;

    if (hasRealProduct) {
      // Scenario 2: Real product (admin created without barcode) → UPDATE existing product
      print('📦 Scenario 2: Updating existing product barcode');

      if (barcode == null || barcode.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'El código de barras es requerido para actualizar el producto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
        return;
      }

      await updateProductBarcode(temporaryProductId, tempProduct.productId!, barcode);
    } else {
      // Scenario 1: Temporary product (from order) → CREATE new product
      print('📦 Scenario 1: Creating new product from temporary');
      await completeTemporaryProduct(temporaryProductId, notes: notes, barcode: barcode);
    }
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
