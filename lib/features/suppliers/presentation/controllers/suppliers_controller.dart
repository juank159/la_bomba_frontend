// lib/features/suppliers/presentation/controllers/suppliers_controller.dart

import 'package:get/get.dart';
import 'dart:async';

import '../../domain/entities/supplier.dart';
import '../../domain/usecases/get_suppliers_usecase.dart';
import '../../domain/usecases/create_supplier_usecase.dart';
import '../../domain/usecases/update_supplier_usecase.dart';
import '../../domain/usecases/delete_supplier_usecase.dart';

/// SuppliersController using GetX for reactive state management
/// Handles suppliers list, search, pagination, and CRUD operations
class SuppliersController extends GetxController {
  final GetSuppliersUseCase getSuppliersUseCase;
  final GetSupplierByIdUseCase getSupplierByIdUseCase;
  final CreateSupplierUseCase createSupplierUseCase;
  final UpdateSupplierUseCase updateSupplierUseCase;
  final DeleteSupplierUseCase deleteSupplierUseCase;

  SuppliersController({
    required this.getSuppliersUseCase,
    required this.getSupplierByIdUseCase,
    required this.createSupplierUseCase,
    required this.updateSupplierUseCase,
    required this.deleteSupplierUseCase,
  });

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxList<Supplier> suppliers = <Supplier>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 0.obs;
  final RxInt totalSuppliers = 0.obs;
  final RxBool hasMoreSuppliers = true.obs;
  final Rx<Supplier?> selectedSupplier = Rx<Supplier?>(null);

  // Constants
  static const int itemsPerPage = 20;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    loadSuppliers();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  /// Load suppliers with optional search and pagination
  Future<void> loadSuppliers({
    bool refresh = false,
    bool loadMore = false,
  }) async {
    try {
      // Set loading states
      if (refresh) {
        isRefreshing.value = true;
        currentPage.value = 0;
        hasMoreSuppliers.value = true;
      } else if (loadMore) {
        if (!hasMoreSuppliers.value || isLoadingMore.value) return;
        isLoadingMore.value = true;
      } else {
        if (isLoading.value) return;
        isLoading.value = true;
        currentPage.value = 0;
        hasMoreSuppliers.value = true;
      }

      // Clear error message
      errorMessage.value = '';

      // Prepare parameters
      final params = GetSuppliersParams(
        page: loadMore ? currentPage.value + 1 : 0,
        limit: itemsPerPage,
        search: searchQuery.value.trim().isNotEmpty
            ? searchQuery.value.trim()
            : null,
      );

      // Execute use case
      final result = await getSuppliersUseCase.call(params);

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        (loadedSuppliers) {
          if (loadMore) {
            suppliers.addAll(loadedSuppliers);
            currentPage.value++;
          } else {
            suppliers.value = loadedSuppliers;
            currentPage.value = 0;
          }

          // Check if there are more suppliers
          hasMoreSuppliers.value = loadedSuppliers.length >= itemsPerPage;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Search suppliers with debounce
  void searchSuppliers(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = query;
      loadSuppliers();
    });
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    loadSuppliers();
  }

  /// Get supplier by ID
  Future<void> getSupplierById(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final params = GetSupplierByIdParams(id: id);
      final result = await getSupplierByIdUseCase.call(params);

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        (supplier) {
          selectedSupplier.value = supplier;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new supplier
  Future<bool> createSupplier({
    required String nombre,
    String? celular,
    String? email,
    String? direccion,
  }) async {
    try {
      isCreating.value = true;
      errorMessage.value = '';

      final params = CreateSupplierParams(
        nombre: nombre,
        celular: celular,
        email: email,
        direccion: direccion,
      );

      final result = await createSupplierUseCase.call(params);

      return result.fold(
        (failure) {
          print('🔴 Controller: Supplier creation failed: ${failure.message}');
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (supplier) {
          print('🟢 Controller: Supplier created successfully: ${supplier.nombre}');
          // Refresh list
          loadSuppliers(refresh: true);
          print('🟢 Controller: Returning true');
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  /// Update an existing supplier
  Future<bool> updateSupplier({
    required String id,
    String? nombre,
    String? celular,
    String? email,
    String? direccion,
    bool? isActive,
  }) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';

      final params = UpdateSupplierParams(
        id: id,
        nombre: nombre,
        celular: celular,
        email: email,
        direccion: direccion,
        isActive: isActive,
      );

      final result = await updateSupplierUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (supplier) {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Éxito',
              'Proveedor actualizado exitosamente',
              snackPosition: SnackPosition.TOP,
            );
          }
          // Update selected supplier if it's the same
          if (selectedSupplier.value?.id == supplier.id) {
            selectedSupplier.value = supplier;
          }
          // Refresh list
          loadSuppliers(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Delete a supplier (soft delete)
  Future<bool> deleteSupplier(String id) async {
    try {
      isDeleting.value = true;
      errorMessage.value = '';

      final params = DeleteSupplierParams(id: id);
      final result = await deleteSupplierUseCase.call(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              failure.message,
              snackPosition: SnackPosition.TOP,
            );
          }
          return false;
        },
        (_) {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Éxito',
              'Proveedor eliminado exitosamente',
              snackPosition: SnackPosition.TOP,
            );
          }
          // Clear selected supplier if it's the deleted one
          if (selectedSupplier.value?.id == id) {
            selectedSupplier.value = null;
          }
          // Refresh list
          loadSuppliers(refresh: true);
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      if (Get.isSnackbarOpen == false) {
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
        );
      }
      return false;
    } finally {
      isDeleting.value = false;
    }
  }

  /// Refresh suppliers list
  Future<void> refreshSuppliers() async {
    await loadSuppliers(refresh: true);
  }

  /// Load more suppliers (pagination)
  Future<void> loadMoreSuppliers() async {
    await loadSuppliers(loadMore: true);
  }

  /// Get suppliers count
  Future<void> getSuppliersCount() async {
    try {
      final result = await getSuppliersUseCase.getCount(
        searchQuery.value.trim().isNotEmpty ? searchQuery.value.trim() : null,
      );

      result.fold(
        (failure) {
          // Silently fail for count
        },
        (count) {
          totalSuppliers.value = count;
        },
      );
    } catch (e) {
      // Silently fail for count
    }
  }

  /// Clear selected supplier data
  void clearSelectedSupplier() {
    selectedSupplier.value = null;
  }
}
