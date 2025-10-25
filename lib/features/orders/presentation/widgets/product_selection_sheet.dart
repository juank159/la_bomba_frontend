import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../products/domain/entities/product.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/orders_controller.dart';

/// Bottom sheet for searching and selecting products to add to order
class ProductSelectionSheet extends StatefulWidget {
  final Function(Product) onProductSelected;
  final Function(String)? onUnregisteredProductAdded;

  const ProductSelectionSheet({
    super.key,
    required this.onProductSelected,
    this.onUnregisteredProductAdded,
  });

  @override
  State<ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Clear previous search and load initial products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<OrdersController>().searchProducts('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConfig.borderRadiusLarge),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppConfig.paddingSmall),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            child: Row(
              children: [
                Icon(Icons.search, color: Get.theme.colorScheme.primary),
                const SizedBox(width: AppConfig.paddingSmall),
                Text(
                  'Buscar Productos',
                  style: TextStyle(
                    fontSize: AppConfig.headingFontSize,
                    fontWeight: FontWeight.w600,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),

          // Botón para añadir producto no registrado (solo admin)
          if (isAdmin && widget.onUnregisteredProductAdded != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingMedium),
              child: OutlinedButton.icon(
                onPressed: () => _showAddUnregisteredProductDialog(context),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Añadir producto no registrado'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  side: BorderSide(color: Colors.orange.shade600, width: 1.5),
                  foregroundColor: Colors.orange.shade700,
                ),
              ),
            ),
          if (isAdmin && widget.onUnregisteredProductAdded != null)
            const SizedBox(height: AppConfig.paddingSmall),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConfig.paddingMedium,
            ),
            child: CustomInput(
              controller: _searchController,
              hintText: 'Buscar por nombre o código de barras...',
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) {
                controller.searchProducts(value);
              },
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        controller.searchProducts('');
                      },
                      icon: const Icon(Icons.clear, size: 20),
                    ),
                  IconButton(
                    onPressed: _startBarcodeScanning,
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Escanear código de barras',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConfig.paddingMedium),

          // Products List
          Expanded(
            child: Obx(() {
              if (controller.isSearchingProducts.value) {
                return const LoadingWidget(message: 'Buscando productos...');
              }

              if (controller.availableProducts.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConfig.paddingMedium,
                ),
                itemCount: controller.availableProducts.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = controller.availableProducts[index];
                  return _buildProductTile(product);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConfig.paddingMedium,
        vertical: AppConfig.paddingSmall,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppConfig.paddingSmall),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Icon(
          Icons.inventory_2,
          size: 20,
          color: Get.theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        product.description,
        style: TextStyle(
          fontSize: AppConfig.bodyFontSize,
          fontWeight: FontWeight.w500,
          color: Get.theme.colorScheme.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: product.barcode.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 14,
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    product.barcode,
                    style: TextStyle(
                      fontSize: AppConfig.smallFontSize,
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            )
          : null,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConfig.paddingSmall,
              vertical: AppConfig.paddingSmall / 2,
            ),
            decoration: BoxDecoration(
              color: product.isActive
                  ? AppConfig.successColor.withOpacity(0.1)
                  : AppConfig.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
            ),
            child: Text(
              product.statusText,
              style: TextStyle(
                fontSize: AppConfig.smallFontSize,
                fontWeight: FontWeight.w600,
                color: product.isActive
                    ? AppConfig.successColor
                    : AppConfig.errorColor,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        if (product.isActive) {
          Navigator.of(context).pop(); // Close the sheet first
          widget.onProductSelected(product);
        } else {
          Get.snackbar(
            'Producto Inactivo',
            'Este producto no está disponible para pedidos',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
            colorText: Get.theme.colorScheme.error,
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    final controller = Get.find<OrdersController>();
    final hasSearchQuery = controller.productSearchQuery.value.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchQuery ? Icons.search_off : Icons.inventory,
              size: 64,
              color: Get.theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            Text(
              hasSearchQuery
                  ? 'No se encontraron productos'
                  : 'Busca productos',
              style: TextStyle(
                fontSize: AppConfig.headingFontSize,
                fontWeight: FontWeight.w600,
                color: Get.theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            Text(
              hasSearchQuery
                  ? 'Intenta con otros términos de búsqueda o escanea un código de barras'
                  : 'Escribe el nombre del producto o escanea su código de barras',
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingLarge),
            ElevatedButton.icon(
              onPressed: _startBarcodeScanning,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear Código'),
            ),
          ],
        ),
      ),
    );
  }

  void _startBarcodeScanning() {
    Navigator.of(context).pop(); // Close the sheet first
    Get.find<OrdersController>().startBarcodeScanning();
  }

  void _showAddUnregisteredProductDialog(BuildContext context) {
    final productNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_box, color: Colors.orange.shade700, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Producto no registrado',
                style: TextStyle(fontSize: 18),
              ),
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
                'Ingresa el nombre del producto que necesitas pero que no está registrado en el sistema.',
                style: TextStyle(
                  fontSize: 13,
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se creará una tarea para que el supervisor registre este producto',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: productNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  hintText: 'Ej: Detergente Ariel 500g',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre del producto es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
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
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final productName = productNameController.text.trim();
                Get.back();
                Navigator.of(context).pop(); // Cerrar el sheet
                widget.onUnregisteredProductAdded?.call(productName);
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir al pedido'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
