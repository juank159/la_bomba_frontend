//lib/features/orders/presentation/pages/edit_order_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order.dart' as order_entity;
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/products_repository.dart';
import '../../../suppliers/domain/entities/supplier.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/orders_controller.dart';
import '../widgets/product_selection_sheet.dart';

/// Edit order page for admin users to modify existing orders
class EditOrderPage extends StatefulWidget {
  const EditOrderPage({super.key});

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _providerController = TextEditingController();
  final _scrollController = ScrollController();
  final RxString _descriptionText = ''.obs;
  final RxString _providerText = ''.obs;

  late OrdersController _controller;
  String? _orderId;
  order_entity.Order? _originalOrder;
  bool _isLoading = true;

  // Lista local de items para manejar cambios como borrador
  final RxList<OrderItem> _draftOrderItems = <OrderItem>[].obs;

  // Control de cambios pendientes
  final RxBool _hasUnsavedChanges = false.obs;

  @override
  void initState() {
    super.initState();
    print('🎯 [EditOrder] initState called');

    // Get order ID from arguments
    _orderId = Get.arguments as String?;
    _controller = Get.find<OrdersController>();
    print('🆔 [EditOrder] Order ID from arguments: $_orderId');

    if (_orderId == null) {
      print('❌ [EditOrder] Order ID is null, going back');
      Get.back();
      Get.snackbar('Error', 'ID de pedido no válido');
      return;
    }

    // Listen to description changes
    _descriptionController.addListener(() {
      _descriptionText.value = _descriptionController.text;
    });

    // Listen to provider changes
    _providerController.addListener(() {
      _providerText.value = _providerController.text;
    });

    // Set up callbacks for scanner results
    _controller.onScannedProductFound = _addProductToOrder;
    _controller.onMultipleProductsFromScan = _showProductSelectionSheet;

    // Load order data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderData();
    });
  }

  Future<void> _loadOrderData() async {
    print('🚀 [EditOrder] Starting _loadOrderData for order ID: $_orderId');
    try {
      print('📞 [EditOrder] Calling getOrderById...');
      await _controller.getOrderById(_orderId!);
      _originalOrder = _controller.selectedOrder.value;
      if (_originalOrder != null) {
        // Check if user can edit this order
        final authController = Get.find<AuthController>();
        
        // For completed orders, only admins can edit
        if (_originalOrder!.isCompleted && !authController.isAdmin) {
          Get.back();
          Get.snackbar(
            'Sin permisos',
            'Solo los administradores pueden editar pedidos completados',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return;
        }

        // Check edit permissions based on role
        bool canEdit = false;

        if (authController.isAdmin) {
          // Admins can edit any order
          canEdit = true;
        } else if (authController.isSupervisor) {
          // Supervisors can edit their own orders or orders created by employees only
          if (_originalOrder!.createdBy?.id == authController.user?.id) {
            canEdit = true;
          } else if (_originalOrder!.createdBy?.role.isEmployee ?? false) {
            canEdit = true;
          }
        } else if (authController.isEmployee) {
          // Employees can only edit their own orders
          canEdit = _originalOrder!.createdBy?.id == authController.user?.id;
        }

        if (!canEdit) {
          Get.back();
          Get.snackbar(
            'Sin permisos',
            authController.isSupervisor
                ? 'Los supervisores solo pueden editar sus propios pedidos y pedidos de empleados'
                : 'Solo puedes editar tus propios pedidos',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
            colorText: Get.theme.colorScheme.error,
          );
          return;
        }

        // Pre-fill form with existing data
        _descriptionController.text = _originalOrder!.description;
        _providerController.text = _originalOrder!.provider ?? '';
        _descriptionText.value = _originalOrder!.description;
        _providerText.value = _originalOrder!.provider ?? '';

        // Load existing items into draft list for editing
        _draftOrderItems.assignAll(
          _originalOrder!.items
              .map(
                (item) => OrderItem(
                  id: item.id,
                  orderId: item.orderId,
                  productId: item.productId,
                  temporaryProductId: item.temporaryProductId,
                  supplierId: item.supplierId,
                  supplier: item.supplier,
                  product: item.product,
                  temporaryProduct: item.temporaryProduct,
                  existingQuantity: item.existingQuantity,
                  requestedQuantity: item.requestedQuantity,
                  measurementUnit: item.measurementUnit,
                ),
              )
              .toList(),
        );
        
        // Limpiar la lista del controlador ya que usaremos la lista local
        _controller.newOrderItems.clear();

        setState(() {
          _isLoading = false;
        });
      } else {
        print('❌ [EditOrder] Order data is null!');
        Get.back();
        Get.snackbar('Error', 'No se pudo cargar el pedido');
      }
    } catch (e) {
      print('💥 [EditOrder] Exception in _loadOrderData: $e');
      Get.back();
      Get.snackbar('Error', 'Error al cargar el pedido: $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _providerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Revert all changes to original state
  void _revertAllChanges() {
    if (_originalOrder == null) return;

    print('🔄 [EditOrder] Reverting all changes to original state...');

    // Restore description and provider fields
    _descriptionController.text = _originalOrder!.description;
    _providerController.text = _originalOrder!.provider ?? '';
    _descriptionText.value = _originalOrder!.description;
    _providerText.value = _originalOrder!.provider ?? '';

    // Restore original products list
    _draftOrderItems.assignAll(
      _originalOrder!.items
          .map(
            (item) => OrderItem(
              id: item.id,
              orderId: item.orderId,
              productId: item.productId,
              temporaryProductId: item.temporaryProductId,
              supplierId: item.supplierId,
              supplier: item.supplier,
              product: item.product,
              temporaryProduct: item.temporaryProduct,
              existingQuantity: item.existingQuantity,
              requestedQuantity: item.requestedQuantity,
              measurementUnit: item.measurementUnit,
            ),
          )
          .toList(),
    );

    // Clear unsaved changes flag
    _hasUnsavedChanges.value = false;

    print('✅ [EditOrder] All changes reverted successfully');
  }

  /// Edit description dialog
  Future<void> _editDescription() async {
    final controller = TextEditingController(text: _descriptionController.text);

    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Editar Descripción'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ej: Pedido mensual de productos',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                Get.snackbar('Error', 'La descripción es requerida');
                return;
              }
              Get.back(result: controller.text.trim());
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      _descriptionController.text = result;
      _descriptionText.value = result;
    }
  }

  /// Edit provider dialog - Now uses dropdown selector
  Future<void> _editProvider() async {
    // Find the current supplier ID from the provider text
    String? selectedSupplierId;
    if (_providerController.text.isNotEmpty) {
      final matchingSupplier = _controller.suppliers.firstWhere(
        (s) => s.nombre == _providerController.text,
        orElse: () => _controller.suppliers.first,
      );
      selectedSupplierId = matchingSupplier.id;
    }

    final result = await Get.dialog<String?>(
      AlertDialog(
        title: const Text('Seleccionar Proveedor'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String?>(
                  value: selectedSupplierId,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    border: OutlineInputBorder(),
                    helperText: 'Selecciona un proveedor o deja sin proveedor para pedido mixto',
                    helperMaxLines: 2,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'Sin proveedor (pedido mixto)',
                        style: TextStyle(
                          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    ..._controller.suppliers.map((supplier) {
                      return DropdownMenuItem<String?>(
                        value: supplier.id,
                        child: Text(supplier.nombre),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      selectedSupplierId = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Return the supplier name or empty string
              if (selectedSupplierId == null) {
                Get.back(result: '');
              } else {
                final supplier = _controller.suppliers.firstWhere(
                  (s) => s.id == selectedSupplierId,
                );
                Get.back(result: supplier.nombre);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      _providerController.text = result;
      _providerText.value = result;
    }
  }

  /// Show professional confirmation dialog for discarding changes
  /// Returns true if user chose to discard changes, false otherwise
  Future<bool> _showDiscardChangesDialog() async {
    final hasBasicChanges = _descriptionText.value.trim() != (_originalOrder?.description ?? '').trim() ||
                           _providerText.value.trim() != (_originalOrder?.provider ?? '').trim();
    final hasProductChanges = _hasProductChanges();

    // Count the number of changes
    List<String> changesList = [];
    if (_descriptionText.value.trim() != (_originalOrder?.description ?? '').trim()) {
      changesList.add('• Descripción modificada');
    }
    if (_providerText.value.trim() != (_originalOrder?.provider ?? '').trim()) {
      changesList.add('• Proveedor modificado');
    }
    if (hasProductChanges) {
      changesList.add('• Cambios en productos del pedido');
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
                'Cambios sin guardar',
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
              'Tienes los siguientes cambios pendientes:',
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
              '¿Estás seguro de que deseas salir sin guardar estos cambios?',
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
            child: const Text('Continuar editando'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Revert all changes
              _revertAllChanges();

              // Close dialog and return true to indicate changes were discarded
              Get.back(result: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.delete_sweep, size: 20),
            label: const Text('Descartar cambios'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Handle back navigation with unsaved changes
  Future<bool> _onWillPop() async {
    print('🔙 [EditOrder] _onWillPop called');

    final hasBasicChanges = _descriptionText.value.trim() != (_originalOrder?.description ?? '').trim() ||
                           _providerText.value.trim() != (_originalOrder?.provider ?? '').trim();
    final hasProductChanges = _hasProductChanges();

    print('📊 [EditOrder] hasBasicChanges: $hasBasicChanges, hasProductChanges: $hasProductChanges, hasUnsavedChanges: ${_hasUnsavedChanges.value}');

    if (!hasBasicChanges && !hasProductChanges && !_hasUnsavedChanges.value) {
      print('✅ [EditOrder] No changes detected, allowing navigation');
      return true; // Allow navigation - no changes
    }

    print('⚠️ [EditOrder] Changes detected, showing discard dialog');
    // Show professional confirmation dialog
    // Returns true if user discarded changes (changes are already reverted)
    // Returns false if user wants to continue editing
    final shouldDiscard = await _showDiscardChangesDialog();
    print('🔍 [EditOrder] User chose to discard: $shouldDiscard');
    return shouldDiscard;
  }

  /// Add product to order from scanner or selection (local draft)
  Future<void> _addProductToOrder(Product product) async {
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin;

    // Check if product already exists in the draft order
    final existingItemIndex = _draftOrderItems.indexWhere(
      (item) => item.actualProductId == product.id,
    );

    if (existingItemIndex != -1) {
      // Product exists, ask user if they want to update quantities
      final existing = _draftOrderItems[existingItemIndex];
      final isTemporaryProduct = existing.temporaryProductId != null;

      final existingController = TextEditingController(text: existing.existingQuantity.toString());
      final requestedController = TextEditingController(text: existing.requestedQuantity?.toString() ?? '');
      final selectedUnit = Rx<MeasurementUnit>(existing.measurementUnit);

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
                final existingQty = int.tryParse(existingController.text);

                // Para productos temporales, no hay "cantidad solicitada" adicional
                final requestedQty = isTemporaryProduct
                    ? null // Productos temporales no tienen requestedQuantity
                    : (isAdmin
                        ? (requestedController.text.isEmpty
                            ? null
                            : int.tryParse(requestedController.text))
                        : existing.requestedQuantity); // Mantener valor original para empleados

                if (existingQty != null && existingQty >= 0) {
                  Get.back(result: {
                    'existingQuantity': existingQty,
                    'requestedQuantity': requestedQty,
                    'measurementUnit': selectedUnit.value,
                  });
                } else {
                  Get.snackbar('Error', isTemporaryProduct
                      ? 'La cantidad solicitada debe ser un número válido'
                      : 'La cantidad existente debe ser un número válido');
                }
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );

      if (result != null) {
        // Update local draft item (no backend call)
        _draftOrderItems[existingItemIndex] = OrderItem(
          id: existing.id,
          orderId: existing.orderId,
          productId: existing.productId,
          temporaryProductId: existing.temporaryProductId,
          supplierId: existing.supplierId,
          supplier: existing.supplier,
          product: existing.product,
          temporaryProduct: existing.temporaryProduct,
          existingQuantity: result['existingQuantity']!,
          requestedQuantity: result['requestedQuantity'],
          measurementUnit: result['measurementUnit'] ?? existing.measurementUnit,
        );
        
        // Mark as having unsaved changes
        _hasUnsavedChanges.value = true;
        
        Get.snackbar(
          'Cambio local',
          'Producto actualizado. Presiona "Actualizar Pedido" para guardar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.primary,
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      // Product doesn't exist, add new
      // Check if this is a temporary product (precioA and iva are 0)
      final isTemporaryProduct = product.precioA == 0.0 && product.iva == 0.0;

      // For temporary products, default existing quantity to 0 (product doesn't exist yet)
      // For regular products, default to 1
      final existingController = TextEditingController(text: isTemporaryProduct ? '0' : '1');
      final requestedController = TextEditingController();
      final selectedUnit = Rx<MeasurementUnit>(MeasurementUnit.unidad);

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
                // Para productos temporales, el primer campo ya es la cantidad solicitada
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
                final existingQty = int.tryParse(existingController.text);

                // Para productos temporales, no hay "cantidad solicitada" adicional
                // La cantidad ingresada es la cantidad que se solicita (se guarda en existingQuantity)
                final requestedQty = isTemporaryProduct
                    ? null // Productos temporales no tienen requestedQuantity
                    : (isAdmin
                        ? (requestedController.text.isEmpty
                            ? null
                            : int.tryParse(requestedController.text))
                        : null); // Empleados no pueden agregar cantidad solicitada

                if (existingQty != null && existingQty >= 0) {
                  Get.back(result: {
                    'existingQuantity': existingQty,
                    'requestedQuantity': requestedQty,
                    'measurementUnit': selectedUnit.value,
                  });
                } else {
                  Get.snackbar('Error', isTemporaryProduct
                      ? 'La cantidad solicitada debe ser un número válido'
                      : 'La cantidad existente debe ser un número válido');
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      );

      if (result != null) {
        // Add new product to local draft (no backend call)
        // Check if this is a temporary product (precioA and iva are 0)
        final isTemporaryProduct = product.precioA == 0.0 && product.iva == 0.0;

        final newItem = OrderItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${product.id}', // Temporary ID
          orderId: _orderId!,
          productId: isTemporaryProduct ? null : product.id,
          temporaryProductId: isTemporaryProduct ? product.id : null,
          product: product,
          temporaryProduct: null, // Will be loaded from backend when order is refreshed
          existingQuantity: result['existingQuantity']!,
          requestedQuantity: result['requestedQuantity'],
          measurementUnit: result['measurementUnit'] ?? MeasurementUnit.unidad,
        );
        
        _draftOrderItems.add(newItem);
        
        // Mark as having unsaved changes
        _hasUnsavedChanges.value = true;
        
        Get.snackbar(
          'Producto agregado localmente',
          '${product.description} agregado. Presiona "Actualizar Pedido" para guardar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.primary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  /// Show product selection sheet for multiple products
  void _showProductSelectionSheet() {
    final authController = Get.find<AuthController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

        print('🚀 [EditOrder] Creating temporary product: $temporaryProductData');

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
            print('✅ [EditOrder] Temporary product created: ${temporaryProduct['id']}');

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
        print('💥 [EditOrder] Exception creating temporary product: $e');
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

  /// Remove product from order (local draft)
  Future<void> _removeProductFromOrder(OrderItem item) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres quitar "${item.productDescription}" del pedido?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Remove from local draft list (no backend call)
      _draftOrderItems.removeWhere((orderItem) => orderItem.productId == item.productId);
      
      // Mark as having unsaved changes
      _hasUnsavedChanges.value = true;
      
      Get.snackbar(
        'Producto removido localmente',
        'Producto quitado. Presiona "Actualizar Pedido" para guardar',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Edit quantities for an order item
  Future<void> _editQuantities(OrderItem item) async {
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin;

    // Detectar si es un producto temporal
    final isTemporaryProduct = item.temporaryProductId != null;

    final existingController = TextEditingController(text: item.existingQuantity.toString());
    final requestedController = TextEditingController(text: item.requestedQuantity?.toString() ?? '');
    final selectedUnit = Rx<MeasurementUnit>(item.measurementUnit);

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Editar cantidades'),
            const SizedBox(height: 8),
            Text(
              item.productDescription,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            if (isTemporaryProduct) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Producto nuevo - No existe en inventario',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
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
                  helperText: isTemporaryProduct ? 'El producto aún no existe en inventario' : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              // Solo mostrar campo de cantidad solicitada a administradores
              // y solo si NO es un producto temporal
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
              final existingQty = int.tryParse(existingController.text);

              // Para empleados, mantener la cantidad solicitada original
              // Para admins con productos temporales, no hay cantidad solicitada separada
              // Para admins con productos regulares, permitir cambiarla
              final requestedQty = isTemporaryProduct
                  ? null
                  : (isAdmin
                      ? (requestedController.text.isEmpty
                          ? null
                          : int.tryParse(requestedController.text))
                      : item.requestedQuantity); // Mantener valor original para empleados

              if (existingQty != null && existingQty >= 0) {
                Get.back(result: {
                  'existingQuantity': existingQty,
                  'requestedQuantity': requestedQty,
                  'measurementUnit': selectedUnit.value,
                });
              } else {
                Get.snackbar(
                  'Error',
                  isTemporaryProduct
                      ? 'La cantidad solicitada debe ser un número válido'
                      : 'La cantidad existente debe ser un número válido',
                );
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Update local draft item (no backend call)
      final itemIndex = _draftOrderItems.indexWhere((orderItem) => orderItem.actualProductId == item.actualProductId);
      if (itemIndex != -1) {
        print('🔵 [Dialog] Updating draft item for: ${item.productDescription}');
        print('🔵 [Dialog] Old measurementUnit: ${item.measurementUnit}');
        print('🔵 [Dialog] New measurementUnit from dialog: ${result['measurementUnit']}');
        print('🔵 [Dialog] existingQuantity: ${result['existingQuantity']}, requestedQuantity: ${result['requestedQuantity']}');

        _draftOrderItems[itemIndex] = OrderItem(
          id: item.id,
          orderId: item.orderId,
          productId: item.productId,
          temporaryProductId: item.temporaryProductId,
          supplierId: item.supplierId,
          supplier: item.supplier,
          product: item.product,
          temporaryProduct: item.temporaryProduct,
          existingQuantity: result['existingQuantity']!,
          requestedQuantity: result['requestedQuantity'],
          measurementUnit: result['measurementUnit'] ?? item.measurementUnit,
        );

        print('🔵 [Dialog] Updated draft item measurementUnit: ${_draftOrderItems[itemIndex].measurementUnit}');

        // Mark as having unsaved changes
        _hasUnsavedChanges.value = true;

        Get.snackbar(
          'Cantidades actualizadas localmente',
          'Cambios guardados. Presiona "Actualizar Pedido" para confirmar',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.primary,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  /// Check if products have changed compared to original order
  bool _hasProductChanges() {
    if (_originalOrder == null) return false;
    
    final originalItems = _originalOrder!.items;
    final draftItems = _draftOrderItems;
    
    // Different number of items
    if (originalItems.length != draftItems.length) {
      print('📊 [EditOrder] Item count changed: ${originalItems.length} -> ${draftItems.length}');
      return true;
    }
    
    // Check if any item is different
    for (int i = 0; i < originalItems.length; i++) {
      final original = originalItems[i];
      final draftIndex = draftItems.indexWhere((item) => item.actualProductId == original.actualProductId);

      if (draftIndex == -1) {
        print('🔄 [EditOrder] Product removed: ${original.productDescription}');
        return true;
      }

      final draft = draftItems[draftIndex];

      // Debug logging for change detection
      print('🟢 [HasChanges] Checking: ${original.productDescription}');
      print('🟢 [HasChanges] Original - existingQty: ${original.existingQuantity}, requestedQty: ${original.requestedQuantity}, unit: ${original.measurementUnit}, supplierId: ${original.supplierId}');
      print('🟢 [HasChanges] Draft    - existingQty: ${draft.existingQuantity}, requestedQty: ${draft.requestedQuantity}, unit: ${draft.measurementUnit}, supplierId: ${draft.supplierId}');

      if (original.existingQuantity != draft.existingQuantity ||
          original.requestedQuantity != draft.requestedQuantity ||
          original.measurementUnit != draft.measurementUnit ||
          original.supplierId != draft.supplierId) {
        print('🔧 [EditOrder] Product modified: ${original.productDescription}');
        return true;
      }
    }

    // Check for new products (those with temporary IDs or not in original)
    // Exclude unregistered products
    for (final draft in draftItems) {
      final actualId = draft.actualProductId;

      // Skip unregistered/pending products
      if (actualId.startsWith('unregistered_') ||
          actualId.startsWith('pending_')) {
        continue;
      }

      final isNew = draft.id.startsWith('temp_') ||
                   !originalItems.any((item) => item.actualProductId == draft.actualProductId);
      if (isNew) {
        print('➕ [EditOrder] New product added: ${draft.productDescription}');
        return true;
      }
    }
    
    print('⚪ [EditOrder] No product changes detected');
    return false;
  }

  /// Update supplier for an order item (ADMIN only, mixed orders only)
  void _updateItemSupplier(OrderItem item, String? supplierId) {
    final itemIndex = _draftOrderItems.indexWhere(
      (orderItem) => orderItem.actualProductId == item.actualProductId,
    );

    if (itemIndex != -1) {
      final currentItem = _draftOrderItems[itemIndex];

      // Find supplier object if supplierId is provided
      Supplier? selectedSupplier;
      if (supplierId != null) {
        selectedSupplier = _controller.suppliers
            .firstWhereOrNull((s) => s.id == supplierId);
      }

      _draftOrderItems[itemIndex] = OrderItem(
        id: currentItem.id,
        orderId: currentItem.orderId,
        productId: currentItem.productId,
        temporaryProductId: currentItem.temporaryProductId,
        supplierId: supplierId,
        supplier: selectedSupplier,
        product: currentItem.product,
        temporaryProduct: currentItem.temporaryProduct,
        existingQuantity: currentItem.existingQuantity,
        requestedQuantity: currentItem.requestedQuantity,
        measurementUnit: currentItem.measurementUnit,
      );

      // Mark as having unsaved changes
      _hasUnsavedChanges.value = true;

      print(
        '🔧 [EditOrder] Updated supplier for ${item.productDescription}: ${selectedSupplier?.nombre ?? "Sin asignar"}',
      );
    }
  }

  /// Apply all product changes to the backend
  Future<bool> _applyProductChanges() async {
    if (_originalOrder == null) return false;
    
    try {
      final originalItems = _originalOrder!.items;
      final draftItems = _draftOrderItems;
      
      // 1. Handle removed products
      for (final original in originalItems) {
        final stillExists = draftItems.any((draft) => draft.productId == original.productId);
        if (!stillExists && original.id != null) {
          print('🗑️ [EditOrder] Removing product: ${original.productDescription}');
          final success = await _controller.removeProductFromExistingOrder(_orderId!, original.id!);
          if (!success) {
            print('❌ [EditOrder] Failed to remove product: ${original.productDescription}');
            return false;
          }
        }
      }
      
      // 2. Handle new products (those with temporary IDs or not in original)
      // Skip unregistered products (they should have been converted to tasks already)
      for (final draft in draftItems) {
        final actualId = draft.actualProductId;

        // Skip if it's an unregistered product
        if (actualId.startsWith('unregistered_') ||
            actualId.startsWith('pending_')) {
          print('⏭️ [EditOrder] Skipping unregistered product: ${draft.productDescription}');
          continue;
        }

        final isNew = draft.id.startsWith('temp_') ||
                     !originalItems.any((original) => original.actualProductId == draft.actualProductId);
        if (isNew) {
          print('➕ [EditOrder] Adding new product: ${draft.productDescription}');
          print('🔍 [EditOrder] Product details - productId: ${draft.productId}, temporaryProductId: ${draft.temporaryProductId}');

          // Determine if this is a temporary product or a regular product
          final success = await _controller.addProductToExistingOrder(
            _orderId!,
            draft.productId,
            draft.existingQuantity,
            draft.requestedQuantity,
            draft.measurementUnit.name,
            temporaryProductId: draft.temporaryProductId,
            supplierId: draft.supplierId,
          );
          if (!success) {
            print('❌ [EditOrder] Failed to add product: ${draft.productDescription}');
            return false;
          }
        }
      }
      
      // 3. Handle modified products (only existing products, not new ones)
      for (final draft in draftItems) {
        // Skip new products with temporary IDs
        if (draft.id.startsWith('temp_')) continue;

        final original = originalItems.where((orig) => orig.actualProductId == draft.actualProductId).firstOrNull;
        if (original != null) {
          // Debug logging for change detection
          print('🔍 [Debug] Product: ${draft.productDescription}');
          print('🔍 [Debug] Original - existingQty: ${original.existingQuantity}, requestedQty: ${original.requestedQuantity}, unit: ${original.measurementUnit}, supplierId: ${original.supplierId}');
          print('🔍 [Debug] Draft    - existingQty: ${draft.existingQuantity}, requestedQty: ${draft.requestedQuantity}, unit: ${draft.measurementUnit}, supplierId: ${draft.supplierId}');
          print('🔍 [Debug] Comparison - existingQty changed: ${original.existingQuantity != draft.existingQuantity}');
          print('🔍 [Debug] Comparison - requestedQty changed: ${original.requestedQuantity != draft.requestedQuantity}');
          print('🔍 [Debug] Comparison - unit changed: ${original.measurementUnit != draft.measurementUnit}');
          print('🔍 [Debug] Comparison - supplierId changed: ${original.supplierId != draft.supplierId}');

          final hasChanged = original.existingQuantity != draft.existingQuantity ||
                           original.requestedQuantity != draft.requestedQuantity ||
                           original.measurementUnit != draft.measurementUnit ||
                           original.supplierId != draft.supplierId;

          print('🔍 [Debug] hasChanged: $hasChanged');

          if (hasChanged) {
            print('🔧 [EditOrder] Updating product: ${draft.productDescription}');
            final success = await _controller.updateExistingOrderItemQuantities(
              _orderId!,
              original.id,
              draft.existingQuantity,
              draft.requestedQuantity,
              draft.measurementUnit,
              supplierId: draft.supplierId,
            );
            if (!success) {
              print('❌ [EditOrder] Failed to update product: ${draft.productDescription}');
              return false;
            }
          }
        }
      }
      
      return true;
    } catch (e) {
      print('💥 [EditOrder] Exception applying product changes: $e');
      return false;
    }
  }

  /// Update the order
  Future<void> _updateOrder() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔄 [EditOrder] Updating order with all changes');

    // Validate products have suppliers in mixed orders (only for admins)
    final isMixedOrder = _providerController.text.trim().isEmpty;
    final isAdmin = _controller.canPerformAdminActions();
    if (isMixedOrder && isAdmin) {
      final productsWithoutSupplier = _draftOrderItems
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

    // Check if basic info has changed (only check description and provider)
    final hasBasicChanges =
        _descriptionController.text.trim() != (_originalOrder!.description ?? '').trim() ||
        _providerController.text.trim() != (_originalOrder!.provider ?? '').trim();

    final hasProductChanges = _hasProductChanges();

    // If no changes at all, just go back
    if (!hasBasicChanges && !hasProductChanges) {
      Get.snackbar(
        'Sin cambios',
        'No hay cambios para guardar',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.secondary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.secondary,
      );
      return;
    }

    // Apply basic info changes if any
    if (hasBasicChanges) {
      final success = await _controller.updateOrder(
        id: _orderId!,
        description: _descriptionController.text.trim(),
        provider: _providerController.text.trim().isEmpty
            ? null
            : _providerController.text.trim(),
      );

      if (!success) {
        print('❌ [EditOrder] Failed to update order basic info');
        Get.snackbar(
          'Error',
          'No se pudo actualizar la información del pedido',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
        return;
      }
    }

    // Apply product changes if any
    if (hasProductChanges) {
      final success = await _applyProductChanges();
      if (!success) {
        Get.snackbar(
          'Error',
          'No se pudieron aplicar los cambios de productos',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
        return;
      }
    }

    print('✅ [EditOrder] All changes applied successfully');

    // Reset unsaved changes flag
    _hasUnsavedChanges.value = false;

    // Always refresh the orders list to show changes
    await _controller.loadOrders(refresh: true);

    // Show success message before navigation
    Get.snackbar(
      'Éxito',
      'Pedido actualizado exitosamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
      colorText: Get.theme.colorScheme.primary,
      duration: const Duration(seconds: 2),
    );

    // Return to orders list
    Get.offNamed('/orders');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'Cargando pedido...'));
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() {
            final hasChanges = _hasUnsavedChanges.value ||
                              _hasProductChanges() ||
                              (_descriptionText.value.trim() != (_originalOrder?.description ?? '').trim()) ||
                              (_providerText.value.trim() != (_originalOrder?.provider ?? '').trim());

            return LayoutBuilder(
              builder: (context, constraints) {
                // Detectar pantalla pequeña (menos de 600px de ancho)
                final isSmallScreen = MediaQuery.of(context).size.width < 600;

                return Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Editar Pedido',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasChanges) ...[
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Get.theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Get.theme.colorScheme.error.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_note,
                              size: isSmallScreen ? 14 : 16,
                              color: Get.theme.colorScheme.error,
                            ),
                            if (!isSmallScreen) ...[
                              const SizedBox(width: 4),
                              Text(
                                'Cambios pendientes',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Get.theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          }),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Verificar si hay cambios pendientes antes de navegar
              final shouldPop = await _onWillPop();
              if (shouldPop) {
                // Solo navegar si el usuario confirmó descartar cambios o no hay cambios
                Get.offNamed('/orders');
              }
            },
          ),
        ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
            // Form Section - Compact Design
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description - Compact Inline Edit
                  InkWell(
                    onTap: () => _editDescription(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Get.theme.colorScheme.outline.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: MediaQuery.of(context).size.width < 600 ? 18 : 20,
                            color: Get.theme.colorScheme.primary,
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width < 600 ? 8 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Descripción',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 600 ? 10 : 11,
                                    color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Obx(() => Text(
                                  _descriptionText.value.isEmpty ? 'Sin descripción' : _descriptionText.value,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 600 ? 13 : 14,
                                    color: _descriptionText.value.isEmpty
                                      ? Get.theme.colorScheme.onSurface.withOpacity(0.4)
                                      : Get.theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit,
                            size: MediaQuery.of(context).size.width < 600 ? 16 : 18,
                            color: Get.theme.colorScheme.primary.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 8 : 12),

                  // Supplier Dropdown - Same as create_order_page
                  Obx(() {
                    final isLoadingSuppliers = _controller.isLoadingSuppliers.value;
                    final suppliers = _controller.suppliers;
                    final isSmallScreen = MediaQuery.of(context).size.width < 600;

                    // Check if there are products with individual suppliers assigned
                    final hasProductsWithSuppliers = _draftOrderItems.any((item) => item.supplierId != null);
                    final isDropdownDisabled = isLoadingSuppliers || hasProductsWithSuppliers;

                    // Find supplier ID from provider text
                    String? currentSupplierId;
                    if (_providerText.value.isNotEmpty) {
                      try {
                        final matchingSupplier = suppliers.firstWhere(
                          (s) => s.nombre == _providerText.value,
                        );
                        currentSupplierId = matchingSupplier.id;
                      } catch (e) {
                        currentSupplierId = null;
                      }
                    }

                    return DropdownButtonFormField<String>(
                      value: currentSupplierId,
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
                          : currentSupplierId != null
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
                            // Update provider text based on selected supplier
                            if (value == null) {
                              _providerController.text = '';
                              _providerText.value = '';
                            } else {
                              final supplier = suppliers.firstWhere((s) => s.id == value);
                              _providerController.text = supplier.nombre;
                              _providerText.value = supplier.nombre;
                            }
                          },
                    );
                  }),

                  SizedBox(height: MediaQuery.of(context).size.width < 600 ? 8 : 12),

                  // Add Product Button - Compact
                  Obx(() {
                    // Disable button if there are products without supplier in mixed orders (only for admins)
                    final isMixedOrder = _providerText.value.trim().isEmpty;
                    final isAdmin = _controller.canPerformAdminActions();
                    final hasProductsWithoutSupplier = isMixedOrder &&
                        isAdmin &&
                        _draftOrderItems.any((item) => item.supplierId == null);

                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: hasProductsWithoutSupplier ? null : _showProductSelectionSheet,
                        icon: Icon(
                          Icons.add_shopping_cart,
                          size: MediaQuery.of(context).size.width < 600 ? 16 : 18,
                        ),
                        label: Text(
                          MediaQuery.of(context).size.width < 600 ? 'Agregar' : 'Agregar Producto',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width < 600 ? 12 : AppConfig.paddingMedium,
                            vertical: MediaQuery.of(context).size.width < 600 ? 8 : 12,
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
                    );
                  }),
                ],
              ),
            ),

            // Products Section
            Expanded(
              child: Column(
                children: [
                  // Products Header - Responsive
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.primaryContainer.withOpacity(0.3),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          color: Get.theme.colorScheme.primary,
                          size: MediaQuery.of(context).size.width < 600 ? 16 : 18,
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width < 600 ? 6 : 8),
                        Flexible(
                          child: Text(
                            MediaQuery.of(context).size.width < 600 ? 'Productos' : 'Productos del Pedido',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: Get.theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Obx(
                          () => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width < 600 ? 6 : 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Get.theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_draftOrderItems.length}',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 12,
                                fontWeight: FontWeight.bold,
                                color: Get.theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Products List
                  Expanded(
                    child: Obx(() {
                      if (_draftOrderItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Get.theme.colorScheme.outline,
                              ),
                              const SizedBox(height: AppConfig.paddingMedium),
                              Text(
                                'No hay productos en el pedido',
                                style: TextStyle(
                                  fontSize: AppConfig.bodyFontSize,
                                  color: Get.theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: AppConfig.paddingSmall),
                              Text(
                                'Usa el botón "Agregar Producto" para añadir productos',
                                style: TextStyle(
                                  fontSize: AppConfig.captionFontSize,
                                  color: Get.theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: _scrollController,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 12),
                        itemCount: _draftOrderItems.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: MediaQuery.of(context).size.width < 600 ? 6 : 8),
                        itemBuilder: (context, index) {
                          final item = _draftOrderItems[index];
                          final isSmallScreen = MediaQuery.of(context).size.width < 600;

                          return Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.productDescription,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 13 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: Get.theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeProductFromOrder(item),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Get.theme.colorScheme.error,
                                          size: isSmallScreen ? 18 : 20,
                                        ),
                                        padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                                        constraints: BoxConstraints(
                                          minWidth: isSmallScreen ? 32 : 40,
                                          minHeight: isSmallScreen ? 32 : 40,
                                        ),
                                        tooltip: 'Quitar',
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Cantidad: ${item.existingQuantity}',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 12,
                                            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 6 : 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Get.theme.colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.measurementUnit.displayName,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            color: Get.theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Mostrar proveedor asignado (solo ADMIN en pedidos mixtos)
                                  Builder(
                                    builder: (context) {
                                      try {
                                        final authController = Get.find<AuthController>();
                                        final isMixedOrder = _originalOrder?.provider == null || _originalOrder!.provider!.isEmpty;

                                        if (authController.isAdmin && isMixedOrder && item.supplier != null) {
                                          return Padding(
                                            padding: EdgeInsets.only(top: isSmallScreen ? 4 : 6),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.local_shipping,
                                                  size: isSmallScreen ? 12 : 14,
                                                  color: Get.theme.colorScheme.tertiary,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Proveedor: ${item.supplier!.nombre}',
                                                    style: TextStyle(
                                                      fontSize: isSmallScreen ? 10 : 11,
                                                      color: Get.theme.colorScheme.tertiary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      } catch (e) {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                  // Solo mostrar cantidad solicitada a administradores
                                  if (item.requestedQuantity != null) ...[
                                    Builder(
                                      builder: (context) {
                                        try {
                                          final authController = Get.find<AuthController>();
                                          if (authController.isAdmin) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: isSmallScreen ? 2 : 4),
                                                Text(
                                                  'Solicitada: ${item.requestedQuantity}',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 11 : 12,
                                                    color: Get.theme.colorScheme.secondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        } catch (e) {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    ),
                                  ],
                                  // Supplier selector (solo para ADMIN en pedidos mixtos)
                                  Builder(
                                    builder: (context) {
                                      try {
                                        final authController = Get.find<AuthController>();
                                        // Solo mostrar si es ADMIN y no hay proveedor general
                                        final showSupplierSelector = authController.isAdmin &&
                                            (_originalOrder?.provider == null || _originalOrder!.provider!.isEmpty);

                                        if (showSupplierSelector) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: isSmallScreen ? 6 : 8),
                                              DropdownButtonFormField<String>(
                                                value: item.supplierId,
                                                isDense: true,
                                                decoration: InputDecoration(
                                                  labelText: 'Proveedor',
                                                  labelStyle: TextStyle(fontSize: isSmallScreen ? 10 : 11),
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: isSmallScreen ? 8 : 10,
                                                    vertical: isSmallScreen ? 4 : 6,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  filled: true,
                                                  fillColor: Get.theme.colorScheme.surface,
                                                ),
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 11 : 12,
                                                  color: Get.theme.colorScheme.onSurface,
                                                ),
                                                hint: Text(
                                                  'Sin asignar',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 11 : 12,
                                                    color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                                                  ),
                                                ),
                                                items: [
                                                  // Opción "Sin asignar"
                                                  const DropdownMenuItem<String>(
                                                    value: null,
                                                    child: Text('Sin asignar'),
                                                  ),
                                                  // Lista de proveedores
                                                  ..._controller.suppliers.map((supplier) {
                                                    return DropdownMenuItem<String>(
                                                      value: supplier.id,
                                                      child: Text(
                                                        supplier.nombre,
                                                        style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                                                      ),
                                                    );
                                                  }),
                                                ],
                                                onChanged: (supplierId) {
                                                  _updateItemSupplier(item, supplierId);
                                                },
                                              ),
                                            ],
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      } catch (e) {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                  SizedBox(height: isSmallScreen ? 6 : 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _editQuantities(item),
                                      icon: Icon(Icons.edit, size: isSmallScreen ? 14 : 16),
                                      label: Text(
                                        isSmallScreen ? 'Editar' : 'Editar cantidades',
                                        style: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 8 : 12,
                                          vertical: isSmallScreen ? 6 : 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Action Buttons - Responsive
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 12),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Get.theme.colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Builder(
                builder: (context) {
                  final isSmallScreen = MediaQuery.of(context).size.width < 600;

                  return Row(
                    children: [
                      Expanded(
                        child: Obx(() {
                          final hasChanges = _hasUnsavedChanges.value ||
                                            _hasProductChanges() ||
                                            (_descriptionText.value.trim() != (_originalOrder?.description ?? '').trim()) ||
                                            (_providerText.value.trim() != (_originalOrder?.provider ?? '').trim());

                          return OutlinedButton.icon(
                            onPressed: hasChanges ? () async {
                              // Mostrar diálogo de confirmación para descartar cambios
                              final shouldDiscard = await _showDiscardChangesDialog();
                              if (shouldDiscard) {
                                // Navegar a la lista de pedidos
                                Get.offNamed('/orders');
                              }
                            } : null,
                            icon: Icon(
                              Icons.close,
                              size: isSmallScreen ? 16 : 18,
                              color: hasChanges ? Get.theme.colorScheme.error : null,
                            ),
                            label: Text(
                              isSmallScreen ? 'Cancelar' : 'Cancelar',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: hasChanges ? Get.theme.colorScheme.error : null,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 12,
                                vertical: isSmallScreen ? 8 : 12,
                              ),
                              foregroundColor: hasChanges ? Get.theme.colorScheme.error : null,
                              side: BorderSide(
                                color: hasChanges
                                  ? Get.theme.colorScheme.error.withOpacity(0.5)
                                  : Get.theme.colorScheme.outline.withOpacity(0.3),
                              ),
                              disabledForegroundColor: Get.theme.colorScheme.onSurface.withOpacity(0.38),
                            ),
                          );
                        }),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        flex: isSmallScreen ? 1 : 2,
                        child: Obx(() {
                          final hasChanges = _hasUnsavedChanges.value ||
                                            _hasProductChanges() ||
                                            (_descriptionText.value.trim() != (_originalOrder?.description ?? '').trim()) ||
                                            (_providerText.value.trim() != (_originalOrder?.provider ?? '').trim());

                          // Check if there are products without supplier in mixed orders (only for admins)
                          final isMixedOrder = _providerText.value.trim().isEmpty;
                          final isAdmin = _controller.canPerformAdminActions();
                          final hasProductsWithoutSupplier = isMixedOrder &&
                              isAdmin &&
                              _draftOrderItems.any((item) => item.supplierId == null);

                          return ElevatedButton(
                            onPressed:
                                _controller.isUpdatingOrder.value ||
                                    _descriptionText.value.trim().isEmpty ||
                                    hasProductsWithoutSupplier
                                ? null
                                : _updateOrder,
                            style: hasChanges
                                ? ElevatedButton.styleFrom(
                                    backgroundColor: Get.theme.colorScheme.primary,
                                    foregroundColor: Get.theme.colorScheme.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: isSmallScreen ? 12 : 14,
                                    ),
                                  )
                                : ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: isSmallScreen ? 12 : 14,
                                    ),
                                  ),
                            child: _controller.isUpdatingOrder.value
                                ? SizedBox(
                                    height: isSmallScreen ? 16 : 18,
                                    width: isSmallScreen ? 16 : 18,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        hasChanges ? Icons.save : Icons.check_circle_outline,
                                        size: isSmallScreen ? 16 : 18,
                                      ),
                                      if (!isSmallScreen) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          hasChanges ? 'Guardar' : 'Actualizar',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                      if (isSmallScreen) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          hasChanges ? 'Guardar' : 'Actualizar',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          ),
        ),
      ),
      ),
    );
  }
}
