// lib/features/products/presentation/pages/products_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/price_input_formatter.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/products_controller.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/repositories/products_repository.dart';
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
            // Create Product option (only for admins)
            if (authController.isAdmin)
              const PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(Icons.add_circle),
                    SizedBox(width: 8),
                    Text('Crear Producto'),
                  ],
                ),
              ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
      case 'create':
        _showCreateProductDialog();
        break;
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

  /// Show create product dialog
  Future<void> _showCreateProductDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ivaController = TextEditingController();
    final precioAController = TextEditingController();
    final precioBController = TextEditingController();
    final precioCController = TextEditingController();
    final costoController = TextEditingController();
    final barcodeController = TextEditingController();
    final isScanningBarcode = false.obs;
    final isCreating = false.obs;

    // Handle barcode scanned
    void handleBarcodeScanned(String barcode) {
      print('📊 [CreateProduct] Barcode scanned: $barcode');
      isScanningBarcode.value = false;
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

    Get.dialog(
      Stack(
        children: [
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_circle, color: Get.theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Crear Producto',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                  tooltip: 'Cerrar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              'Se creará una tarea para el supervisor para revisar el producto.',
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
                    // Nombre del producto
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto *',
                        hintText: 'Ej: Coca Cola 2L',
                        prefixIcon: Icon(Icons.inventory),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    // Precio A (Precio Público)
                    TextFormField(
                      controller: precioAController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Público (Precio A) *',
                        hintText: 'Ej: 25.500',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                        helperText: 'Precio de venta al público',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [PriceInputFormatter()],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El precio es requerido';
                        }
                        final precio = PriceFormatter.parse(value.trim());
                        if (precio <= 0) {
                          return 'El precio debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Precio B (Mayorista)
                    TextFormField(
                      controller: precioBController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Mayorista (Precio B) - Opcional',
                        hintText: 'Ej: 23.000',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                        helperText: 'Para ventas al por mayor',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [PriceInputFormatter()],
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final precio = PriceFormatter.parse(value.trim());
                          if (precio <= 0) {
                            return 'El precio debe ser mayor a 0';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Precio C (Super Mayorista)
                    TextFormField(
                      controller: precioCController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Super Mayorista (Precio C) - Opcional',
                        hintText: 'Ej: 20.000',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                        helperText: 'Para distribuidores y super mayoristas',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [PriceInputFormatter()],
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final precio = PriceFormatter.parse(value.trim());
                          if (precio <= 0) {
                            return 'El precio debe ser mayor a 0';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // IVA
                    TextFormField(
                      controller: ivaController,
                      decoration: const InputDecoration(
                        labelText: 'IVA (%) *',
                        hintText: 'Ej: 19',
                        prefixIcon: Icon(Icons.percent),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El IVA es requerido';
                        }
                        final iva = double.tryParse(value.trim());
                        if (iva == null) {
                          return 'Ingrese un número válido';
                        }
                        if (iva < 0 || iva > 100) {
                          return 'El IVA debe estar entre 0 y 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Costo (Opcional)
                    TextFormField(
                      controller: costoController,
                      decoration: const InputDecoration(
                        labelText: 'Costo (Opcional)',
                        hintText: 'Ej: 15.000',
                        prefixIcon: Icon(Icons.request_quote),
                        border: OutlineInputBorder(),
                        helperText: 'Costo de adquisición del producto',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [PriceInputFormatter()],
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final costo = PriceFormatter.parse(value.trim());
                          if (costo <= 0) {
                            return 'El costo debe ser mayor a 0';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Código de barras (opcional)
                    TextFormField(
                      controller: barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Código de Barras (Opcional)',
                        hintText: 'Ej: 7501234567890',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: const OutlineInputBorder(),
                        helperText: 'El supervisor puede agregarlo después',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Escanear código de barras',
                          onPressed: () {
                            print('📷 [CreateProduct] Starting barcode scanning');
                            isScanningBarcode.value = true;
                          },
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (value.trim().length < 8) {
                            return 'El código debe tener al menos 8 dígitos';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              Obx(() {
                if (isCreating.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CircularProgressIndicator(),
                  );
                }
                return ElevatedButton.icon(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      isCreating.value = true;

                      try {
                        // Prepare product data
                        final productData = {
                          'description': nameController.text.trim(),
                          'precioA': PriceFormatter.parse(precioAController.text.trim()),
                          'iva': double.parse(ivaController.text.trim()),
                        };

                        // Add optional precioB if provided
                        if (precioBController.text.trim().isNotEmpty) {
                          productData['precioB'] = PriceFormatter.parse(precioBController.text.trim());
                        }

                        // Add optional precioC if provided
                        if (precioCController.text.trim().isNotEmpty) {
                          productData['precioC'] = PriceFormatter.parse(precioCController.text.trim());
                        }

                        // Add optional costo if provided
                        if (costoController.text.trim().isNotEmpty) {
                          productData['costo'] = PriceFormatter.parse(costoController.text.trim());
                        }

                        // Add barcode if provided
                        if (barcodeController.text.trim().isNotEmpty) {
                          productData['barcode'] = barcodeController.text.trim();
                        }

                        print('🎯 [CreateProduct] Creating product with data: $productData');

                        // Call repository to create product with supervisor task
                        final repository = getIt<ProductsRepository>();
                        final result = await repository.createProductWithSupervisorTask(productData);

                        result.fold(
                          (failure) {
                            // Error handling
                            isCreating.value = false;
                            print('❌ [CreateProduct] Error: ${failure.message}');

                            Get.snackbar(
                              'Error',
                              failure.message,
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.red.withOpacity(0.1),
                              colorText: Colors.red,
                              duration: const Duration(seconds: 4),
                              icon: const Icon(Icons.error, color: Colors.red),
                            );
                          },
                          (response) {
                            // Success
                            isCreating.value = false;
                            print('✅ [CreateProduct] Product created successfully');

                            Get.back();

                            Get.snackbar(
                              'Producto Creado',
                              'El producto ha sido creado. Se notificó al supervisor.',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
                              colorText: Get.theme.colorScheme.primary,
                              duration: const Duration(seconds: 3),
                              icon: Icon(Icons.check_circle, color: Get.theme.colorScheme.primary),
                            );

                            // Refresh products list
                            controller.refreshProducts();
                          },
                        );
                      } catch (e) {
                        // Unexpected error
                        isCreating.value = false;
                        print('❌ [CreateProduct] Unexpected error: $e');

                        Get.snackbar(
                          'Error Inesperado',
                          'Ocurrió un error al crear el producto: ${e.toString()}',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.red.withOpacity(0.1),
                          colorText: Colors.red,
                          duration: const Duration(seconds: 4),
                          icon: const Icon(Icons.error, color: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Crear Producto'),
                );
              }),
            ],
          ),
          // Barcode Scanner Overlay
          Obx(() {
            if (isScanningBarcode.value) {
              return BarcodeScannerOverlay(
                onBarcodeDetected: handleBarcodeScanned,
                onClose: () {
                  print('🛑 [CreateProduct] Stopping barcode scanning');
                  isScanningBarcode.value = false;
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      barrierDismissible: false,
    ).then((_) {
      // Dispose controllers after dialog closes
      nameController.dispose();
      ivaController.dispose();
      precioAController.dispose();
      precioBController.dispose();
      precioCController.dispose();
      costoController.dispose();
      barcodeController.dispose();
    });
  }
}
