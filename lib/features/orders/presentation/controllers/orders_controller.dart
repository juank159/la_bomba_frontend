// lib features/orders/presentation/controllers/orders_controller.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidos_frontend/features/orders/domain/usecases/get_orders_usecase.dart'
    as get_order_by_id;
import 'dart:async';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../app/core/services/pdf_service.dart';

import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/services/text_to_speech_service.dart';
import '../../domain/entities/order.dart' as order_entity;
import '../../domain/entities/order_item.dart';
import '../../domain/usecases/get_orders_usecase.dart';

import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/update_order_usecase.dart';
import '../../domain/usecases/delete_order_usecase.dart';
import '../../domain/usecases/update_quantities_usecase.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../suppliers/domain/usecases/get_suppliers_usecase.dart';

/// OrdersController using GetX for reactive state management
/// Handles orders list, search, pagination, CRUD operations, and product management
class OrdersController extends GetxController {
  final GetOrdersUseCase getOrdersUseCase;
  final get_order_by_id.GetOrderByIdUseCase getOrderByIdUseCase;
  final CreateOrderUseCase createOrderUseCase;
  final UpdateOrderUseCase updateOrderUseCase;
  final DeleteOrderUseCase deleteOrderUseCase;
  final UpdateQuantitiesUseCase updateQuantitiesUseCase;
  final GetProductsUseCase getProductsUseCase;
  final GetSuppliersUseCase getSuppliersUseCase;

  OrdersController({
    required this.getOrdersUseCase,
    required this.getOrderByIdUseCase,
    required this.createOrderUseCase,
    required this.updateOrderUseCase,
    required this.deleteOrderUseCase,
    required this.updateQuantitiesUseCase,
    required this.getProductsUseCase,
    required this.getSuppliersUseCase,
  });

  // Reactive variables for orders list
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxList<order_entity.Order> orders = <order_entity.Order>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt currentPage = 0.obs;
  final RxInt totalOrders = 0.obs;
  final RxBool hasMoreOrders = true.obs;
  final Rx<order_entity.Order?> selectedOrder = Rx<order_entity.Order?>(null);
  final RxString statusFilter =
      ''.obs; // 'pending', 'completed', or empty for all

  // Order counts for filters (always showing real totals)
  final RxInt totalOrdersCount = 0.obs;
  final RxInt realPendingOrdersCount = 0.obs;
  final RxInt realCompletedOrdersCount = 0.obs;

  // Reactive variables for order creation/editing
  final RxBool isCreatingOrder = false.obs;
  final RxBool isUpdatingOrder = false.obs;
  final RxBool isDeletingOrder = false.obs;
  final RxBool isUpdatingQuantities = false.obs;
  final RxList<OrderItem> newOrderItems = <OrderItem>[].obs;
  final RxString newOrderDescription = ''.obs;
  final RxString newOrderProvider = ''.obs; // Deprecated: usar newOrderSupplierId
  final Rx<String?> newOrderSupplierId = Rx<String?>(null);

  // Reactive variables for suppliers
  final RxBool isLoadingSuppliers = false.obs;
  final RxList<Supplier> suppliers = <Supplier>[].obs;

  // Reactive variables for product search and barcode scanning
  final RxBool isSearchingProducts = false.obs;
  final RxList<Product> availableProducts = <Product>[].obs;
  final RxString productSearchQuery = ''.obs;
  final RxBool isScanningBarcode = false.obs;

  // Constants
  static const int itemsPerPage = 20;
  Timer? _searchDebounce;
  Timer? _productSearchDebounce;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
    loadOrdersStatistics();
    loadSuppliers();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _productSearchDebounce?.cancel();
    super.onClose();
  }

  /// Load orders with optional search, status filter, and pagination
  Future<void> loadOrders({bool refresh = false, bool loadMore = false}) async {
    try {
      // Set loading states
      if (refresh) {
        isRefreshing.value = true;
        currentPage.value = 0;
        hasMoreOrders.value = true;
      } else if (loadMore) {
        if (!hasMoreOrders.value || isLoadingMore.value) return;
        isLoadingMore.value = true;
      } else {
        if (isLoading.value) return;
        isLoading.value = true;
        currentPage.value = 0;
        hasMoreOrders.value = true;
      }

      // Clear error message
      errorMessage.value = '';

      // Prepare parameters
      final params = GetOrdersParams(
        page: loadMore ? currentPage.value + 1 : 0,
        limit: itemsPerPage,
        search: searchQuery.value.trim().isNotEmpty
            ? searchQuery.value.trim()
            : null,
        status: statusFilter.value.trim().isNotEmpty
            ? statusFilter.value.trim()
            : null,
      );

      // Execute use case
      final result = await getOrdersUseCase(params);

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
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
        },
        (newOrders) {
          // Client-side filtering as backup validation
          List<order_entity.Order> filteredOrders = newOrders;

          if (statusFilter.value.trim().isNotEmpty) {
            final filterStatus = statusFilter.value.trim();
            filteredOrders = newOrders.where((order) {
              return order.status.value == filterStatus;
            }).toList();
          }

          if (refresh || (!loadMore && currentPage.value == 0)) {
            // Replace orders for refresh or initial load
            orders.assignAll(filteredOrders);
          } else if (loadMore) {
            // Append orders for load more
            orders.addAll(filteredOrders);
            currentPage.value++;
          }

          // Check if there are more orders to load
          hasMoreOrders.value = newOrders.length == itemsPerPage;

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

  /// Load orders statistics for filter counters
  Future<void> loadOrdersStatistics() async {
    try {
      // Load all orders count
      final allOrdersResult = await getOrdersUseCase(
        GetOrdersParams(page: 0, limit: 1),
      );

      // Load pending orders count
      final pendingOrdersResult = await getOrdersUseCase(
        GetOrdersParams(page: 0, limit: 1, status: 'pending'),
      );

      // Load completed orders count
      final completedOrdersResult = await getOrdersUseCase(
        GetOrdersParams(page: 0, limit: 1, status: 'completed'),
      );

      allOrdersResult.fold(
        (failure) =>
            print('Error loading all orders stats: ${failure.message}'),
        (orders) {
          // For statistics, we need to make additional calls to get total counts
          // The backend should return total count in metadata
          _loadAllOrdersCounts();
        },
      );
    } catch (e) {
      print('Error loading orders statistics: $e');
    }
  }

  /// Load actual counts for all order types
  Future<void> _loadAllOrdersCounts() async {
    try {
      // Load all orders to count them
      final allResult = await getOrdersUseCase(
        GetOrdersParams(page: 0, limit: 1000), // Large limit to get all
      );

      allResult.fold(
        (failure) => print('Error loading all orders: ${failure.message}'),
        (allOrders) {
          totalOrdersCount.value = allOrders.length;
          realPendingOrdersCount.value = allOrders
              .where(
                (order) => order.status == order_entity.OrderStatus.pending,
              )
              .length;
          realCompletedOrdersCount.value = allOrders
              .where(
                (order) => order.status == order_entity.OrderStatus.completed,
              )
              .length;
        },
      );
    } catch (e) {
      print('Error loading order counts: $e');
    }
  }

  /// Search orders with debouncing
  Future<void> searchOrders(String query) async {
    // Cancel previous search timer
    _searchDebounce?.cancel();

    // Update search query immediately for UI responsiveness
    searchQuery.value = query;

    // Debounce search to avoid too many API calls
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim() != searchQuery.value.trim()) return;

      // Reset pagination and load orders
      currentPage.value = 0;
      loadOrders();
    });
  }

  /// Filter orders by status
  Future<void> filterByStatus(String status) async {
    // Clear current orders first to prevent showing old data
    orders.clear();

    statusFilter.value = status;
    currentPage.value = 0;
    hasMoreOrders.value = true;

    // Force fresh load
    await loadOrders(refresh: true);

    // Update statistics to ensure counts are current
    loadOrdersStatistics();
  }

  /// Clear search and status filter
  Future<void> clearFilters() async {
    searchQuery.value = '';
    statusFilter.value = '';
    currentPage.value = 0;
    orders.clear();
    await loadOrders(refresh: true);
  }

  /// Refresh orders (pull-to-refresh)
  Future<void> refreshOrders() async {
    await loadOrders(refresh: true);
    // Also refresh statistics
    loadOrdersStatistics();
  }

  /// Load more orders (pagination)
  Future<void> loadMoreOrders() async {
    await loadOrders(loadMore: true);
  }

  /// Get order by ID and set as selected
  Future<void> getOrderById(String orderId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await getOrderByIdUseCase(
        get_order_by_id.GetOrderByIdParams(id: orderId),
      );

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          selectedOrder.value = null;

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
        },
        (order) {
          selectedOrder.value = order;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      selectedOrder.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a new order
  Future<bool> createOrder({
    required String description,
    String? provider,
    required List<OrderItem> items,
  }) async {
    try {
      isCreatingOrder.value = true;
      errorMessage.value = '';

      final params = CreateOrderParams(
        description: description,
        provider: provider,
        items: items
            .map(
              (item) => CreateOrderItemParams(
                productId: item.productId,
                temporaryProductId: item.temporaryProductId,
                supplierId: item.supplierId,
                existingQuantity: item.existingQuantity,
                requestedQuantity: item.requestedQuantity,
                measurementUnit: item.measurementUnit.value,
              ),
            )
            .toList(),
      );

      final result = await createOrderUseCase(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return false;
        },
        (order) {
          // Add new order to the top of the list
          orders.insert(0, order);

          // Clear new order data
          clearNewOrderData();

          Get.snackbar(
            'Éxito',
            'Pedido creado exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary.withValues(
              alpha: 0.1,
            ),
            colorText: Get.theme.colorScheme.primary,
          );
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      isCreatingOrder.value = false;
    }
  }

  /// Update an existing order
  Future<bool> updateOrder({
    required String id,
    String? description,
    String? provider,
    String? status,
  }) async {
    try {
      isUpdatingOrder.value = true;
      errorMessage.value = '';

      final params = UpdateOrderParams(
        id: id,
        description: description,
        provider: provider,
        status: status,
      );

      final result = await updateOrderUseCase(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return false;
        },
        (updatedOrder) {
          // Update order in the list
          final index = orders.indexWhere((order) => order.id == id);
          if (index != -1) {
            orders[index] = updatedOrder;
          }

          // Update selected order if it matches
          if (selectedOrder.value?.id == id) {
            selectedOrder.value = updatedOrder;
          }

          Get.snackbar(
            'Éxito',
            'Pedido actualizado exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary.withValues(
              alpha: 0.1,
            ),
            colorText: Get.theme.colorScheme.primary,
          );
          return true;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      isUpdatingOrder.value = false;
    }
  }

  /// Delete an order
  Future<bool> deleteOrder(String id) async {
    try {
      isDeletingOrder.value = true;
      errorMessage.value = '';

      final params = DeleteOrderParams(id: id);
      final result = await deleteOrderUseCase(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return false;
        },
        (success) {
          if (success) {
            // Remove order from the list
            orders.removeWhere((order) => order.id == id);

            // Clear selected order if it matches
            if (selectedOrder.value?.id == id) {
              selectedOrder.value = null;
            }

            Get.snackbar(
              'Éxito',
              'Pedido eliminado exitosamente',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Get.theme.colorScheme.primary.withValues(
                alpha: 0.1,
              ),
              colorText: Get.theme.colorScheme.primary,
            );
          }
          return success;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      isDeletingOrder.value = false;
    }
  }

  /// Update requested quantities for order items (admin only)
  Future<bool> updateRequestedQuantities(List<UpdateQuantityItem> items) async {
    try {
      isUpdatingQuantities.value = true;
      errorMessage.value = '';

      final params = UpdateQuantitiesParams(items: items);
      final result = await updateQuantitiesUseCase(params);

      return result.fold(
        (failure) {
          errorMessage.value = failure.message;

          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return false;
        },
        (success) {
          if (success) {
            // Refresh the current order to get updated quantities
            if (selectedOrder.value != null) {
              getOrderById(selectedOrder.value!.id);
            }

            Get.snackbar(
              'Éxito',
              'Cantidades actualizadas exitosamente',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Get.theme.colorScheme.primary.withValues(
                alpha: 0.1,
              ),
              colorText: Get.theme.colorScheme.primary,
            );
          }
          return success;
        },
      );
    } catch (e) {
      errorMessage.value = 'Error inesperado: ${e.toString()}';
      return false;
    } finally {
      isUpdatingQuantities.value = false;
    }
  }

  /// Search products for adding to order (with barcode scanning support)
  Future<void> searchProducts(String query) async {
    // Cancel previous search timer
    _productSearchDebounce?.cancel();

    // Update search query immediately for UI responsiveness
    productSearchQuery.value = query;

    // Debounce search to avoid too many API calls
    _productSearchDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.trim() != productSearchQuery.value.trim()) return;

      try {
        isSearchingProducts.value = true;

        final searchQuery = query.trim().isNotEmpty ? query.trim() : null;
        print(
          '🔍 [OrdersController] Creating search params with query: "$searchQuery"',
        );

        final params = GetProductsParams(
          page: 0,
          limit: 50, // Get more results for selection
          search: searchQuery,
        );

        print('🔍 [OrdersController] Search params: $params');
        final result = await getProductsUseCase(params);

        result.fold(
          (failure) {
            availableProducts.clear();
          },
          (products) {
            availableProducts.assignAll(products);
          },
        );
      } catch (e) {
        availableProducts.clear();
      } finally {
        isSearchingProducts.value = false;
      }
    });
  }

  /// Handle barcode scan result
  Future<void> handleBarcodeScanned(String barcode) async {
    print('🔍 [OrdersController] Barcode scanned: $barcode');
    isScanningBarcode.value = false;

    if (barcode.trim().isNotEmpty) {
      // Search for product by barcode using direct API call
      print(
        '🔍 [OrdersController] Searching for product with barcode: ${barcode.trim()}',
      );

      try {
        isSearchingProducts.value = true;

        final params = GetProductsParams(
          page: 0,
          limit: 50,
          search: barcode.trim(),
        );

        print('🔍 [OrdersController] Search params for barcode: $params');
        final result = await getProductsUseCase(params);

        result.fold(
          (failure) {
            print('🔍 [OrdersController] Search failed: ${failure.message}');
            availableProducts.clear();

            // No product found due to error
            Get.snackbar(
              'Error de búsqueda',
              'Error al buscar el producto: ${failure.message}',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
              colorText: Get.theme.colorScheme.error,
            );
          },
          (products) {
            print(
              '🔍 [OrdersController] Search successful: Found ${products.length} products',
            );
            availableProducts.assignAll(products);

            // Process results
            _processBarcodeSearchResults(products, barcode);
          },
        );
      } catch (e) {
        print('🔍 [OrdersController] Search exception: $e');
        availableProducts.clear();

        Get.snackbar(
          'Error inesperado',
          'Error al buscar el producto: $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      } finally {
        isSearchingProducts.value = false;
      }
    } else {
      print('🔍 [OrdersController] Empty barcode scanned');
    }
  }

  /// Process the results of barcode search
  void _processBarcodeSearchResults(List<Product> products, String barcode) {
    if (products.length == 1) {
      final product = products.first;
      print(
        '🔍 [OrdersController] Single product found: ${product.description}',
      );
      productSearchQuery.value = product.description;

      if (product.isActive) {
        // Directly add the scanned product to the order
        print('🔍 [OrdersController] Adding scanned product to order');
        _showQuantityDialogForScannedProduct(product);
      } else {
        print('🔍 [OrdersController] Product is inactive');
        Get.snackbar(
          'Producto Inactivo',
          'El producto escaneado no está disponible para pedidos',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
        // Speak that product is not available
        getIt<TextToSpeechService>().speak("Producto no disponible");
      }
    } else if (products.isEmpty) {
      // No product found
      print('🔍 [OrdersController] No product found for barcode: $barcode');
      Get.snackbar(
        'Producto no encontrado',
        'No se encontró ningún producto con ese código de barras',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
      // Speak that product was not found
      getIt<TextToSpeechService>().speakProductNotFound();
    } else {
      // Multiple products found, show selection sheet
      print(
        '🔍 [OrdersController] Multiple products found (${products.length}), showing selection sheet',
      );
      _showProductSelectionFromScan();
    }
  }

  /// Show quantity dialog for scanned product
  void _showQuantityDialogForScannedProduct(Product product) {
    // Close any open dialogs or bottom sheets first
    closeOpenDialogs();

    // Directly add the scanned product to the order with default values
    addProductToOrder(
      product,
      existingQuantity: 0, // Default existing quantity (producto nuevo, no hay stock)
      requestedQuantity: null, // No requested quantity by default
      measurementUnit: MeasurementUnit.unidad, // Default unit
    );

    // Show success feedback for scanned product
    Get.snackbar(
      'Producto Escaneado',
      '${product.description} agregado al pedido',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
      colorText: Get.theme.colorScheme.primary,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show product selection sheet for multiple products found from scan
  void _showProductSelectionFromScan() {
    // This will be called from the UI layer
    onMultipleProductsFromScan?.call();
  }

  /// Close any open dialogs or sheets
  void closeOpenDialogs() {
    print('🔍 [OrdersController] Closing open dialogs');
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
  }

  // Callbacks for UI interaction from scanning
  Function(Product)? onScannedProductFound;
  VoidCallback? onMultipleProductsFromScan;

  /// Add product to new order items
  void addProductToOrder(
    Product product, {
    required int existingQuantity,
    int? requestedQuantity,
    required MeasurementUnit measurementUnit,
    String? supplierId,
  }) {
    print(
      '🔍 [OrdersController] Adding product to order: ${product.description}',
    );
    print('🔍 [OrdersController] Existing quantity: $existingQuantity');
    print('🔍 [OrdersController] Requested quantity: $requestedQuantity');
    print(
      '🔍 [OrdersController] Measurement unit: ${measurementUnit.displayName}',
    );

    // Check if product already exists in order
    final existingItemIndex = newOrderItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingItemIndex != -1) {
      // Update existing item and move to top
      print(
        '🔍 [OrdersController] Updating existing item at index: $existingItemIndex',
      );
      final existingItem = newOrderItems[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        existingQuantity: existingQuantity,
        requestedQuantity: requestedQuantity,
        measurementUnit: measurementUnit,
      );
      // Remove from current position and add to top
      newOrderItems.removeAt(existingItemIndex);
      newOrderItems.insert(0, updatedItem);
    } else {
      // Add new item to top of list
      print('🔍 [OrdersController] Adding new item to top of order list');
      final newItem = OrderItem(
        id: '', // Will be set by backend
        orderId: '', // Will be set by backend
        productId: product.id,
        product: product,
        supplierId: supplierId,
        existingQuantity: existingQuantity,
        requestedQuantity: requestedQuantity,
        measurementUnit: measurementUnit,
      );
      newOrderItems.insert(0, newItem);
      print(
        '🔍 [OrdersController] New order items count: ${newOrderItems.length}',
      );
    }

    // Force update UI
    newOrderItems.refresh();
    print(
      '🔍 [OrdersController] Order items after refresh: ${newOrderItems.length}',
    );
  }

  /// Remove product from new order items
  void removeProductFromOrder(String productId) {
    newOrderItems.removeWhere((item) => item.productId == productId);
  }

  /// Update order item quantities
  void updateOrderItemQuantities(
    String itemId, {
    int? existingQuantity,
    int? requestedQuantity,
  }) {
    final index = newOrderItems.indexWhere((item) => item.productId == itemId);
    if (index != -1) {
      final item = newOrderItems[index];
      final updatedItem = item.copyWith(
        existingQuantity: existingQuantity ?? item.existingQuantity,
        requestedQuantity: requestedQuantity,
      );
      newOrderItems[index] = updatedItem;
      newOrderItems.refresh();
    }
  }

  /// Update order item measurement unit
  void updateOrderItemMeasurementUnit(String itemId, MeasurementUnit unit) {
    final index = newOrderItems.indexWhere((item) => item.productId == itemId);
    if (index != -1) {
      final item = newOrderItems[index];
      final updatedItem = item.copyWith(measurementUnit: unit);
      newOrderItems[index] = updatedItem;
      newOrderItems.refresh();
      print(
        '🔧 [OrdersController] Updated measurement unit for ${item.productDescription}: ${unit.displayName}',
      );
    }
  }

  /// Update order item supplier (ADMIN only)
  void updateOrderItemSupplier(String itemId, String? supplierId) {
    final index = newOrderItems.indexWhere((item) => item.productId == itemId);
    if (index != -1) {
      final item = newOrderItems[index];
      final updatedItem = item.copyWith(supplierId: supplierId);
      newOrderItems[index] = updatedItem;
      newOrderItems.refresh();
      print(
        '🔧 [OrdersController] Updated supplier for ${item.productDescription}: ${supplierId ?? "Sin asignar"}',
      );
    }
  }

  /// Clear new order data
  void clearNewOrderData() {
    newOrderItems.clear();
    newOrderDescription.value = '';
    newOrderProvider.value = '';
    newOrderSupplierId.value = null;
    availableProducts.clear();
    productSearchQuery.value = '';
  }

  /// Clear selected order
  void clearSelectedOrder() {
    selectedOrder.value = null;
  }

  /// Load suppliers for dropdown selection
  Future<void> loadSuppliers() async {
    try {
      isLoadingSuppliers.value = true;

      final params = GetSuppliersParams(
        page: 0,
        limit: 100, // Load first 100 suppliers
      );

      final result = await getSuppliersUseCase.call(params);

      result.fold(
        (failure) {
          print('⚠️ [OrdersController] Failed to load suppliers: ${failure.message}');
        },
        (loadedSuppliers) {
          suppliers.assignAll(loadedSuppliers);
          print('✅ [OrdersController] Loaded ${suppliers.length} suppliers');
        },
      );
    } catch (e) {
      print('❌ [OrdersController] Error loading suppliers: ${e.toString()}');
    } finally {
      isLoadingSuppliers.value = false;
    }
  }

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Check if orders list is empty and not loading
  bool get isOrdersEmpty => orders.isEmpty && !isLoading.value;

  /// Check if should show empty state
  bool get showEmptyState => isOrdersEmpty && errorMessage.value.isEmpty;

  /// Check if should show error state
  bool get showErrorState => errorMessage.value.isNotEmpty && orders.isEmpty;

  /// Get current search/filter status text
  String get statusText {
    if (searchQuery.value.trim().isNotEmpty &&
        statusFilter.value.trim().isNotEmpty) {
      final statusName = statusFilter.value == 'pending'
          ? 'pendientes'
          : 'completados';
      return 'Encontrados ${orders.length} pedidos $statusName para "${searchQuery.value}"';
    } else if (searchQuery.value.trim().isNotEmpty) {
      return 'Encontrados ${orders.length} pedidos para "${searchQuery.value}"';
    } else if (statusFilter.value.trim().isNotEmpty) {
      final statusName = statusFilter.value == 'pending'
          ? 'pendientes'
          : 'completados';
      return 'Mostrando ${orders.length} pedidos $statusName';
    } else {
      return 'Mostrando ${orders.length} pedidos';
    }
  }

  /// Get orders grouped by status for display
  Map<String, List<order_entity.Order>> get ordersGroupedByStatus {
    final Map<String, List<order_entity.Order>> grouped = {
      'pending': [],
      'completed': [],
    };

    for (final order in orders) {
      grouped[order.status.value]?.add(order);
    }

    return grouped;
  }

  /// Get pending orders count (from real statistics)
  int get pendingOrdersCount {
    return realPendingOrdersCount.value;
  }

  /// Get completed orders count (from real statistics)
  int get completedOrdersCount {
    return realCompletedOrdersCount.value;
  }

  /// Get total orders count (from real statistics)
  int get allOrdersCount {
    return totalOrdersCount.value;
  }

  /// Start barcode scanning
  void startBarcodeScanning() {
    isScanningBarcode.value = true;
  }

  /// Stop barcode scanning
  void stopBarcodeScanning() {
    isScanningBarcode.value = false;
  }

  /// Check if user can perform admin actions
  bool canPerformAdminActions() {
    try {
      // Get the auth controller instance to check user role
      final authController = Get.find<AuthController>();
      return authController.isAdmin;
    } catch (e) {
      // If AuthController is not available, default to false for security
      print(
        '🔒 [OrdersController] AuthController not found, denying admin access: $e',
      );
      return false;
    }
  }

  /// Get filtered orders based on local search
  List<order_entity.Order> getFilteredOrders(String localFilter) {
    if (localFilter.trim().isEmpty) {
      return orders;
    }

    final filter = localFilter.toLowerCase().trim();
    return orders.where((order) {
      return order.description.toLowerCase().contains(filter) ||
          (order.provider?.toLowerCase().contains(filter) ?? false);
    }).toList();
  }

  /// Check if orders list is empty and not loading
  bool get isEmpty => orders.isEmpty && !isLoading.value;

  /// Get current search status text
  String get searchStatusText {
    if (searchQuery.value.trim().isEmpty) {
      return 'Mostrando ${orders.length} pedidos';
    } else {
      return 'Encontrados ${orders.length} pedidos para "${searchQuery.value}"';
    }
  }

  /// Clear search and reload all orders
  Future<void> clearSearch() async {
    searchQuery.value = '';
    currentPage.value = 0;
    await loadOrders();
  }

  /// Toggle order status (for future implementation)
  Future<void> toggleOrderStatus(String orderId) async {
    // TODO: Implement when needed
    Get.snackbar(
      'Información',
      'Función no disponible aún',
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Export orders data (for future implementation)
  Future<void> exportOrders() async {
    // TODO: Implement export functionality
    Get.snackbar(
      'Información',
      'Función de exportación no disponible aún',
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Complete a pending order (admin only)
  Future<bool> completeOrder(String orderId) async {
    // Check admin permissions
    if (!canPerformAdminActions()) {
      Get.snackbar(
        'Acceso denegado',
        'Solo los administradores pueden completar pedidos',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return false;
    }

    try {
      final success = await updateOrder(id: orderId, status: 'completed');

      if (success) {
        Get.snackbar(
          'Éxito',
          'Pedido completado exitosamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.primary,
        );
      }

      return success;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al completar el pedido: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return false;
    }
  }

  /// Share order as PDF (admin only)
  Future<void> shareOrderPdf(order_entity.Order order) async {
    // Check admin permissions
    if (!canPerformAdminActions()) {
      Get.snackbar(
        'Acceso denegado',
        'Solo los administradores pueden compartir PDFs',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return;
    }

    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Generate and share PDF (single or multiple based on supplier)
      final pdfService = getIt<PdfService>();
      await pdfService.shareOrderPdfSmart(order);

      // Close loading dialog
      Get.back();

      Get.snackbar(
        'Éxito',
        order.hasProvider
            ? 'PDF compartido exitosamente'
            : 'PDFs por proveedor compartidos exitosamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Error al compartir PDF: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    }
  }

  /// Add product to existing order (for edit page)
  Future<bool> addProductToExistingOrder(
    String orderId,
    String? productId,
    int existingQuantity,
    int? requestedQuantity,
    String measurementUnit, {
    String? temporaryProductId,
    String? supplierId,
  }) async {
    try {
      isLoading.value = true;

      final result = await getIt<OrdersRepository>().addProductToOrder(
        orderId,
        productId,
        existingQuantity,
        requestedQuantity,
        measurementUnit,
        temporaryProductId: temporaryProductId,
        supplierId: supplierId,
      );

      return result.fold(
        (failure) {
          // Check for specific error messages and provide better user feedback
          String errorMessage = failure.message;
          if (failure.message.contains('Product already exists in order')) {
            errorMessage =
                'El producto ya está agregado al pedido. Use la opción de editar cantidades.';
          }

          Get.snackbar(
            'Error',
            errorMessage,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return false;
        },
        (updatedOrder) {
          // Update the selected order with the new data
          selectedOrder.value = updatedOrder;

          // Also update the order in the list if it exists
          final index = orders.indexWhere((order) => order.id == orderId);
          if (index != -1) {
            orders[index] = updatedOrder;
          }

          Get.snackbar(
            'Éxito',
            'Producto agregado al pedido',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary.withValues(
              alpha: 0.1,
            ),
            colorText: Get.theme.colorScheme.primary,
          );
          return true;
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Remove product from existing order
  Future<bool> removeProductFromExistingOrder(
    String orderId,
    String itemId,
  ) async {
    try {
      isLoading.value = true;

      final result = await getIt<OrdersRepository>().removeProductFromOrder(
        orderId,
        itemId,
      );

      return result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return false;
        },
        (updatedOrder) {
          // Update the selected order with the new data
          selectedOrder.value = updatedOrder;

          // Also update the order in the list if it exists
          final index = orders.indexWhere((order) => order.id == orderId);
          if (index != -1) {
            orders[index] = updatedOrder;
          }

          Get.snackbar(
            'Éxito',
            'Producto removido del pedido',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary.withValues(
              alpha: 0.1,
            ),
            colorText: Get.theme.colorScheme.primary,
          );
          return true;
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update quantities for order item
  Future<bool> updateExistingOrderItemQuantities(
    String orderId,
    String itemId,
    int? existingQuantity,
    int? requestedQuantity,
  ) async {
    try {
      isLoading.value = true;

      final result = await getIt<OrdersRepository>().updateOrderItemQuantity(
        orderId,
        itemId,
        existingQuantity,
        requestedQuantity,
      );

      return result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return false;
        },
        (updatedOrder) {
          // Update the selected order with the new data
          selectedOrder.value = updatedOrder;

          // Also update the order in the list if it exists
          final index = orders.indexWhere((order) => order.id == orderId);
          if (index != -1) {
            orders[index] = updatedOrder;
          }

          Get.snackbar(
            'Éxito',
            'Cantidades actualizadas',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary.withValues(
              alpha: 0.1,
            ),
            colorText: Get.theme.colorScheme.primary,
          );
          return true;
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
