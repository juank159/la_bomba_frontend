// lib/features/vegetables/presentation/pages/create_vegetable_purchase_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../domain/entities/vegetable_item.dart';
import '../controllers/vegetables_controller.dart';

/// Registra una compra real de mercancía: selecciona productos ya
/// existentes en el catálogo (misma búsqueda/filtro por categoría que
/// "Vender Verduras"), indica cantidad y costo pagado. Al guardar, suma
/// automáticamente al inventario de cada producto.
class CreateVegetablePurchasePage extends StatefulWidget {
  const CreateVegetablePurchasePage({super.key});

  @override
  State<CreateVegetablePurchasePage> createState() => _CreateVegetablePurchasePageState();
}

class _CreateVegetablePurchasePageState extends State<CreateVegetablePurchasePage> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<VegetablesController>();
    searchController = TextEditingController(text: controller.itemsSearchQuery.value);
    searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadItems();
      controller.loadCategories();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Get.find<VegetablesController>().searchItems(searchController.text);
  }

  void _clearSearch() => searchController.clear();

  Future<bool> _confirmDiscard(VegetablesController controller) async {
    if (controller.purchaseCartIsEmpty) return true;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Descartar compra?'),
        content: Text('Tienes ${controller.purchaseCart.length} producto(s) sin guardar. Si sales ahora se perderán.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            style: TextButton.styleFrom(foregroundColor: Get.theme.colorScheme.error),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _pickQuantityAndCost(
    VegetablesController controller,
    VegetableItem item, {
    double? initialQuantity,
    double? initialUnitCost,
  }) async {
    final quantityController = TextEditingController(
      text: initialQuantity != null ? NumberFormatter.formatQuantity(initialQuantity) : '',
    );
    final costController = TextEditingController(
      text: initialUnitCost != null && initialUnitCost > 0 ? initialUnitCost.toStringAsFixed(0) : '',
    );
    String? errorText;

    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(item.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock actual: ${NumberFormatter.formatQuantity(item.stock)} ${item.stockUnitLabel}',
                    style: Get.textTheme.bodySmall),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: quantityController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cantidad comprada',
                    suffixText: item.stockUnitLabel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: item.pricingType.isWeight ? 'Costo pagado por kg' : 'Costo pagado por unidad',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantity = double.tryParse(quantityController.text.trim().replaceAll(',', '.'));
                  if (quantity == null || quantity <= 0) {
                    setDialogState(() => errorText = 'Ingresa una cantidad válida');
                    return;
                  }
                  Navigator.of(context, rootNavigator: true).pop(true);
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final quantity = double.tryParse(quantityController.text.trim().replaceAll(',', '.')) ?? 0;
    final unitCost = double.tryParse(costController.text.trim().replaceAll(',', '.')) ?? 0;
    if (quantity <= 0) return;

    controller.addToPurchaseCart(item, quantity, unitCost);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard(controller) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Nueva Compra'), elevation: 0),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConfig.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(controller),
                      const SizedBox(height: AppConfig.paddingMedium),
                      _buildCatalog(controller),
                      const SizedBox(height: AppConfig.paddingLarge),
                      _buildCart(controller),
                    ],
                  ),
                ),
              ),
              _buildCheckoutBar(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(VegetablesController controller) {
    return CustomInput(
      controller: searchController,
      hintText: 'Buscar producto...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: Obx(() {
        if (controller.itemsSearchQuery.value.isEmpty) return const SizedBox.shrink();
        return IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch);
      }),
    );
  }

  Widget _buildCatalog(VegetablesController controller) {
    return Obx(() {
      if (controller.isLoadingItems.value && controller.items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final grouped = controller.itemsByCategory;

      if (grouped.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 40, color: Get.theme.disabledColor),
                const SizedBox(height: 8),
                Text(
                  controller.itemsSearchQuery.value.isEmpty
                      ? 'No hay productos activos en el catálogo'
                      : 'Sin resultados para "${controller.itemsSearchQuery.value}"',
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConfig.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: Get.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((item) => _buildCatalogCard(controller, item)).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildCatalogCard(VegetablesController controller, VegetableItem item) {
    final outOfStock = item.isOutOfStock;
    return InkWell(
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      onTap: () => _pickQuantityAndCost(controller, item),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppConfig.paddingSmall),
        decoration: BoxDecoration(
          border: Border.all(color: outOfStock ? Get.theme.colorScheme.error : Get.theme.dividerColor),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.pricingType.isWeight ? Icons.scale_outlined : Icons.sell_outlined,
              color: Get.theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              outOfStock
                  ? 'Sin stock'
                  : 'Stock: ${NumberFormatter.formatQuantity(item.stock)} ${item.stockUnitLabel}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: outOfStock ? FontWeight.w600 : null,
                color: outOfStock ? Get.theme.colorScheme.error : Get.theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart(VegetablesController controller) {
    return Obx(() {
      if (controller.purchaseCart.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_basket_outlined, size: 40, color: Get.theme.disabledColor),
                const SizedBox(height: 8),
                Text('Carrito de compra vacío', style: Get.textTheme.bodyMedium),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En la compra', style: Get.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...controller.purchaseCart.map((line) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
              child: ListTile(
                onTap: () => _pickQuantityAndCost(
                  controller,
                  line.item,
                  initialQuantity: line.quantity,
                  initialUnitCost: line.unitCost,
                ),
                title: Text(line.item.name),
                subtitle: Text(
                  '${NumberFormatter.formatQuantity(line.quantity)} ${line.item.stockUnitLabel} x ${NumberFormatter.formatCurrency(line.unitCost)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormatter.formatCurrency(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                      onPressed: () => controller.removeFromPurchaseCart(line),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildCheckoutBar(VegetablesController controller) {
    return Obx(() {
      return Container(
        padding: EdgeInsets.only(
          left: AppConfig.paddingMedium,
          right: AppConfig.paddingMedium,
          top: AppConfig.paddingMedium,
          bottom: AppConfig.paddingMedium + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  NumberFormatter.formatCurrency(controller.purchaseCartTotal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.purchaseCartIsEmpty || controller.isCreatingPurchase.value
                    ? null
                    : () async {
                        final purchase = await controller.checkoutPurchase();
                        if (purchase != null && mounted) {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.vegetablePurchases);
                        }
                      },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: controller.isCreatingPurchase.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Registrar Compra', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
