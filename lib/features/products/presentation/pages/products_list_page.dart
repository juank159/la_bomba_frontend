// lib/features/products/presentation/pages/products_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/products_controller.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../../../app/core/di/service_locator.dart';
import '../widgets/product_card.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../notifications/data/repositories/notifications_repository_impl.dart';
import '../../../notifications/data/datasources/notifications_remote_datasource.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/presentation/widgets/barcode_scanner_overlay.dart';

/// ProductsListPage - Main page showing list of products with search and pagination
/// Features:
/// - Search by description or barcode with debouncing
/// - Pull-to-refresh functionality
/// - Infinite scroll pagination
/// - Empty and error states
/// - Role-based access (admin and employee can view)
class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  late ProductsController controller;
  late ScrollController scrollController;
  late TextEditingController searchController;
  final RxBool isScanning = false.obs;

  @override
  void initState() {
    super.initState();
    // Initialize products controller with dependencies
    Get.put(
      ProductsController(
        getProductsUseCase: getIt<GetProductsUseCase>(),
        getProductByIdUseCase: getIt<GetProductByIdUseCase>(),
        updateProductUseCase: getIt<UpdateProductUseCase>(),
      ),
      permanent: true,
    );
    controller = Get.find<ProductsController>();

    // Initialize notifications controller for admin users
    final authController = Get.find<AuthController>();

    if (authController.isAdmin) {
      if (!Get.isRegistered<NotificationsController>()) {
        final dioClient = getIt<DioClient>();
        final dataSource = NotificationsRemoteDataSourceImpl(dioClient);
        final repository = NotificationsRepositoryImpl(dataSource);

        Get.put(
          NotificationsController(repository: repository),
          permanent: true,
        );
      } else {
        // Si ya está registrado, forzar recarga de notificaciones
        final notifController = Get.find<NotificationsController>();
        notifController.loadNotifications();
      }
    }

    scrollController = ScrollController();
    searchController = TextEditingController();

    // Setup scroll listener for pagination
    scrollController.addListener(_onScroll);

    // Setup search controller listener
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    searchController.removeListener(_onSearchChanged);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  /// Handle scroll events for pagination
  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      controller.loadMoreProducts();
    }
  }

  /// Handle search text changes
  void _onSearchChanged() {
    controller.searchProducts(searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildBody()),
            ],
          ),
          // Barcode Scanner Overlay
          Obx(() {
            if (isScanning.value) {
              return BarcodeScannerOverlay(
                onBarcodeDetected: _handleBarcodeScanned,
                onClose: _stopBarcodeScanning,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar with title and actions
  PreferredSizeWidget _buildAppBar() {
    final authController = Get.find<AuthController>();

    return AppBar(
      title: const Text('Productos'),
      centerTitle: true,
      elevation: 0,
      actions: [
        // Notification bell (only for admins)
        if (authController.isAdmin &&
            Get.isRegistered<NotificationsController>())
          const NotificationBell(),
        // Filter button (future feature)
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filtros',
        ),
        // More options menu
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Actualizar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Exportar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: CustomInput(
              controller: searchController,
              hintText: 'Buscar por descripción o código...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          // Barcode scanner button
          Container(
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: IconButton(
              icon: Icon(
                Icons.qr_code_scanner,
                color: Get.theme.colorScheme.onSecondaryContainer,
              ),
              onPressed: _startBarcodeScanning,
              tooltip: 'Escanear código de barras',
            ),
          ),
        ],
      ),
    );
  }

  /// Build main body content
  Widget _buildBody() {
    return Obx(() {
      // Show loading on first load
      if (controller.isLoading.value && controller.products.isEmpty) {
        return const LoadingWidget(message: 'Cargando productos...');
      }

      // Show error state if products list is empty and there's an error
      if (controller.showErrorState) {
        return _buildErrorState();
      }

      // Show empty state
      if (controller.showEmptyState) {
        return _buildEmptyState();
      }

      // Show products list
      return _buildProductsList();
    });
  }

  /// Build products list with pull-to-refresh
  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: controller.refreshProducts,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Search status
          SliverToBoxAdapter(child: _buildSearchStatus()),

          // Products list
          SliverPadding(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < controller.products.length) {
                  final product = controller.products[index];
                  return ProductCard(product: product);
                }

                // Show loading indicator at bottom when loading more
                return Obx(() {
                  if (controller.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.all(AppConfig.paddingMedium),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return const SizedBox.shrink();
                });
              }, childCount: controller.products.length + 1),
            ),
          ),
        ],
      ),
    );
  }

  /// Build search status widget
  Widget _buildSearchStatus() {
    return Obx(() {
      if (controller.products.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConfig.paddingMedium,
          vertical: AppConfig.paddingSmall,
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.searchStatusText,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            Text(
              'Error al cargar productos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            Obx(
              () => Text(
                controller.errorMessage.value,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppConfig.paddingLarge),
            ElevatedButton.icon(
              onPressed: () => controller.loadProducts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.searchQuery.value.isEmpty
                  ? Icons.inventory_2_outlined
                  : Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            Text(
              controller.searchQuery.value.isEmpty
                  ? 'No hay productos disponibles'
                  : 'No se encontraron productos',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            Text(
              controller.searchQuery.value.isEmpty
                  ? 'Los productos aparecerán aquí cuando estén disponibles.'
                  : 'Intenta con una búsqueda diferente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (controller.searchQuery.value.isNotEmpty) ...[
              const SizedBox(height: AppConfig.paddingLarge),
              ElevatedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar búsqueda'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build floating action button
  Widget? _buildFloatingActionButton() {
    return Obx(() {
      // Show FAB only when not loading and has products
      if (controller.isLoading.value || controller.products.isEmpty) {
        return const SizedBox.shrink();
      }

      return FloatingActionButton.extended(
        onPressed: _scrollToTop,
        icon: const Icon(Icons.keyboard_arrow_up),
        label: const Text('Inicio'),
      );
    });
  }

  /// Clear search and reset filters
  void _clearSearch() {
    searchController.clear();
    controller.clearSearch();
  }

  /// Scroll to top of the list
  void _scrollToTop() {
    scrollController.animateTo(
      0,
      duration: AppConfig.animationDurationMedium,
      curve: Curves.easeOut,
    );
  }

  /// Show filter dialog (future feature)
  void _showFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Filtros'),
        content: const Text('Los filtros avanzados no están disponibles aún.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  /// Handle app bar menu selections
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        controller.refreshProducts();
        break;
      case 'export':
        controller.exportProducts();
        break;
    }
  }

  /// Start barcode scanning
  void _startBarcodeScanning() {
    print('📷 [ProductsListPage] Starting barcode scanning');
    isScanning.value = true;
  }

  /// Stop barcode scanning
  void _stopBarcodeScanning() {
    print('🛑 [ProductsListPage] Stopping barcode scanning');
    isScanning.value = false;
  }

  /// Handle scanned barcode
  void _handleBarcodeScanned(String barcode) {
    print('📊 [ProductsListPage] Barcode scanned: $barcode');

    // Close scanner
    _stopBarcodeScanning();

    // Set the barcode in the search field
    searchController.text = barcode;

    // Trigger search with the scanned barcode
    controller.searchProducts(barcode);

    // Show feedback to user
    Get.snackbar(
      'Código Escaneado',
      'Buscando producto con código: $barcode',
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
}
