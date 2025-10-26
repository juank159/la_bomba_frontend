// lib/features/orders/presentation/pages/create_order_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../domain/entities/order_item.dart';
import '../../../products/domain/entities/product.dart';
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

                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: hasProductsWithoutSupplier ? null : _showProductSelectionSheet,
                                    icon: Icon(
                                      Icons.search,
                                      size: isSmallScreen ? 16 : 18,
                                    ),
                                    label: Text(
                                      isSmallScreen ? 'Buscar' : 'Buscar Producto',
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
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : AppConfig.paddingMedium),
                                OutlinedButton.icon(
                                  onPressed: hasProductsWithoutSupplier ? null : _startBarcodeScanning,
                                  icon: Icon(
                                    Icons.qr_code_scanner,
                                    size: isSmallScreen ? 16 : 18,
                                  ),
                                  label: Text(
                                    'Escanear',
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
                                          : Get.theme.colorScheme.secondary,
                                      width: 1.5,
                                    ),
                                    foregroundColor: hasProductsWithoutSupplier
                                        ? Get.theme.colorScheme.onSurface.withOpacity(0.38)
                                        : Get.theme.colorScheme.secondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ProductSelectionSheet(onProductSelected: _addProductToOrder),
    );
  }

  void _addProductToOrder(Product product) {
    print('🔍 [CreateOrderPage] Product selected: ${product.description}');
    // Directly add product to order with default values
    final controller = Get.find<OrdersController>();
    controller.addProductToOrder(
      product,
      existingQuantity: 1, // Default existing quantity
      requestedQuantity: null, // No requested quantity by default
      measurementUnit: MeasurementUnit.unidad, // Default unit
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

  void _startBarcodeScanning() {
    final controller = Get.find<OrdersController>();
    controller.startBarcodeScanning();
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
