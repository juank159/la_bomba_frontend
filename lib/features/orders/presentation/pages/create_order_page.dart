// lib/features/orders/presentation/pages/create_order_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../domain/entities/order_item.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/products_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/orders_controller.dart';
import '../widgets/product_selection_sheet.dart';
import '../widgets/order_item_card.dart';
import '../widgets/barcode_scanner_overlay.dart';

/// Create order page with product selection and barcode scanning
class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _providerController = TextEditingController();
  final _scrollController = ScrollController();
  final RxString _descriptionText = ''.obs;

  @override
  void initState() {
    super.initState();

    // Listen to description changes
    _descriptionController.addListener(() {
      _descriptionText.value = _descriptionController.text;
    });

    // Clear any previous new order data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<OrdersController>();
      controller.clearNewOrderData();

      // Set up callbacks for scanner results
      controller.onScannedProductFound = _addProductToOrder;
      controller.onMultipleProductsFromScan = _showProductSelectionSheet;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _providerController.dispose();
    _scrollController.dispose();

    // Clean up callbacks
    final controller = Get.find<OrdersController>();
    controller.onScannedProductFound = null;
    controller.onMultipleProductsFromScan = null;

    super.dispose();
  }

  /// Check if there are unsaved changes
  bool _hasUnsavedChanges() {
    final controller = Get.find<OrdersController>();
    return _descriptionController.text.trim().isNotEmpty ||
           _providerController.text.trim().isNotEmpty ||
           controller.newOrderSupplierId.value != null ||
           controller.newOrderItems.isNotEmpty;
  }

  /// Show professional confirmation dialog for discarding changes
  /// Returns true if user chose to discard changes, false otherwise
  Future<bool> _showDiscardChangesDialog() async {
    final controller = Get.find<OrdersController>();

    // Count the changes
    List<String> changesList = [];
    if (_descriptionController.text.trim().isNotEmpty) {
      changesList.add('• Descripción ingresada');
    }
    if (_providerController.text.trim().isNotEmpty) {
      changesList.add('• Proveedor ingresado');
    }
    if (controller.newOrderSupplierId.value != null) {
      final selectedSupplier = controller.suppliers.firstWhere(
        (s) => s.id == controller.newOrderSupplierId.value,
        orElse: () => controller.suppliers.first,
      );
      changesList.add('• Proveedor seleccionado: ${selectedSupplier.nombre}');
    }
    if (controller.newOrderItems.isNotEmpty) {
      changesList.add('• ${controller.newOrderItems.length} producto(s) agregado(s)');
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Get.theme.colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pedido sin guardar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tienes los siguientes cambios sin guardar:',
              style: TextStyle(
                fontSize: 14,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Get.theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: changesList.map((change) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 13,
                      color: Get.theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas salir sin crear el pedido?',
              style: TextStyle(
                fontSize: 14,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: Get.theme.colorScheme.primary,
            ),
            child: const Text('Continuar creando'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Clear all data
              final controller = Get.find<OrdersController>();
              controller.clearNewOrderData();
              _descriptionController.clear();
              _providerController.clear();

              // Close dialog and return true to indicate changes were discarded
              Get.back(result: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.delete_sweep, size: 20),
            label: const Text('Descartar pedido'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Handle back navigation with unsaved changes
  Future<bool> _onWillPop() async {
    print('🔙 [CreateOrderPage] _onWillPop called');

    if (!_hasUnsavedChanges()) {
      print('✅ [CreateOrderPage] No changes detected, allowing navigation');
      return true; // Allow navigation - no changes
    }

    print('⚠️ [CreateOrderPage] Changes detected, showing discard dialog');
    // Show professional confirmation dialog
    final shouldDiscard = await _showDiscardChangesDialog();
    print('🔍 [CreateOrderPage] User chose to discard: $shouldDiscard');
    return shouldDiscard;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crear Pedido'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Verificar si hay cambios pendientes antes de navegar
              final shouldPop = await _onWillPop();
              if (shouldPop) {
                // Solo navegar si el usuario confirmó descartar cambios o no hay cambios
                Get.back();
              }
            },
          ),
          actions: [
          Obx(() {
            // Check if all products have supplier in mixed orders (only for admins)
            final isMixedOrder = controller.newOrderSupplierId.value == null;
            final isAdmin = controller.canPerformAdminActions();
            final hasProductsWithoutSupplier = isMixedOrder &&
                isAdmin &&
                controller.newOrderItems.any((item) => item.supplierId == null);

            final canCreate =
                _descriptionText.value.trim().isNotEmpty &&
                controller.newOrderItems.isNotEmpty &&
                !controller.isCreatingOrder.value &&
                !hasProductsWithoutSupplier;
            final isSmallScreen = MediaQuery.of(context).size.width < 600;

            return controller.isCreatingOrder.value
                ? Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    child: SizedBox(
                      width: isSmallScreen ? 18 : 20,
                      height: isSmallScreen ? 18 : 20,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: canCreate ? _createOrder : null,
                    icon: Icon(Icons.check, size: isSmallScreen ? 16 : 18),
                    label: Text(
                      'Crear',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: canCreate
                        ? Get.theme.colorScheme.primary
                        : Get.theme.colorScheme.onSurface.withOpacity(0.38),
                    ),
                  );
          }),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: Column(
              children: [
                // Order Details Section - Responsive
                Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : AppConfig.paddingMedium),
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      final isSmallScreen = MediaQuery.of(context).size.width < 600;

                      return Column(
                        children: [
                          CustomInput(
                            label: 'Descripción del Pedido *',
                            controller: _descriptionController,
                            hintText: isSmallScreen
                              ? 'Descripción...'
                              : 'Ingrese la descripción del pedido...',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La descripción es requerida';
                              }
                              if (value.trim().length < 3) {
                                return 'Mínimo 3 caracteres';
                              }
                              return null;
                            },
                            maxLines: isSmallScreen ? 2 : 2,
                            prefixIcon: Icon(
                              Icons.description,
                              size: isSmallScreen ? 18 : 20,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : AppConfig.paddingMedium),
                          // Supplier Dropdown
                          Obx(() {
                            final isLoadingSuppliers = controller.isLoadingSuppliers.value;
                            final suppliers = controller.suppliers;

                            // Check if there are products with individual suppliers assigned
                            final hasProductsWithSuppliers = controller.newOrderItems.any((item) => item.supplierId != null);
                            final isDropdownDisabled = isLoadingSuppliers || hasProductsWithSuppliers;

                            return DropdownButtonFormField<String>(
                              value: controller.newOrderSupplierId.value,
                              decoration: InputDecoration(
                                labelText: 'Proveedor General (Opcional)',
                                hintText: isLoadingSuppliers
                                  ? 'Cargando proveedores...'
                                  : hasProductsWithSuppliers
                                    ? 'No disponible - Pedido mixto'
                                    : isSmallScreen
                                      ? 'Seleccionar...'
                                      : 'Seleccionar proveedor general...',
                                prefixIcon: Icon(
                                  Icons.business,
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                helperText: hasProductsWithSuppliers
                                  ? 'Este es un pedido mixto con productos de diferentes proveedores. Para cambiarlo, quita los productos primero.'
                                  : controller.newOrderSupplierId.value != null
                                    ? 'Todos los productos serán para este proveedor'
                                    : 'Dejar vacío para productos de múltiples proveedores',
                                helperMaxLines: 3,
                                helperStyle: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 11,
                                  color: hasProductsWithSuppliers
                                    ? Get.theme.colorScheme.error
                                    : null,
                                ),
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'Sin proveedor general',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                ...suppliers.map((supplier) {
                                  return DropdownMenuItem<String>(
                                    value: supplier.id,
                                    child: Text(
                                      supplier.nombre,
                                      style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: isDropdownDisabled
                                ? null
                                : (String? value) {
                                    controller.newOrderSupplierId.value = value;
                                  },
                            );
                          }),

                          SizedBox(height: isSmallScreen ? 8 : 12),

                          // Add Product Buttons - Responsive
                          Obx(() {
                            // Disable buttons if there are products without supplier in mixed orders (only for admins)
                            final isMixedOrder = controller.newOrderSupplierId.value == null;
                            final isAdmin = controller.canPerformAdminActions();
                            final hasProductsWithoutSupplier = isMixedOrder &&
                                isAdmin &&
                                controller.newOrderItems.any((item) => item.supplierId == null);

                            return OutlinedButton.icon(
                              onPressed: hasProductsWithoutSupplier ? null : _showProductSelectionSheet,
                              icon: Icon(
                                Icons.search,
                                size: isSmallScreen ? 16 : 18,
                              ),
                              label: Text(
                                isSmallScreen ? 'Buscar Producto' : 'Buscar / Escanear Producto',
                                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : AppConfig.paddingMedium,
                                  vertical: isSmallScreen ? 8 : 12,
                                ),
                                side: BorderSide(
                                  color: hasProductsWithoutSupplier
                                      ? Get.theme.colorScheme.outline.withOpacity(0.3)
                                      : Get.theme.colorScheme.primary,
                                  width: 1.5,
                                ),
                                foregroundColor: hasProductsWithoutSupplier
                                    ? Get.theme.colorScheme.onSurface.withOpacity(0.38)
                                    : Get.theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),

                // Products Section
                Expanded(
                  child: Column(
                    children: [
                      // Section Header - Responsive
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Get.theme.colorScheme.primaryContainer.withOpacity(0.3),
                        ),
                        child: Builder(
                          builder: (context) {
                            final isSmallScreen = MediaQuery.of(context).size.width < 600;

                            return Row(
                              children: [
                                Icon(
                                  Icons.inventory,
                                  size: isSmallScreen ? 16 : 18,
                                  color: Get.theme.colorScheme.primary,
                                ),
                                SizedBox(width: isSmallScreen ? 6 : 8),
                                Text(
                                  'Productos',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: Get.theme.colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                Obx(
                                  () => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 6 : 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Get.theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${controller.newOrderItems.length}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        fontWeight: FontWeight.bold,
                                        color: Get.theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Products List or Empty State
                      Expanded(
                        child: Obx(() {
                          if (controller.newOrderItems.isEmpty) {
                            return _buildEmptyProductsState();
                          }

                          return ListView.separated(
                            controller: _scrollController,
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width < 600 ? 8 : 12,
                            ),
                            itemCount: controller.newOrderItems.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: MediaQuery.of(context).size.width < 600 ? 6 : 8),
                            itemBuilder: (context, index) {
                              final item = controller.newOrderItems[index];
                              return OrderItemCard(
                                item: item,
                                isEditingOrder: true,
                                canEditRequestedQuantity: controller
                                    .canPerformAdminActions(),
                                showRequestedQuantities: controller
                                    .canPerformAdminActions(),
                                // Show supplier selector only if ADMIN and no general supplier
                                showSupplierSelector: controller.canPerformAdminActions() &&
                                    controller.newOrderSupplierId.value == null,
                                suppliers: controller.suppliers,
                                startCollapsed:
                                    true, // Start collapsed to save space
                                onQuantityChanged: (existingQty, requestedQty) {
                                  controller.updateOrderItemQuantities(
                                    item.actualProductId,
                                    existingQuantity: existingQty,
                                    requestedQuantity: requestedQty,
                                  );
                                },
                                onMeasurementUnitChanged: (unit) {
                                  controller.updateOrderItemMeasurementUnit(
                                    item.actualProductId,
                                    unit,
                                  );
                                },
                                onSupplierChanged: (supplierId) {
                                  controller.updateOrderItemSupplier(
                                    item.actualProductId,
                                    supplierId,
                                  );
                                },
                                onRemove: () {
                                  controller.removeProductFromOrder(
                                    item.actualProductId,
                                  );
                                },
                                showRemoveButton: true,
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barcode Scanner Overlay
          Obx(() {
            if (controller.isScanningBarcode.value) {
              return BarcodeScannerOverlay(
                onBarcodeDetected: controller.handleBarcodeScanned,
                onClose: controller.stopBarcodeScanning,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
        ),
      ),
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    return Builder(
      builder: (context) {
        final isSmallScreen = MediaQuery.of(context).size.width < 600;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : AppConfig.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : AppConfig.paddingLarge),
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_outlined,
                    size: isSmallScreen ? 48 : 60,
                    color: Get.theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : AppConfig.paddingLarge),
                Text(
                  'No hay productos agregados',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : AppConfig.headingFontSize,
                    fontWeight: FontWeight.w600,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 8 : AppConfig.paddingMedium),
                Text(
                  isSmallScreen
                    ? 'Usa "Buscar" o "Escanear" para agregar productos'
                    : 'Usa los botones "Buscar Producto" o "Escanear" de arriba para agregar productos',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : AppConfig.bodyFontSize,
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProductSelectionSheet() {
    final authController = Get.find<AuthController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductSelectionSheet(
        onProductSelected: _addProductToOrder,
        onUnregisteredProductAdded: authController.isAdmin ? _addUnregisteredProduct : null,
      ),
    );
  }

  /// Add an unregistered product to the temporary products list (admin only)
  Future<void> _addUnregisteredProduct(String productName) async {
    final notesController = TextEditingController();

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: Text('Producto no registrado\n$productName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este producto se guardará como temporal hasta que sea registrado.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                  helperText: 'Añade información adicional sobre el producto',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back(result: {
                'notes': notesController.text.trim(),
              });
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      final notes = result['notes'] as String;

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        // Create temporary product
        final productsRepository = getIt<ProductsRepository>();
        final authController = Get.find<AuthController>();
        final userId = authController.user?.id;

        if (userId == null) {
          Get.back();
          Get.snackbar(
            'Error',
            'No se pudo obtener el ID del usuario',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return;
        }

        final temporaryProductData = {
          'name': productName,
          'notes': notes.isEmpty ? null : notes,
          'createdBy': userId,
        };

        print('🚀 [CreateOrder] Creating temporary product: $temporaryProductData');

        // Call temporary products endpoint
        final response = await productsRepository.createTemporaryProduct(temporaryProductData);

        response.fold(
          (failure) {
            Get.back(); // Close loading dialog
            Get.snackbar(
              'Error',
              'No se pudo guardar el producto temporal: ${failure.toString()}',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
              colorText: Get.theme.colorScheme.error,
              duration: const Duration(seconds: 4),
            );
          },
          (temporaryProduct) {
            Get.back(); // Close loading dialog
            print('✅ [CreateOrder] Temporary product created: ${temporaryProduct['id']}');

            // Crear un Product temporal para agregarlo al pedido
            final tempProduct = Product(
              id: temporaryProduct['id'], // Usar el ID del producto temporal
              description: '$productName (TEMPORAL - Sin precios)',
              barcode: 'TEMP-${temporaryProduct['id'].substring(0, 8)}',
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              precioA: 0.0, // Placeholder hasta que admin agregue precio real
              iva: 0.0, // Placeholder hasta que admin agregue IVA real
            );

            // Agregar el producto temporal al pedido
            _addProductToOrder(tempProduct);

            Get.snackbar(
              'Producto temporal agregado',
              'Se guardó "$productName" y se agregó al pedido. El administrador debe completar precios e IVA cuando llegue.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade900,
              duration: const Duration(seconds: 5),
              icon: const Icon(Icons.check_circle, color: Colors.green),
            );
          },
        );
      } catch (e) {
        Get.back(); // Close loading dialog
        print('💥 [CreateOrder] Exception creating temporary product: $e');
        Get.snackbar(
          'Error',
          'Error al guardar el producto temporal: ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  /// Add product to order with quantity dialog
  void _addProductToOrder(Product product) async {
    print('🔍 [CreateOrderPage] Product selected: ${product.description}');

    final controller = Get.find<OrdersController>();
    final isAdmin = controller.canPerformAdminActions();

    // Check if this is a temporary product (new product without price/iva)
    final isTemporaryProduct = product.precioA == 0.0 && product.iva == 0.0;

    // Check if product already exists in the order
    final existingItemIndex = controller.newOrderItems.indexWhere(
      (item) => item.actualProductId == product.id,
    );

    if (existingItemIndex != -1) {
      // Product already exists, show update dialog
      final existing = controller.newOrderItems[existingItemIndex];
      await _showUpdateExistingProductDialog(product, existing, isTemporaryProduct, isAdmin);
      return;
    }

    // Product doesn't exist, show add dialog
    await _showAddNewProductDialog(product, isTemporaryProduct, isAdmin);
  }

  /// Show dialog to add a new product to the order
  Future<void> _showAddNewProductDialog(
    Product product,
    bool isTemporaryProduct,
    bool isAdmin,
  ) async {
    final controller = Get.find<OrdersController>();

    // For temporary products, start with '1' since field is for requested quantity
    // For regular products, default to 1
    final existingController = TextEditingController(text: '1');
    final requestedController = TextEditingController();
    final selectedUnit = Rx<MeasurementUnit>(MeasurementUnit.unidad);
    final selectedSupplierId = Rx<String?>(null);

    // Detectar si es pedido mixto
    final isMixedOrder = controller.newOrderSupplierId.value == null;

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agregar producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              product.description,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            if (isTemporaryProduct) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Producto nuevo - La cantidad existente es 0',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: existingController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isTemporaryProduct ? 'Cantidad solicitada' : 'Cantidad existente',
                  border: OutlineInputBorder(),
                  helperText: isTemporaryProduct
                      ? 'El producto aún no existe en inventario'
                      : null,
                ),
              ),
              // Solo mostrar campo de cantidad solicitada a administradores Y si NO es producto temporal
              if (isAdmin && !isTemporaryProduct) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: requestedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad solicitada (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              // Unidad de medida - TODOS los roles
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<MeasurementUnit>(
                value: selectedUnit.value,
                decoration: const InputDecoration(
                  labelText: 'Unidad de medida',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                items: MeasurementUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedUnit.value = value;
                  }
                },
              )),
              // Selector de proveedor - Solo ADMIN en pedidos mixtos
              if (isAdmin && isMixedOrder) ...[
                const SizedBox(height: 16),
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedSupplierId.value,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                    helperText: 'Asigna un proveedor para este producto',
                  ),
                  hint: const Text('Sin asignar'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Sin asignar'),
                    ),
                    ...controller.suppliers.map((supplier) {
                      return DropdownMenuItem<String>(
                        value: supplier.id,
                        child: Text(
                          supplier.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    print('📦 [CreateOrder] Supplier selected: $value');
                    selectedSupplierId.value = value;
                  },
                )),
              ],
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
              // Para productos temporales: existingQty=0, requestedQty=valor del campo
              // Para productos normales: existingQty=valor del campo, requestedQty=campo adicional
              final existingQty = isTemporaryProduct
                  ? 0
                  : int.tryParse(existingController.text);

              final requestedQty = isTemporaryProduct
                  ? int.tryParse(existingController.text) // El valor ingresado es la cantidad solicitada
                  : (isAdmin
                      ? (requestedController.text.isEmpty
                          ? null
                          : int.tryParse(requestedController.text))
                      : null);

              // VALIDACIÓN DE CANTIDAD
              if (isTemporaryProduct) {
                // Para productos temporales, validar requestedQty
                if (requestedQty == null || requestedQty < 1) {
                  Get.snackbar(
                    'Error',
                    'La cantidad solicitada debe ser un número válido mayor a 0',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
                    colorText: Get.theme.colorScheme.error,
                  );
                  return;
                }
              } else {
                // Para productos normales, validar existingQty
                if (existingQty == null || existingQty < 0) {
                  Get.snackbar(
                    'Error',
                    'La cantidad existente debe ser un número válido',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
                    colorText: Get.theme.colorScheme.error,
                  );
                  return;
                }
              }

              // VALIDACIÓN DE PROVEEDOR EN PEDIDOS MIXTOS
              if (isAdmin && isMixedOrder && selectedSupplierId.value == null) {
                Get.snackbar(
                  'Proveedor Requerido',
                  'Debes seleccionar un proveedor para este producto en pedidos mixtos',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
                  colorText: Get.theme.colorScheme.error,
                  duration: const Duration(seconds: 3),
                  icon: Icon(Icons.warning_amber_rounded, color: Get.theme.colorScheme.error),
                );
                return;
              }

              // Todo válido, cerrar diálogo con resultado
              Get.back(result: {
                'existingQuantity': existingQty,
                'requestedQuantity': requestedQty,
                'measurementUnit': selectedUnit.value,
                'supplierId': selectedSupplierId.value,
              });
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result != null) {
      print('📦 [CreateOrder] Result received from dialog:');
      print('   - supplierId: ${result['supplierId']}');
      print('   - existingQuantity: ${result['existingQuantity']}');
      print('   - requestedQuantity: ${result['requestedQuantity']}');

      // Add product to order
      controller.addProductToOrder(
        product,
        existingQuantity: result['existingQuantity']!,
        requestedQuantity: result['requestedQuantity'],
        measurementUnit: result['measurementUnit'] ?? MeasurementUnit.unidad,
        supplierId: result['supplierId'],
      );

      // Show success feedback
      Get.snackbar(
        'Producto Agregado',
        '${product.description} agregado al pedido',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Show dialog to update an existing product in the order
  Future<void> _showUpdateExistingProductDialog(
    Product product,
    OrderItem existing,
    bool isTemporaryProduct,
    bool isAdmin,
  ) async {
    final controller = Get.find<OrdersController>();

    final existingController = TextEditingController(text: existing.existingQuantity.toString());
    final requestedController = TextEditingController(text: existing.requestedQuantity?.toString() ?? '');
    final selectedUnit = Rx<MeasurementUnit>(existing.measurementUnit);
    final selectedSupplierId = Rx<String?>(existing.supplierId);

    // Detectar si es pedido mixto
    final isMixedOrder = controller.newOrderSupplierId.value == null;

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Producto ya existe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              product.description,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Este producto ya está en el pedido. ¿Deseas actualizar las cantidades?',
                style: TextStyle(
                  fontSize: 14,
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (isTemporaryProduct) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Producto nuevo - Sin inventario existente',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: existingController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isTemporaryProduct ? 'Cantidad solicitada' : 'Cantidad existente',
                  border: OutlineInputBorder(),
                  helperText: isTemporaryProduct
                      ? 'El producto aún no existe en inventario'
                      : null,
                ),
              ),
              // Solo mostrar campo de cantidad solicitada a administradores Y si NO es producto temporal
              if (isAdmin && !isTemporaryProduct) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: requestedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad solicitada (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              // Unidad de medida - TODOS los roles
              const SizedBox(height: 16),
              Obx(() => DropdownButtonFormField<MeasurementUnit>(
                value: selectedUnit.value,
                decoration: const InputDecoration(
                  labelText: 'Unidad de medida',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                items: MeasurementUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedUnit.value = value;
                  }
                },
              )),
              // Selector de proveedor - Solo ADMIN en pedidos mixtos
              if (isAdmin && isMixedOrder) ...[
                const SizedBox(height: 16),
                Obx(() => DropdownButtonFormField<String>(
                  value: selectedSupplierId.value,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                    helperText: 'Asigna un proveedor para este producto',
                  ),
                  hint: const Text('Sin asignar'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Sin asignar'),
                    ),
                    ...controller.suppliers.map((supplier) {
                      return DropdownMenuItem<String>(
                        value: supplier.id,
                        child: Text(
                          supplier.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    print('📦 [CreateOrder] Supplier selected: $value');
                    selectedSupplierId.value = value;
                  },
                )),
              ],
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
              // Para productos temporales: existingQty=0, requestedQty=valor del campo
              // Para productos normales: existingQty=valor del campo, requestedQty=campo adicional
              final existingQty = isTemporaryProduct
                  ? 0
                  : int.tryParse(existingController.text);

              final requestedQty = isTemporaryProduct
                  ? int.tryParse(existingController.text) // El valor ingresado es la cantidad solicitada
                  : (isAdmin
                      ? (requestedController.text.isEmpty
                          ? null
                          : int.tryParse(requestedController.text))
                      : existing.requestedQuantity); // Mantener valor original para empleados

              // VALIDACIÓN DE CANTIDAD
              if (isTemporaryProduct) {
                // Para productos temporales, validar requestedQty
                if (requestedQty == null || requestedQty < 1) {
                  Get.snackbar(
                    'Error',
                    'La cantidad solicitada debe ser un número válido mayor a 0',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
                    colorText: Get.theme.colorScheme.error,
                  );
                  return;
                }
              } else {
                // Para productos normales, validar existingQty
                if (existingQty == null || existingQty < 0) {
                  Get.snackbar(
                    'Error',
                    'La cantidad existente debe ser un número válido',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
                    colorText: Get.theme.colorScheme.error,
                  );
                  return;
                }
              }

              // VALIDACIÓN DE PROVEEDOR EN PEDIDOS MIXTOS
              if (isAdmin && isMixedOrder && selectedSupplierId.value == null) {
                Get.snackbar(
                  'Proveedor Requerido',
                  'Debes seleccionar un proveedor para este producto en pedidos mixtos',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
                  colorText: Get.theme.colorScheme.error,
                  duration: const Duration(seconds: 3),
                  icon: Icon(Icons.warning_amber_rounded, color: Get.theme.colorScheme.error),
                );
                return;
              }

              // Todo válido, cerrar diálogo con resultado
              Get.back(result: {
                'existingQuantity': existingQty,
                'requestedQuantity': requestedQty,
                'measurementUnit': selectedUnit.value,
                'supplierId': selectedSupplierId.value,
              });
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Update existing product
      controller.updateOrderItemQuantities(
        existing.actualProductId,
        existingQuantity: result['existingQuantity']!,
        requestedQuantity: result['requestedQuantity'],
      );
      controller.updateOrderItemMeasurementUnit(
        existing.actualProductId,
        result['measurementUnit'] ?? existing.measurementUnit,
      );
      // Update supplier if provided
      if (result.containsKey('supplierId')) {
        controller.updateOrderItemSupplier(
          existing.actualProductId,
          result['supplierId'],
        );
      }

      // Show success feedback
      Get.snackbar(
        'Producto Actualizado',
        '${product.description} actualizado en el pedido',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showQuantityDialog(Product product) {
    final existingQtyController = TextEditingController(text: '0');
    final requestedQtyController = TextEditingController();
    MeasurementUnit selectedUnit = MeasurementUnit.unidad;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar ${product.description}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomInput(
              label: 'Cantidad Existente',
              controller: existingQtyController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Requerido';
                if (int.tryParse(value) == null || int.parse(value) < 0) {
                  return 'Debe ser un número válido >= 0';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            CustomInput(
              label: 'Cantidad Solicitada (Opcional)',
              controller: requestedQtyController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Debe ser un número válido >= 0';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            DropdownButtonFormField<MeasurementUnit>(
              value: selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Unidad de Medida',
                border: OutlineInputBorder(),
              ),
              items: MeasurementUnit.values.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(unit.displayName),
                );
              }).toList(),
              onChanged: (unit) {
                if (unit != null) {
                  selectedUnit = unit;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              print(
                '🔍 [CreateOrderPage] Add button pressed in quantity dialog',
              );
              final existingQty = int.tryParse(existingQtyController.text);
              final requestedQty = requestedQtyController.text.trim().isNotEmpty
                  ? int.tryParse(requestedQtyController.text)
                  : null;

              print(
                '🔍 [CreateOrderPage] Parsed quantities - existing: $existingQty, requested: $requestedQty',
              );

              if (existingQty != null && existingQty >= 0) {
                print(
                  '🔍 [CreateOrderPage] Validation passed, calling controller.addProductToOrder',
                );
                final controller = Get.find<OrdersController>();
                controller.addProductToOrder(
                  product,
                  existingQuantity: existingQty,
                  requestedQuantity: requestedQty,
                  measurementUnit: selectedUnit,
                );
                Navigator.of(context).pop();
                print(
                  '🔍 [CreateOrderPage] Dialog closed, product should be added',
                );
              } else {
                print(
                  '🔍 [CreateOrderPage] Validation failed - existingQty: $existingQty',
                );
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  bool _canCreateOrder() {
    final controller = Get.find<OrdersController>();
    return _descriptionController.text.trim().isNotEmpty &&
        controller.newOrderItems.isNotEmpty &&
        !controller.isCreatingOrder.value;
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canCreateOrder()) return;

    final controller = Get.find<OrdersController>();

    // Validate products have suppliers in mixed orders (only for admins)
    final isMixedOrder = controller.newOrderSupplierId.value == null;
    final isAdmin = controller.canPerformAdminActions();
    if (isMixedOrder && isAdmin) {
      final productsWithoutSupplier = controller.newOrderItems
          .where((item) => item.supplierId == null)
          .toList();

      if (productsWithoutSupplier.isNotEmpty) {
        Get.snackbar(
          'Error de Validación',
          'Como administrador, debes asignar un proveedor a todos los productos en pedidos mixtos. ${productsWithoutSupplier.length} producto(s) sin proveedor.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error_outline, color: Colors.white),
        );
        return;
      }
    }

    // Get supplier name if one is selected (for backward compatibility)
    String? providerName;
    if (controller.newOrderSupplierId.value != null) {
      final selectedSupplier = controller.suppliers.firstWhereOrNull(
        (s) => s.id == controller.newOrderSupplierId.value,
      );
      providerName = selectedSupplier?.nombre;
    } else if (_providerController.text.trim().isNotEmpty) {
      // Fallback to text field for backward compatibility
      providerName = _providerController.text.trim();
    }

    final success = await controller.createOrder(
      description: _descriptionController.text.trim(),
      provider: providerName,
      items: controller.newOrderItems,
    );

    if (success) {
      // Clear text controllers
      _descriptionController.clear();
      _providerController.clear();

      // Navigate to orders list and remove all previous routes
      Get.offAllNamed('/orders');

      // Refresh the orders list to ensure the new order is visible at the top
      await controller.refreshOrders();
    }
  }
}
