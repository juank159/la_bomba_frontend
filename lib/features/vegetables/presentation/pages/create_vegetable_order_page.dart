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
  // A partir de este ancho se muestra el pedido como columna fija a la
  // derecha (escritorio/tablet en Windows) - siempre visible, sin scroll;
  // por debajo (celular Android en vertical) se apila como antes, con
  // autoscroll al agregar para que se note.
  static const double _wideBreakpoint = 760;
  static const double _cartPanelWidth = 320;

  late final TextEditingController searchController;
  final ScrollController _cartScrollController = ScrollController();
  final ScrollController _pageScrollController = ScrollController();
  late final Worker _cartWorker;
  int _lastOrderCartLength = 0;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<VegetablesController>();
    searchController = TextEditingController(text: controller.itemsSearchQuery.value);
    searchController.addListener(_onSearchChanged);

    _lastOrderCartLength = controller.orderCart.length;
    _cartWorker = ever<List<VegetableOrderCartLine>>(controller.orderCart, (list) {
      if (list.length > _lastOrderCartLength) _scrollCartToEnd();
      _lastOrderCartLength = list.length;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadItems();
    });
  }

  /// Baja el scroll del pedido hasta el final apenas el frame con la línea
  /// nueva ya se dibujó, para que se note que sí se agregó sin tener que
  /// buscarla entre los productos ya agregados.
  void _scrollCartToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in [_cartScrollController, _pageScrollController]) {
        if (!controller.hasClients) continue;
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _cartWorker.dispose();
    _cartScrollController.dispose();
    _pageScrollController.dispose();
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
    safeSnackbar('Agregado al pedido', item.name, snackPosition: SnackPosition.TOP);
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
    final name = nameController.text.trim();
    controller.addCustomItemToOrder(name, quantity, unit.value);
    safeSnackbar('Agregado al pedido', name, snackPosition: SnackPosition.TOP);
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

                  // Se leen acá adentro (y no dentro del LayoutBuilder de más
                  // abajo) a propósito: Obx solo detecta los Rx que se leen
                  // de forma síncrona mientras corre este builder. El
                  // builder de LayoutBuilder se ejecuta después, en la fase
                  // de layout - si se leyeran ahí adentro, Obx nunca se
                  // enteraría de un cambio en la búsqueda o en el pedido
                  // (mismo fix aplicado en sell_vegetables_page.dart).
                  final catalogGrid = _buildCatalogGrid(controller);
                  final orderCart = controller.orderCart;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final catalogHeader = Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Catálogo', style: Get.textTheme.titleSmall),
                          TextButton.icon(
                            onPressed: () => _addCustomItem(controller),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Producto personalizado'),
                          ),
                        ],
                      );

                      if (constraints.maxWidth >= _wideBreakpoint) {
                        // Layout de escritorio: catálogo a la izquierda,
                        // pedido siempre visible a la derecha - así nunca
                        // hace falta bajar con scroll para confirmar que
                        // algo se agregó.
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(AppConfig.paddingMedium),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [catalogHeader, const SizedBox(height: 8), catalogGrid],
                                ),
                              ),
                            ),
                            _buildCartPanel(controller, orderCart),
                          ],
                        );
                      }

                      // Ventana angosta (celular): se apila igual que
                      // antes, con autoscroll hasta el pedido al agregar
                      // un producto para que se note.
                      return SingleChildScrollView(
                        controller: _pageScrollController,
                        padding: const EdgeInsets.all(AppConfig.paddingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            catalogHeader,
                            const SizedBox(height: 8),
                            catalogGrid,
                            const SizedBox(height: AppConfig.paddingLarge),
                            _buildOrderCartSectionInline(controller, orderCart),
                          ],
                        ),
                      );
                    },
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

  Widget _buildEmptyCart() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_outlined, size: 40, color: Get.theme.disabledColor),
            const SizedBox(height: 8),
            Text('Aún no has agregado productos al pedido', style: Get.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCartLineTile(VegetablesController controller, int index, VegetableOrderCartLine line) {
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
  }

  /// Pedido apilado debajo del catálogo (ventanas angostas) - parte del
  /// mismo scroll de la página, con autoscroll hasta acá al agregar.
  Widget _buildOrderCartSectionInline(VegetablesController controller, List<VegetableOrderCartLine> orderCart) {
    if (orderCart.isEmpty) return _buildEmptyCart();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('En el pedido (${orderCart.length})', style: Get.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...orderCart.asMap().entries.map((entry) => _buildOrderCartLineTile(controller, entry.key, entry.value)),
      ],
    );
  }

  /// Columna fija a la derecha (ventanas anchas): el pedido siempre
  /// visible al lado del catálogo, con su propio scroll - así nunca hace
  /// falta bajar para confirmar que un producto se agregó.
  Widget _buildCartPanel(VegetablesController controller, List<VegetableOrderCartLine> orderCart) {
    return Container(
      width: _cartPanelWidth,
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        border: Border(left: BorderSide(color: Get.theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(Icons.list_alt_outlined, size: 18, color: Get.theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Pedido', style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (orderCart.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${orderCart.length}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Get.theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: orderCart.isEmpty
                ? _buildEmptyCart()
                : ListView.builder(
                    controller: _cartScrollController,
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    itemCount: orderCart.length,
                    itemBuilder: (context, index) => _buildOrderCartLineTile(controller, index, orderCart[index]),
                  ),
          ),
        ],
      ),
    );
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
