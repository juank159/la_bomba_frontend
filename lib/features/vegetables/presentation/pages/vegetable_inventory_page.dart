// lib/features/vegetables/presentation/pages/vegetable_inventory_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/entities/vegetable_stock_movement.dart';
import '../../domain/repositories/vegetables_repository.dart';
import '../controllers/vegetables_controller.dart';

/// Inventario básico del módulo de verduras: saldo actual por producto,
/// con acciones rápidas para registrar una entrada de mercancía o dar de
/// baja producto dañado/vencido (merma). El historial completo por
/// producto vive en [VegetableStockHistoryPage].
class VegetableInventoryPage extends StatefulWidget {
  const VegetableInventoryPage({super.key});

  @override
  State<VegetableInventoryPage> createState() => _VegetableInventoryPageState();
}

class _VegetableInventoryPageState extends State<VegetableInventoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de Verduras'), elevation: 0),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingItems.value && controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Get.theme.disabledColor),
                  const SizedBox(height: 8),
                  const Text('No hay productos en el catálogo'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadItems(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              itemCount: controller.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _buildItemTile(controller, controller.items[index]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildItemTile(VegetablesController controller, VegetableItem item) {
    final outOfStock = item.isOutOfStock;
    final stockLabel = '${item.stock.toStringAsFixed(item.pricingType.isWeight ? 3 : 0)} ${item.stockUnitLabel}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: ListTile(
        onTap: () => Get.toNamed(AppRoutes.vegetableStockHistory, arguments: item.id),
        leading: CircleAvatar(
          backgroundColor: (outOfStock ? Get.theme.colorScheme.error : Get.theme.colorScheme.primary).withValues(alpha: 0.1),
          child: Icon(
            item.pricingType.isWeight ? Icons.scale_outlined : Icons.sell_outlined,
            color: outOfStock ? Get.theme.colorScheme.error : Get.theme.colorScheme.primary,
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(item.category?.name ?? 'Sin categoría'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stockLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: outOfStock ? Get.theme.colorScheme.error : null,
                  ),
                ),
                if (outOfStock)
                  Text('Sin stock', style: TextStyle(fontSize: 11, color: Get.theme.colorScheme.error)),
              ],
            ),
            IconButton(
              tooltip: 'Registrar movimiento',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showMovementDialog(controller, item),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMovementDialog(
    VegetablesController controller,
    VegetableItem item, {
    StockMovementType initialType = StockMovementType.in_,
  }) async {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    StockMovementType type = initialType;
    String? errorText;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final isMerma = type == StockMovementType.merma;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(item.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock actual: ${item.stock.toStringAsFixed(item.pricingType.isWeight ? 3 : 0)} ${item.stockUnitLabel}',
                    style: Get.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  SegmentedButton<StockMovementType>(
                    segments: const [
                      ButtonSegment(
                        value: StockMovementType.in_,
                        label: Text('Entrada'),
                        icon: Icon(Icons.add_box_outlined),
                      ),
                      ButtonSegment(
                        value: StockMovementType.merma,
                        label: Text('Merma'),
                        icon: Icon(Icons.report_problem_outlined),
                      ),
                      ButtonSegment(
                        value: StockMovementType.adjustment,
                        label: Text('Ajuste'),
                        icon: Icon(Icons.tune),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (selection) => setDialogState(() => type = selection.first),
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  TextField(
                    controller: quantityController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: type == StockMovementType.adjustment ? 'Diferencia (+/-)' : 'Cantidad',
                      hintText: type == StockMovementType.adjustment
                          ? 'Ej: -2.5 para restar, 3 para sumar'
                          : 'Ej: 10',
                      suffixText: item.stockUnitLabel,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: AppConfig.paddingMedium),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isMerma ? 'Razón (obligatoria)' : 'Nota (opcional)',
                      hintText: isMerma ? 'Ej: dañada, vencida, golpeada' : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cancelar'),
              ),
              Obx(() {
                return ElevatedButton(
                  onPressed: controller.isRegisteringStockMovement.value
                      ? null
                      : () async {
                          final raw = double.tryParse(quantityController.text.trim().replaceAll(',', '.'));
                          if (raw == null || raw == 0) {
                            setDialogState(() => errorText = 'Ingresa una cantidad válida');
                            return;
                          }
                          if (isMerma && reasonController.text.trim().isEmpty) {
                            setDialogState(() => errorText = null);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Indica la razón de la merma')),
                            );
                            return;
                          }

                          final quantity = type == StockMovementType.adjustment ? raw : raw.abs();
                          final error = await controller.registerStockMovement(
                            item.id,
                            RegisterStockMovementParams(
                              type: type,
                              quantity: quantity,
                              reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                            ),
                          );

                          if (!context.mounted) return;
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }
                          Navigator.of(context, rootNavigator: true).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Movimiento registrado')),
                            );
                          }
                        },
                  child: controller.isRegisteringStockMovement.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar'),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
