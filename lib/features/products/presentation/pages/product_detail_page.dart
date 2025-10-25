// lib/features/products/presentation/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../../domain/entities/product.dart';
import '../controllers/products_controller.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../supervisor/domain/entities/product_update_task.dart';
import '../../../supervisor/domain/usecases/create_task.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// ProductDetailPage - Detailed view of a single product
/// Shows complete product information including all metadata
/// Supports loading product by ID when product object is not provided
class ProductDetailPage extends StatefulWidget {
  final Product? product;
  final String? productId;

  const ProductDetailPage({super.key, this.product, this.productId})
    : assert(
        product != null || productId != null,
        'Either product or productId must be provided',
      );

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductsController controller;
  late AuthController authController;
  Product? currentProduct;

  // Map to accumulate pending changes (prices as double, description as String, iva as double)
  final Map<String, dynamic> _pendingChanges = {};
  bool get hasPendingChanges => _pendingChanges.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Initialize products controller if not already exists
    if (!Get.isRegistered<ProductsController>()) {
      Get.put(
        ProductsController(
          getProductsUseCase: getIt<GetProductsUseCase>(),
          getProductByIdUseCase: getIt<GetProductByIdUseCase>(),
          updateProductUseCase: getIt<UpdateProductUseCase>(),
        ),
        permanent: true,
      );
    }
    controller = Get.find<ProductsController>();

    // Get auth controller to check user role
    authController = Get.find<AuthController>();

    if (widget.product != null) {
      currentProduct = widget.product;
    } else if (widget.productId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductById();
      });
    }
  }

  /// Load product by ID if not provided
  Future<void> _loadProductById() async {
    await controller.getProductById(widget.productId!);
    // Update currentProduct after loading
    if (controller.selectedProduct.value != null) {
      setState(() {
        currentProduct = controller.selectedProduct.value;
      });
      print('✅ currentProduct updated after load: ${currentProduct?.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (hasPendingChanges) {
          return await _showDiscardChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: hasPendingChanges
            ? _buildPendingChangesBottomBar()
            : null,
      ),
    );
  }

  /// Build app bar with product title and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          if (hasPendingChanges) {
            final shouldPop = await _showDiscardChangesDialog();
            if (shouldPop) {
              Get.back();
            }
          } else {
            Get.back();
          }
        },
      ),
      title: Text(
        currentProduct?.description ?? 'Producto',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        // More options menu
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'copy_barcode',
              child: Row(
                children: [
                  const Icon(Icons.copy_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text('Copiar código'),
                ],
              ),
            ),
            if (currentProduct != null) ...[
              PopupMenuItem(
                value: currentProduct!.isActive ? 'deactivate' : 'activate',
                child: Row(
                  children: [
                    Icon(
                      currentProduct!.isActive
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(currentProduct!.isActive ? 'Desactivar' : 'Activar'),
                  ],
                ),
              ),
            ],
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(Icons.share_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Text('Compartir'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build main body content
  Widget _buildBody() {
    // Show loading if product is being fetched by ID
    if (currentProduct == null && widget.productId != null) {
      return Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget(message: 'Cargando producto...');
        }

        if (controller.selectedProduct.value != null) {
          return _buildProductContent(controller.selectedProduct.value!);
        }

        // Error loading product
        return _buildErrorState();
      });
    }

    // Show product content if available
    if (currentProduct != null) {
      return _buildProductContent();
    }

    // Fallback error state
    return _buildErrorState();
  }

  /// Build product content
  Widget _buildProductContent([Product? product]) {
    final productToUse = product ?? currentProduct!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(productToUse),
          const SizedBox(height: AppConfig.paddingLarge),
          _buildProductInfo(productToUse),
          const SizedBox(height: AppConfig.paddingLarge),
          _buildPricingInfo(productToUse),
          const SizedBox(height: AppConfig.paddingLarge),
          _buildProductMetadata(productToUse),
        ],
      ),
    );
  }

  /// Build product header with image placeholder and basic info
  Widget _buildProductHeader(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Center(
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Imagen no disponible',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConfig.paddingLarge),

            // Product title (editable for admins)
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.description,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (authController.isAdmin)
                  IconButton(
                    onPressed: () => _editProductName(product.description),
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Editar nombre del producto',
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: AppConfig.paddingSmall),

            // Status chip
            _buildStatusChip(product),
          ],
        ),
      ),
    );
  }

  /// Build status chip
  Widget _buildStatusChip(Product product) {
    final isActive = product.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppConfig.successColor.withOpacity(0.1)
            : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppConfig.successColor.withOpacity(0.3)
              : Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppConfig.successColor
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            product.statusText,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isActive
                  ? AppConfig.successColor
                  : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build product information section
  Widget _buildProductInfo(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Producto',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConfig.paddingMedium),

            _buildInfoRow(
              'Descripción',
              product.description,
              Icons.description_outlined,
              isSelectable: true,
            ),
            const SizedBox(height: AppConfig.paddingMedium),

            _buildInfoRow(
              'Código de Barras',
              product.barcode,
              Icons.qr_code_outlined,
              isSelectable: true,
              onTap: () =>
                  _copyToClipboard(product.barcode, 'Código de barras'),
            ),
            const SizedBox(height: AppConfig.paddingMedium),

            _buildInfoRow(
              'Estado',
              product.statusText,
              product.isActive
                  ? Icons.check_circle_outlined
                  : Icons.cancel_outlined,
            ),
          ],
        ),
      ),
    );
  }

  /// Build pricing information section
  Widget _buildPricingInfo(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de Precios',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConfig.paddingMedium),

            // Precio A (Público) - Obligatorio
            _buildEditablePriceRow(
              'Precio Público',
              product.precioA,
              Icons.store_outlined,
              isRequired: true,
              description: 'Precio de venta al público',
              onEdit: () => _editPrice('precioA', product.precioA),
            ),

            // Precio B (Mayorista) - Opcional
            const SizedBox(height: AppConfig.paddingMedium),
            _buildEditablePriceRow(
              'Precio Mayorista',
              product.precioB ?? 0.0,
              Icons.business_outlined,
              description: 'Precio para ventas mayoristas',
              onEdit: () => _editPrice('precioB', product.precioB ?? 0.0),
              isEmpty: product.precioB == null,
            ),

            // Precio C (Super Mayorista) - Opcional
            const SizedBox(height: AppConfig.paddingMedium),
            _buildEditablePriceRow(
              'Precio Super Mayorista',
              product.precioC ?? 0.0,
              Icons.account_balance_outlined,
              description: 'Precio para grandes volúmenes',
              onEdit: () => _editPrice('precioC', product.precioC ?? 0.0),
              isEmpty: product.precioC == null,
            ),

            const SizedBox(height: AppConfig.paddingMedium),
            const Divider(),
            const SizedBox(height: AppConfig.paddingMedium),

            // Costo - Opcional
            _buildEditablePriceRow(
              'Costo',
              product.costo ?? 0.0,
              Icons.receipt_outlined,
              description: 'Costo del producto',
              onEdit: () => _editPrice('costo', product.costo ?? 0.0),
              isEmpty: product.costo == null,
              isHighlighted: true,
            ),
            const SizedBox(height: AppConfig.paddingMedium),

            // IVA (editable for admins)
            _buildEditableInfoRow(
              'IVA',
              NumberFormatter.formatPercentage(product.iva),
              Icons.percent_outlined,
              onEdit: authController.isAdmin
                ? () => _editIVA(product.iva)
                : null,
            ),

            // Cálculos adicionales si hay costo
            if (product.costo != null && product.costo! > 0) ...[
              const SizedBox(height: AppConfig.paddingMedium),
              _buildProfitMarginInfo(product),
            ],

            // Precios faltantes
            if (product.precioB == null || product.precioC == null) ...[
              const SizedBox(height: AppConfig.paddingMedium),
              _buildMissingPricesInfo(),
            ],

            // Botón de confirmación de llegada - Solo para administradores
            if (authController.isAdmin) ...[
              const SizedBox(height: AppConfig.paddingLarge),
              const Divider(),
              const SizedBox(height: AppConfig.paddingMedium),
              _buildArrivalConfirmationSection(product),
            ],
          ],
        ),
      ),
    );
  }

  /// Build price row with formatting
  Widget _buildPriceRow(
    String label,
    double price,
    IconData icon, {
    bool isRequired = false,
    bool isHighlighted = false,
    String? description,
  }) {
    final priceText = NumberFormatter.formatCurrency(price);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
        border: Border.all(
          color: isRequired
              ? AppConfig.primaryColor.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isRequired
                ? AppConfig.primaryColor
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Requerido',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppConfig.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  priceText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHighlighted
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build profit margin information
  Widget _buildProfitMarginInfo(Product product) {
    if (product.costo == null || product.costo! <= 0) return const SizedBox();

    final marginPublico =
        ((product.precioA - product.costo!) / product.costo!) * 100;
    final marginMayorista = product.precioB != null
        ? ((product.precioB! - product.costo!) / product.costo!) * 100
        : null;
    final marginSuperMayorista = product.precioC != null
        ? ((product.precioC! - product.costo!) / product.costo!) * 100
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppConfig.successColor.withOpacity(0.1),
        border: Border.all(color: AppConfig.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_outlined,
                size: 20,
                color: AppConfig.successColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Márgenes de Ganancia',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppConfig.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildMarginRow('Público', marginPublico),

          if (marginMayorista != null)
            _buildMarginRow('Mayorista', marginMayorista),

          if (marginSuperMayorista != null)
            _buildMarginRow('Super Mayorista', marginSuperMayorista),
        ],
      ),
    );
  }

  /// Build margin row
  Widget _buildMarginRow(String label, double margin) {
    final isPositive = margin >= 0;
    final color = isPositive
        ? AppConfig.successColor
        : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${margin.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build missing prices information
  Widget _buildMissingPricesInfo() {
    final missingPrices = <String>[];

    if (currentProduct?.precioB == null) missingPrices.add('Precio Mayorista');
    if (currentProduct?.precioC == null)
      missingPrices.add('Precio Super Mayorista');

    if (missingPrices.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withOpacity(0.3),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Precios no asignados',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...missingPrices.map(
            (price) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 2),
              child: Text(
                '• $price',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build product metadata section
  Widget _buildProductMetadata(Product product) {
    final createdAtFormatted = DateFormat(
      AppConfig.dateTimeFormat,
    ).format(product.createdAt);
    final updatedAtFormatted = DateFormat(
      AppConfig.dateTimeFormat,
    ).format(product.updatedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Adicional',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConfig.paddingMedium),

            _buildInfoRow(
              'ID del Sistema',
              product.id,
              Icons.fingerprint_outlined,
              isSelectable: true,
            ),
            const SizedBox(height: AppConfig.paddingMedium),

            _buildInfoRow(
              'Fecha de Creación',
              createdAtFormatted,
              Icons.access_time_outlined,
            ),

            if (product.updatedAt != product.createdAt) ...[
              const SizedBox(height: AppConfig.paddingMedium),
              _buildInfoRow(
                'Última Actualización',
                updatedAtFormatted,
                Icons.update_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build information row with icon, label and value
  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isSelectable = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: _shouldUseMonospace(label)
                          ? 'monospace'
                          : null,
                    ),
                    enableInteractiveSelection: isSelectable,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.content_copy_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  /// Build editable info row (for admins)
  Widget _buildEditableInfoRow(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              tooltip: 'Editar $label',
              color: Theme.of(context).colorScheme.primary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  /// Check if field should use monospace font
  bool _shouldUseMonospace(String label) {
    return label.toLowerCase().contains('código') ||
        label.toLowerCase().contains('id');
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
              'Error al cargar producto',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            Obx(
              () => Text(
                controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : 'No se pudo cargar la información del producto',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppConfig.paddingLarge),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  /// Copy text to clipboard
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copiado',
      '$label copiado al portapapeles',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: AppConfig.successColor.withOpacity(0.1),
      colorText: AppConfig.successColor,
    );
  }

  /// Handle app bar menu selections
  void _handleMenuSelection(String value) {
    if (currentProduct == null) return;

    switch (value) {
      case 'copy_barcode':
        _copyToClipboard(currentProduct!.barcode, 'Código de barras');
        break;
      case 'activate':
      case 'deactivate':
        _toggleProductStatus();
        break;
      case 'share':
        _shareProduct();
        break;
    }
  }

  /// Toggle product active status
  void _toggleProductStatus() {
    if (currentProduct == null) return;
    controller.toggleProductStatus(currentProduct!.id);
  }

  /// Share product information
  void _shareProduct() {
    if (currentProduct == null) return;

    final product = currentProduct!;
    final shareText =
        '''
Producto: ${product.description}
Código: ${product.barcode}
Estado: ${product.statusText}
ID: ${product.id}
    ''';

    // TODO: Implement proper sharing functionality
    Get.snackbar(
      'Compartir',
      'Función de compartir no disponible aún',
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Build editable price row with edit button
  Widget _buildEditablePriceRow(
    String label,
    double price,
    IconData icon, {
    bool isRequired = false,
    bool isHighlighted = false,
    bool isEmpty = false,
    String? description,
    required VoidCallback onEdit,
  }) {
    final priceText = isEmpty && price == 0.0
        ? 'No asignado'
        : NumberFormatter.formatCurrency(price);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : isEmpty
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : Theme.of(context).colorScheme.surfaceContainer.withOpacity(0.5),
        border: Border.all(
          color: isRequired
              ? AppConfig.primaryColor.withOpacity(0.3)
              : isEmpty
              ? Theme.of(context).colorScheme.outline.withOpacity(0.1)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isRequired
                ? AppConfig.primaryColor
                : isEmpty
                ? Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.6)
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Requerido',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppConfig.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                    if (isEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Sin asignar',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  priceText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isEmpty
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : isHighlighted
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Only show edit button for admin users
          if (authController.isAdmin)
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                isEmpty ? Icons.add : Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: isEmpty ? 'Asignar precio' : 'Editar precio',
            ),
        ],
      ),
    );
  }

  /// Edit price dialog
  void _editPrice(String priceType, double currentPrice) {
    // Format the current price without decimals for editing
    final TextEditingController priceController = TextEditingController(
      text: currentPrice == 0.0
          ? ''
          : PriceFormatter.formatForEditing(currentPrice),
    );

    String priceLabel = '';
    switch (priceType) {
      case 'precioA':
        priceLabel = 'Precio Público';
        break;
      case 'precioB':
        priceLabel = 'Precio Mayorista';
        break;
      case 'precioC':
        priceLabel = 'Precio Super Mayorista';
        break;
      case 'costo':
        priceLabel = 'Costo';
        break;
    }

    Get.dialog(
      AlertDialog(
        title: Text('Editar $priceLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                PriceInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: priceLabel,
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
                hintText: '0',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa el nuevo precio (sin decimales)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isUpdating.value
                  ? null
                  : () => _savePriceEdit(priceType, priceController.text),
              child: controller.isUpdating.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }

  /// Save price edit
  void _savePriceEdit(String priceType, String priceText) async {
    print(
      '🚨 _savePriceEdit called with: priceType=$priceType, priceText="$priceText"',
    );
    try {
      // Parse the formatted price (removes thousand separators)
      final double newPrice = PriceFormatter.parse(priceText.trim());
      print('🚨 Parsed price: $newPrice');

      if (newPrice < 0) {
        Get.snackbar(
          'Error',
          'Por favor ingresa un precio válido',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
          colorText: Theme.of(context).colorScheme.error,
        );
        return;
      }

      if (currentProduct == null) {
        print('❌ ProductDetailPage: currentProduct is null');
        Get.snackbar(
          'Error',
          '❌ PRODUCT_DETAIL: Producto no encontrado (currentProduct null)',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
          colorText: Theme.of(context).colorScheme.error,
        );
        return;
      }

      // Cerrar diálogo
      Get.back();

      // Acumular el cambio en el map de cambios pendientes
      setState(() {
        _pendingChanges[priceType] = newPrice;
      });

      // Mostrar snackbar informativo
      Get.snackbar(
        'Cambio registrado',
        'Cambio agregado. Presiona "Guardar Cambios" para aplicarlos',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al procesar el precio: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
        colorText: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// Edit product name (admins only)
  void _editProductName(String currentName) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Editar Nombre del Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto',
                border: OutlineInputBorder(),
                hintText: 'Ingresa el nombre del producto',
              ),
              autofocus: true,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Text(
              'Este cambio será notificado a los supervisores',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _saveProductNameEdit(nameController.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Save product name edit
  void _saveProductNameEdit(String newName) {
    final trimmedName = newName.trim();

    if (trimmedName.isEmpty) {
      Get.snackbar(
        'Error',
        'El nombre del producto no puede estar vacío',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
        colorText: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (currentProduct == null) {
      Get.snackbar(
        'Error',
        'Producto no encontrado',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
        colorText: Theme.of(context).colorScheme.error,
      );
      return;
    }

    // Cerrar diálogo
    Get.back();

    // Acumular el cambio en el map de cambios pendientes
    setState(() {
      _pendingChanges['description'] = trimmedName;
    });

    // Mostrar snackbar informativo
    Get.snackbar(
      'Cambio registrado',
      'Cambio agregado. Presiona "Guardar Cambios" para aplicarlo',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
      colorText: Get.theme.colorScheme.primary,
      duration: const Duration(seconds: 2),
    );
  }

  /// Edit IVA (admins only)
  void _editIVA(double currentIVA) {
    // Remove unnecessary decimals (16.00 -> 16, 19.50 -> 19.5)
    final String ivaText = currentIVA % 1 == 0
        ? currentIVA.toInt().toString()
        : currentIVA.toString();

    final TextEditingController ivaController = TextEditingController(
      text: ivaText,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Editar IVA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ivaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'IVA (%)',
                border: OutlineInputBorder(),
                hintText: '19',
                suffixText: '%',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa el porcentaje de IVA (0-100). Este cambio será notificado a los supervisores',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _saveIVAEdit(ivaController.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Save IVA edit
  void _saveIVAEdit(String ivaText) {
    try {
      final double newIVA = double.parse(ivaText.trim());

      if (newIVA < 0 || newIVA > 100) {
        Get.snackbar(
          'Error',
          'Por favor ingresa un valor entre 0 y 100',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
          colorText: Theme.of(context).colorScheme.error,
        );
        return;
      }

      if (currentProduct == null) {
        Get.snackbar(
          'Error',
          'Producto no encontrado',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
          colorText: Theme.of(context).colorScheme.error,
        );
        return;
      }

      // Cerrar diálogo
      Get.back();

      // Acumular el cambio en el map de cambios pendientes
      setState(() {
        _pendingChanges['iva'] = newIVA;
      });

      // Mostrar snackbar informativo
      Get.snackbar(
        'Cambio registrado',
        'Cambio agregado. Presiona "Guardar Cambios" para aplicarlo',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
        colorText: Get.theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al procesar el IVA: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
        colorText: Theme.of(context).colorScheme.error,
      );
    }
  }

  /// Save all pending changes at once
  Future<void> _saveAllPendingChanges() async {
    if (!hasPendingChanges || currentProduct == null) return;

    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Log exactly what we're sending to backend
      print('🔍 FRONTEND: Sending update with _pendingChanges: $_pendingChanges');
      print('🔍 FRONTEND: Keys: ${_pendingChanges.keys.toList()}');
      print('🔍 FRONTEND: Values: ${_pendingChanges.values.toList()}');

      // Send all changes at once
      final success = await controller.updateProduct(
        currentProduct!.id,
        _pendingChanges,
      );

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (success) {
        // Clear pending changes
        _pendingChanges.clear();

        // Navigate back to products list, removing all previous routes
        Get.offAllNamed('/products');
      }
    } catch (e) {
      // Close loading if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Error al guardar cambios: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    }
  }

  /// Discard all pending changes
  void _discardPendingChanges() {
    setState(() {
      _pendingChanges.clear();
    });
    Get.snackbar(
      'Cambios descartados',
      'Todos los cambios pendientes han sido descartados',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.secondary.withOpacity(0.1),
      colorText: Get.theme.colorScheme.secondary,
      duration: const Duration(seconds: 2),
    );
  }

  /// Build pending changes bottom bar (fixed at bottom)
  Widget _buildPendingChangesBottomBar() {
    final changedCount = _pendingChanges.length;
    final changedPrices = _pendingChanges.keys
        .map((key) {
          switch (key) {
            case 'precioA':
              return 'Público';
            case 'precioB':
              return 'Mayorista';
            case 'precioC':
              return 'Super Mayorista';
            case 'costo':
              return 'Costo';
            default:
              return key;
          }
        })
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConfig.paddingMedium,
                  vertical: AppConfig.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.primaryContainer.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: Get.theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppConfig.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$changedCount cambio${changedCount > 1 ? 's' : ''} pendiente${changedCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Get.theme.colorScheme.primary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            changedPrices,
                            style: TextStyle(
                              fontSize: 12,
                              color: Get.theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _discardPendingChanges,
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('Descartar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Get.theme.colorScheme.error,
                        side: BorderSide(color: Get.theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConfig.paddingMedium),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveAllPendingChanges,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Get.theme.colorScheme.primary,
                        foregroundColor: Get.theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show dialog when user tries to leave with unsaved changes
  Future<bool> _showDiscardChangesDialog() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Get.theme.colorScheme.error,
          size: 48,
        ),
        title: const Text('¿Descartar cambios?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tienes ${_pendingChanges.length} cambio${_pendingChanges.length > 1 ? 's' : ''} sin guardar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '¿Qué deseas hacer?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              _discardPendingChanges();
              Get.back(result: false); // Close dialog
              Get.offAllNamed('/products'); // Navigate to products list
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Descartar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Get.theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back(result: false);
              await _saveAllPendingChanges();
            },
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.primary,
              foregroundColor: Get.theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Build arrival confirmation section
  Widget _buildArrivalConfirmationSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmación de Llegada',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Get.theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppConfig.paddingSmall),
        Text(
          'Confirma que este producto llegó con los precios actuales mostrados arriba',
          style: TextStyle(
            fontSize: AppConfig.bodyFontSize,
            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: AppConfig.paddingMedium),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showArrivalConfirmationDialog(product),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Confirmar Llegada de Producto'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConfig.paddingLarge,
                vertical: AppConfig.paddingMedium,
              ),
              backgroundColor: Get.theme.colorScheme.primary,
              foregroundColor: Get.theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show arrival confirmation dialog
  void _showArrivalConfirmationDialog(Product product) {
    final commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: Get.theme.colorScheme.primary),
            const SizedBox(width: AppConfig.paddingSmall),
            const Expanded(child: Text('Confirmar Llegada')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Producto: ${product.description}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            const Text(
              'Esto creará una notificación para el supervisor confirmando que el producto llegó con los precios actuales.',
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Ej: Llegó en buen estado, cantidad completa...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                _createArrivalTask(product, commentController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.primary,
              foregroundColor: Get.theme.colorScheme.onPrimary,
            ),
            child: const Text('Confirmar Llegada'),
          ),
        ],
      ),
    );
  }

  /// Create arrival confirmation task
  Future<void> _createArrivalTask(Product product, String comment) async {
    try {
      Get.back(); // Close dialog

      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Get CreateTask use case from GetIt
      final createTaskUseCase = getIt<CreateTask>();

      final description = comment.isNotEmpty
          ? 'Producto llegó - precios confirmados. Comentario: $comment'
          : 'Producto llegó - precios confirmados sin cambios';

      final result = await createTaskUseCase(
        CreateTaskParams(
          productId: product.id,
          changeType: ChangeType.arrival,
          description: description,
        ),
      );

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            'No se pudo crear la notificación: ${failure.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
            colorText: Get.theme.colorScheme.error,
          );
        },
        (task) {
          Get.snackbar(
            'Éxito',
            'Notificación de llegada enviada al supervisor',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
            colorText: Get.theme.colorScheme.primary,
            duration: const Duration(seconds: 2),
          );

          // Navigate back to products list, removing all previous routes
          Get.offAllNamed('/products');
        },
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    }
  }
}
