// lib/features/vegetables/presentation/pages/sell_vegetables_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../domain/entities/vegetable_item.dart';
import '../controllers/vegetables_controller.dart';

/// POS-style screen to sell vegetables: tap a weighted item to capture the
/// live scale reading, tap a fixed-price item to add a unit, then charge
/// and print the receipt.
class SellVegetablesPage extends StatefulWidget {
  const SellVegetablesPage({super.key});

  @override
  State<SellVegetablesPage> createState() => _SellVegetablesPageState();
}

class _SellVegetablesPageState extends State<SellVegetablesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<VegetablesController>();
      controller.loadItems();
      if (!controller.isScaleConnected.value) {
        controller.connectScale();
      }
    });
  }

  /// Se llama al intentar salir de la pantalla (gesto/botón de retroceso).
  /// Esta pantalla casi siempre es la raíz de la pila (se llega por el
  /// drawer con offAllNamed), así que normalmente no hay nada a qué volver
  /// con pop() — solo confirmamos y vaciamos el carrito si hace falta.
  Future<void> _confirmDiscard(VegetablesController controller) async {
    final canPop = Navigator.of(context).canPop();

    if (controller.cartIsEmpty) {
      if (canPop) Navigator.of(context).pop();
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Descartar venta?'),
        content: Text('Tienes ${controller.cart.length} producto(s) en el carrito. Si sales ahora se perderán.'),
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
      controller.clearCart();
      if (canPop) Navigator.of(context).pop();
    }
  }

  Future<void> _addWeightedItem(VegetablesController controller, VegetableItem item) async {
    final weightController = TextEditingController(
      text: controller.liveWeight.value != null ? controller.liveWeight.value!.toStringAsFixed(3) : '',
    );

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
                Obx(() {
                  final connected = controller.isScaleConnected.value;
                  final weight = controller.liveWeight.value;
                  return Container(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    decoration: BoxDecoration(
                      color: (connected ? Get.theme.colorScheme.primary : Get.theme.disabledColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          connected ? Icons.scale : Icons.scale_outlined,
                          color: connected ? Get.theme.colorScheme.primary : Get.theme.disabledColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            connected
                                ? (weight != null ? '${weight.toStringAsFixed(3)} kg en báscula' : 'Esperando lectura...')
                                : 'Báscula no conectada',
                          ),
                        ),
                        if (connected && weight != null)
                          TextButton(
                            onPressed: () => setDialogState(() => weightController.text = weight.toStringAsFixed(3)),
                            child: const Text('Usar'),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: weightController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Peso (kg)',
                    hintText: 'Ej: 0.350',
                    prefixIcon: const Icon(Icons.scale_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${NumberFormatter.formatCurrency(item.pricePerKg)} / kg',
                  style: Get.textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final weight = double.tryParse(weightController.text.trim());
    if (weight == null || weight <= 0) {
      safeSnackbar('Peso inválido', 'Ingresa un peso mayor a 0', snackPosition: SnackPosition.TOP);
      return;
    }

    controller.addWeightedItemToCart(item, weight);
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
          title: const Text('Vender Verduras'),
          elevation: 0,
          actions: [
            Obx(() => IconButton(
                  tooltip: controller.isScaleConnected.value ? 'Báscula conectada' : 'Conectar báscula',
                  icon: Icon(controller.isScaleConnected.value ? Icons.scale : Icons.scale_outlined),
                  color: controller.isScaleConnected.value ? Get.theme.colorScheme.primary : null,
                  onPressed: () => Get.toNamed(AppRoutes.scaleSettings),
                )),
          ],
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Column(
            children: [
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
                        Text('Productos', style: Get.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        _buildItemsGrid(controller),
                        const SizedBox(height: AppConfig.paddingLarge),
                        _buildCartSection(controller),
                      ],
                    ),
                  );
                }),
              ),
              _buildCheckoutBar(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsGrid(VegetablesController controller) {
    if (controller.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No hay productos activos en el catálogo'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: controller.items.map((item) {
        final priceLabel = item.pricingType.isWeight
            ? '${NumberFormatter.formatCurrency(item.pricePerKg)}/kg'
            : NumberFormatter.formatCurrency(item.fixedPrice);

        return InkWell(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          onTap: () => item.pricingType.isWeight
              ? _addWeightedItem(controller, item)
              : controller.addFixedItemToCart(item),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(AppConfig.paddingSmall),
            decoration: BoxDecoration(
              border: Border.all(color: Get.theme.dividerColor),
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
                Text(priceLabel, style: Get.textTheme.bodySmall),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCartSection(VegetablesController controller) {
    return Obx(() {
      if (controller.cart.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_basket_outlined, size: 40, color: Get.theme.disabledColor),
                const SizedBox(height: 8),
                Text('Carrito vacío', style: Get.textTheme.bodyMedium),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En el carrito', style: Get.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...controller.cart.map((line) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
              child: ListTile(
                title: Text(line.item.name),
                subtitle: Text(line.quantityLabel),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormatter.formatCurrency(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                      onPressed: () => controller.removeFromCart(line.item.id),
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
                  NumberFormatter.formatCurrency(controller.cartTotal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.cartIsEmpty || controller.isCreatingSale.value
                    ? null
                    : () async {
                        final sale = await controller.checkout();
                        if (sale != null) {
                          await controller.printSale(sale);
                        }
                      },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: controller.isCreatingSale.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Cobrar e Imprimir', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
