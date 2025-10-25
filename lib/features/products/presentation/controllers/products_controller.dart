// lib/features/products/presentation/controllers/products_controller.dart
import 'package:get/get.dart';
import 'dart:async';

import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';

/// ProductsController using GetX for reactive state management
/// Handles products list, search, pagination, and individual product operations
class ProductsController extends GetxController {
  final GetProductsUseCase getProductsUseCase;
  final GetProductByIdUseCase getProductByIdUseCase;
  final UpdateProductUseCase updateProductUseCase;

  ProductsController({
    required this.getProductsUseCase,
    required this.getProductByIdUseCase,
    required this.updateProductUseCase,
  });

  // Reactive variables
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isUpdating = false.obs;
  final RxList<Product> products = <Product>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 0.obs;
  final RxInt totalProducts = 0.obs;
  final RxBool hasMoreProducts = true.obs;
  final Rx<Product?> selectedProduct = Rx<Product?>(null);

  // Constants
  static const int itemsPerPage = 20;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  /// Load products with optional search and pagination
  Future<void> loadProducts({
    bool refresh = false,
    bool loadMore = false,
  }) async {
    try {
      // Set loading states
      if (refresh) {
        isRefreshing.value = true;
        currentPage.value = 0;
        hasMoreProducts.value = true;
      } else if (loadMore) {
        if (!hasMoreProducts.value || isLoadingMore.value) return;
        isLoadingMore.value = true;
      } else {
        if (isLoading.value) return;
        isLoading.value = true;
        currentPage.value = 0;
        hasMoreProducts.value = true;
      }

      // Clear error message
      errorMessage.value = '';

      // Prepare parameters
      final params = GetProductsParams(
        page: loadMore ? currentPage.value + 1 : 0,
        limit: itemsPerPage,
        search: searchQuery.value.trim().isNotEmpty
            ? searchQuery.value.trim()
            : null,
      );

      // Execute use case
      final result = await getProductsUseCase(params);

      result.fold(
        (failure) {
          errorMessage.value = failure.message;

          // Reset loading states
          isLoading.value = false;
          isLoadingMore.value = false;
          isRefreshing.value = false;

          // Show error snackbar
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
            colorText: Get.theme.colorScheme.error,
          );
        },
        (newProducts) {
          if (refresh || (!loadMore && currentPage.value == 0)) {
            // Replace products for refresh or initial load
            products.assignAll(newProducts);
          } else if (loadMore) {
            // Append products for load more
            products.addAll(newProducts);
            currentPage.value++;
          }

          // Check if there are more products to load
          hasMoreProducts.value = newProducts.length == itemsPerPage;

          // Reset loading states
          isLoading.value = false;
          isLoadingMore.value = false;
          isRefreshing.value = false;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      isLoading.value = false;
      isLoadingMore.value = false;
      isRefreshing.value = false;
    }
  }

  /// Search products with debouncing
  Future<void> searchProducts(String query) async {
    // Cancel previous search timer
    _searchDebounce?.cancel();

    // Update search query immediately for UI responsiveness
    searchQuery.value = query;

    // Debounce search to avoid too many API calls
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim() != searchQuery.value.trim()) return;

      // Reset pagination and load products
      currentPage.value = 0;
      loadProducts();
    });
  }

  /// Clear search and reload all products
  Future<void> clearSearch() async {
    searchQuery.value = '';
    currentPage.value = 0;
    await loadProducts();
  }

  /// Refresh products (pull-to-refresh)
  Future<void> refreshProducts() async {
    await loadProducts(refresh: true);
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    await loadProducts(loadMore: true);
  }

  /// Get product by ID
  Future<void> getProductById(String productId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final params = GetProductByIdParams(id: productId);
      final result = await getProductByIdUseCase(params);

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          selectedProduct.value = null;

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
            colorText: Get.theme.colorScheme.error,
          );
        },
        (product) {
          selectedProduct.value = product;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      selectedProduct.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Clear selected product
  void clearSelectedProduct() {
    selectedProduct.value = null;
  }

  /// Get filtered products based on local search
  List<Product> getFilteredProducts(String localFilter) {
    if (localFilter.trim().isEmpty) {
      return products;
    }

    final filter = localFilter.toLowerCase().trim();
    return products.where((product) {
      return product.description.toLowerCase().contains(filter) ||
          product.barcode.toLowerCase().contains(filter);
    }).toList();
  }

  /// Check if products list is empty and not loading
  bool get isEmpty => products.isEmpty && !isLoading.value;

  /// Check if should show empty state
  bool get showEmptyState => isEmpty && errorMessage.value.isEmpty;

  /// Check if should show error state
  bool get showErrorState => errorMessage.value.isNotEmpty && products.isEmpty;

  /// Get current search status text
  String get searchStatusText {
    if (searchQuery.value.trim().isEmpty) {
      return 'Mostrando ${products.length} productos';
    } else {
      return 'Encontrados ${products.length} productos para "${searchQuery.value}"';
    }
  }

  /// Toggle product active status (for future implementation)
  Future<void> toggleProductStatus(String productId) async {
    // TODO: Implement when backend supports updating product status
    // This would require a new use case and repository method
    Get.snackbar(
      'Información',
      'Función no disponible aún',
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Get product by barcode (for future barcode scanning implementation)
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final matchingProducts = products
          .where((product) => product.barcode == barcode)
          .toList();

      if (matchingProducts.isNotEmpty) {
        return matchingProducts.first;
      }

      // If not found in local list, search remotely
      await searchProducts(barcode);

      final searchResults = products
          .where((product) => product.barcode == barcode)
          .toList();

      return searchResults.isNotEmpty ? searchResults.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Export products data (for future implementation)
  Future<void> exportProducts() async {
    // TODO: Implement export functionality
    Get.snackbar(
      'Información',
      'Función de exportación no disponible aún',
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Update product information
  Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      isUpdating.value = true;
      errorMessage.value = '';

      print('🔍 CONTROLLER: updateProduct called with:');
      print('🔍 CONTROLLER: productId: $productId');
      print('🔍 CONTROLLER: updatedData: $updatedData');

      final params = UpdateProductParams(
        id: productId,
        updatedData: updatedData,
      );

      final result = await updateProductUseCase(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
            colorText: Get.theme.colorScheme.error,
            duration: const Duration(seconds: 3),
          );

          return false;
        },
        (updatedProduct) {
          print('🔍 CONTROLLER: Update successful, received product:');
          print('🔍 CONTROLLER: Product ID: ${updatedProduct.id}');
          print('🔍 CONTROLLER: Product IVA: ${updatedProduct.iva}');
          print(
            '🔍 CONTROLLER: Product description: ${updatedProduct.description}',
          );

          // Update the product in the local list
          final index = products.indexWhere((p) => p.id == productId);
          if (index != -1) {
            print(
              '🔍 CONTROLLER: Updating product in local list at index $index',
            );
            products[index] = updatedProduct;
          }

          // Update selected product if it's the same
          if (selectedProduct.value?.id == productId) {
            print('🔍 CONTROLLER: Updating selected product');
            selectedProduct.value = updatedProduct;
          }

          Get.snackbar(
            'Éxito',
            'Producto actualizado correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
            colorText: Get.theme.colorScheme.primary,
            duration: const Duration(seconds: 2),
          );

          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';

      Get.snackbar(
        'Error',
        'Error inesperado al actualizar producto',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );

      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Update specific price of a product
  Future<bool> updateProductPrice(
    String productId,
    String priceType,
    double price,
  ) async {
    print(
      '🔧 UpdateProductPrice: ID=$productId, Type=$priceType, Price=$price',
    );
    final Map<String, dynamic> updatedData = {priceType: price};
    print('🔧 UpdateData: $updatedData');
    return await updateProduct(productId, updatedData);
  }
}
