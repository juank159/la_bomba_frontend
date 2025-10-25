import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../domain/entities/product.dart';

/// ProductCard widget for displaying product information in a list
/// Shows description, barcode, active status, and creation date
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool showActions;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showDetails = true,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConfig.marginMedium),
      elevation: 2,
      child: InkWell(
        onTap: onTap ?? () => _navigateToProductDetail(context),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: Icono + Info básica + Acciones
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductIcon(context),
                      const SizedBox(width: AppConfig.paddingMedium),
                      Expanded(child: _buildBasicProductInfo(context)),
                      if (showActions) _buildActionButtons(context),
                    ],
                  ),

                  // Fila de precios: Alineada con el icono (aprovecha todo el ancho)
                  const SizedBox(height: AppConfig.paddingSmall),
                  _buildPriceInfo(context),

                  if (showDetails) ...[
                    const SizedBox(height: AppConfig.paddingMedium),
                    _buildProductDetails(context),
                  ],
                ],
              ),
            ),

            // Status indicator - punto en esquina superior derecha
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: product.isActive
                      ? AppConfig.successColor
                      : Theme.of(context).colorScheme.error,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (product.isActive
                                  ? AppConfig.successColor
                                  : Theme.of(context).colorScheme.error)
                              .withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build product icon/image placeholder
  Widget _buildProductIcon(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: 28,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Build basic product information (without prices)
  Widget _buildBasicProductInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.description,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConfig.paddingSmall / 2),
        Text(
          'Código: ${product.barcode}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  /// Build price information display
  Widget _buildPriceInfo(BuildContext context) {
    // Crear lista de precios disponibles para mostrar en una sola fila
    final List<Widget> priceWidgets = [];

    // Precio A (siempre presente y más prominente)
    priceWidgets.add(
      Expanded(
        flex: 2, // Más espacio para el precio principal
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sell,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Público',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                product.precioAFormatted,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    // Precio B (si existe)
    if (product.precioB != null) {
      priceWidgets.add(const SizedBox(width: 6));
      priceWidgets.add(
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.business_center_outlined,
                      size: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'Mayor',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  NumberFormatter.formatCurrency(product.precioB!),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Precio C (si existe)
    if (product.precioC != null) {
      priceWidgets.add(const SizedBox(width: 6));
      priceWidgets.add(
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.tertiaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 12,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'Super',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  NumberFormatter.formatCurrency(product.precioC!),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila principal de precios
        Row(children: priceWidgets),

        // IVA indicator en fila separada solo si es diferente de 19%
        if (product.iva != 19.0) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.percent,
                    size: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'IVA ${NumberFormatter.formatPercentage(product.iva)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build additional product details
  Widget _buildProductDetails(BuildContext context) {
    final createdAtFormatted = DateFormat(
      AppConfig.dateTimeFormat,
    ).format(product.createdAt);
    final updatedAtFormatted = DateFormat(
      AppConfig.dateTimeFormat,
    ).format(product.updatedAt);

    return Container(
      padding: const EdgeInsets.all(AppConfig.paddingSmall),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: Column(
        children: [
          // Cost and profit margin (if available)
          if (product.costo != null) ...[
            const SizedBox(height: 4),
            _buildDetailRow(
              context,
              'Costo:',
              product.getFormattedPrice(product.costo!),
              Icons.savings_outlined,
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              context,
              'Margen:',
              product.profitMarginFormatted,
              Icons.trending_up_outlined,
            ),
          ],

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Timestamps
          _buildDetailRow(
            context,
            'Actualizado:',
            updatedAtFormatted,
            Icons.update,
          ),
          const SizedBox(height: 4),
          _buildDetailRow(
            context,
            'Creado:',
            createdAtFormatted,
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  /// Build a detail row with icon, label and value
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppConfig.paddingSmall / 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Build action buttons (for future features)
  Widget _buildActionButtons(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: (value) => _handleActionSelected(context, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 20),
              const SizedBox(width: AppConfig.paddingSmall),
              const Text('Ver detalle'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy_barcode',
          child: Row(
            children: [
              const Icon(Icons.copy_outlined, size: 20),
              const SizedBox(width: AppConfig.paddingSmall),
              const Text('Copiar código'),
            ],
          ),
        ),
        if (product.isActive)
          PopupMenuItem(
            value: 'deactivate',
            child: Row(
              children: [
                const Icon(Icons.block_outlined, size: 20),
                const SizedBox(width: AppConfig.paddingSmall),
                const Text('Desactivar'),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'activate',
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: AppConfig.paddingSmall),
                const Text('Activar'),
              ],
            ),
          ),
      ],
    );
  }

  /// Handle action menu selections
  void _handleActionSelected(BuildContext context, String action) {
    switch (action) {
      case 'view':
        _navigateToProductDetail(context);
        break;
      case 'copy_barcode':
        _copyBarcodeToClipboard(context);
        break;
      case 'activate':
      case 'deactivate':
        _toggleProductStatus(context);
        break;
    }
  }

  /// Navigate to product detail page
  void _navigateToProductDetail(BuildContext context) {
    AppPages.toProductDetail(product.id);
  }

  /// Copy barcode to clipboard
  void _copyBarcodeToClipboard(BuildContext context) {
    // TODO: Implement clipboard functionality
    Get.snackbar(
      'Copiado',
      'Código de barras copiado: ${product.barcode}',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  /// Toggle product active status
  void _toggleProductStatus(BuildContext context) {
    // TODO: Implement product status toggle
    Get.snackbar(
      'Información',
      'Función no disponible aún',
      snackPosition: SnackPosition.TOP,
    );
  }
}

/// Compact version of ProductCard for dense lists
class ProductCardCompact extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCardCompact({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ProductCard(
      product: product,
      onTap: onTap,
      showDetails: false,
      showActions: false,
    );
  }
}

/// ProductCard with action buttons enabled
class ProductCardWithActions extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCardWithActions({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ProductCard(
      product: product,
      onTap: onTap,
      showDetails: true,
      showActions: true,
    );
  }
}
