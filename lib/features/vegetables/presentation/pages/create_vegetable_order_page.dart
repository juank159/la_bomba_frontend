// lib/features/vegetables/presentation/pages/create_vegetable_order_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/entities/vegetable_order_item.dart';
import '../controllers/vegetables_controller.dart';

/// Builds a vegetables restock order ("pedido"): pick products from the
/// catalog (or add a one-off custom item), choose quantity and unit
/// (kilogramos/libras/unidad), then generate the PDF and print it.
///
/// Deliberately simpler than the regular Orders module: no supplier, no
/// status - just a list to print and hand to whoever supplies the produce.
class CreateVegetableOrderPage extends StatefulWidget {
  const CreateVegetableOrderPage({super.key});

  @override
  State<CreateVegetableOrderPage> createState() => _CreateVegetableOrderPageState();
}

class _CreateVegetableOrderPageState extends State<CreateVegetableOrderPage> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<VegetablesController>();
    searchController = TextEditingController(text: controller.itemsSearchQuery.value);
    searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadItems();
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

  Future<void> _confirmDiscard(VegetablesController controller) async {
    final canPop = Navigator.of(context).canPop();

    if (controller.orderCartIsEmpty) {
      if (canPop) Navigator.of(context).pop();
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Descartar pedido?'),
        content: Text('Tienes ${controller.orderCart.length} producto(s) en el pedido. Si sales ahora se perderán.'),
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

    if (confirmed == true && mounted) {
      controller.clearOrderCart();
      if (canPop) Navigator.of(context).pop();
    }
  }

  Future<void> _addCatalogItem(VegetablesController controller, VegetableItem item) async {
    final quantityController = TextEditingController();
    final Rx<VegetableOrderUnit> unit = (item.pricingType.isWeight
            ? VegetableOrderUnit.kilogramos
            : VegetableOrderUnit.unidad)
        .obs;
    final formKey = GlobalKey<FormState>();

    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(item.name),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: quantityController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) return 'Ingresa una cantidad válida';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  Obx(() => DropdownButtonFormField<VegetableOrderUnit>(
                        initialValue: unit.value,
                        decoration: InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                        ),
                        items: VegetableOrderUnit.values
                            .map((u) => DropdownMenuItem(value: u, child: Text(u.displayName)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) unit.value = value;
                        },
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context, rootNavigator: true).pop(true);
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final quantity = double.parse(quantityController.text.trim());
    controller.addCatalogItemToOrder(item, quantity, unit.value);
  }

  Future<void> _addCustomItem(VegetablesController controller) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final Rx<VegetableOrderUnit> unit = VegetableOrderUnit.unidad.obs;
    final formKey = GlobalKey<FormState>();

    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Producto personalizado'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para un producto que aún no está en el catálogo.',
                    style: Get.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej: Cilantro',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    ),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresa un nombre' : null,
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) return 'Ingresa una cantidad válida';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  Obx(() => DropdownButtonFormField<VegetableOrderUnit>(
                        initialValue: unit.value,
                        decoration: InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                        ),
                        items: VegetableOrderUnit.values
                            .map((u) => DropdownMenuItem(value: u, child: Text(u.displayName)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) unit.value = value;
                        },
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context, rootNavigator: true).pop(true);
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final quantity = double.parse(quantityController.text.trim());
    controller.addCustomItemToOrder(nameController.text.trim(), quantity, unit.value);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmDiscard(controller);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nuevo Pedido'),
          elevation: 0,
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              Obx(() {
                if (controller.isLoadingItems.value && controller.items.isEmpty) return const SizedBox.shrink();
                if (controller.items.isEmpty) return const SizedBox.shrink();
                return _buildSearchBar(controller);
              }),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingItems.value && controller.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Catálogo', style: Get.textTheme.titleSmall),
                            TextButton.icon(
                              onPressed: () => _addCustomItem(controller),
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Producto personalizado'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildCatalogGrid(controller),
                        const SizedBox(height: AppConfig.paddingLarge),
                        _buildOrderCartSection(controller),
                      ],
                    ),
                  );
                }),
              ),
              _buildGenerateBar(controller),
            ],
          ),
        ),
      ),
    );
  }

  /// Buscador instantáneo por nombre o categoría - mismo mecanismo que
  /// Catálogo y Vender: filtra en el cliente mientras se escribe.
  Widget _buildSearchBar(VegetablesController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConfig.paddingMedium,
        AppConfig.paddingMedium,
        AppConfig.paddingMedium,
        0,
      ),
      child: CustomInput(
        controller: searchController,
        hintText: 'Buscar producto o categoría...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Obx(() {
          if (controller.itemsSearchQuery.value.isEmpty) return const SizedBox.shrink();
          return IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch);
        }),
      ),
    );
  }

  Widget _buildCatalogGrid(VegetablesController controller) {
    if (controller.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No hay productos activos en el catálogo'),
      );
    }

    final filtered = controller.filteredItems;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sin resultados para "${controller.itemsSearchQuery.value}"'),
            TextButton(onPressed: _clearSearch, child: const Text('Limpiar búsqueda')),
          ],
        ),
      );
    }

    // Sin stock primero: son los que más urge pedir.
    final sorted = [...filtered]..sort((a, b) => a.stock.compareTo(b.stock));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sorted.map((item) {
        final outOfStock = item.isOutOfStock;
        return InkWell(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          onTap: () => _addCatalogItem(controller, item),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(AppConfig.paddingSmall),
            decoration: BoxDecoration(
              border: Border.all(color: outOfStock ? Get.theme.colorScheme.error : Get.theme.dividerColor),
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco_outlined, color: Get.theme.colorScheme.primary),
                const SizedBox(height: 4),
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.category != null)
                  Text(item.category!.name, style: Get.textTheme.bodySmall),
                const SizedBox(height: 2),
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
      }).toList(),
    );
  }

  Widget _buildOrderCartSection(VegetablesController controller) {
    return Obx(() {
      if (controller.orderCart.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.list_alt_outlined, size: 40, color: Get.theme.disabledColor),
                const SizedBox(height: 8),
                Text('Aún no has agregado productos al pedido', style: Get.textTheme.bodyMedium),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En el pedido (${controller.orderCart.length})', style: Get.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...controller.orderCart.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
              child: ListTile(
                title: Text(line.description),
                subtitle: Text(line.quantityLabel),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                  onPressed: () => controller.removeFromOrderCart(index),
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildGenerateBar(VegetablesController controller) {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.orderCartIsEmpty || controller.isCreatingOrder.value
                ? null
                : () async {
                    final order = await controller.submitOrder();
                    if (order != null && mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            icon: controller.isCreatingOrder.value
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Generar PDF e Imprimir', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      );
    });
  }
}
