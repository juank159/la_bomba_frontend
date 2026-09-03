// lib/features/vegetables/presentation/pages/vegetable_stock_history_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/entities/vegetable_stock_movement.dart';
import '../controllers/vegetables_controller.dart';

/// Historial completo de movimientos de stock de un producto (entradas,
/// ventas, mermas, ajustes) - la auditoría detrás del saldo que se ve en
/// VegetableInventoryPage.
class VegetableStockHistoryPage extends StatefulWidget {
  final String itemId;

  const VegetableStockHistoryPage({super.key, required this.itemId});

  @override
  State<VegetableStockHistoryPage> createState() => _VegetableStockHistoryPageState();
}

class _VegetableStockHistoryPageState extends State<VegetableStockHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadStockMovements(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();
    final item = controller.items.firstWhereOrNull((i) => i.id == widget.itemId);

    return Scaffold(
      appBar: AppBar(title: Text(item?.name ?? 'Historial de inventario'), elevation: 0),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            if (item != null) _buildStockHeader(item),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingStockMovements.value && controller.stockMovements.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.stockMovements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 48, color: Get.theme.disabledColor),
                        const SizedBox(height: 8),
                        const Text('Aún no hay movimientos registrados'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => controller.loadStockMovements(widget.itemId),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    itemCount: controller.stockMovements.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _buildMovementTile(controller.stockMovements[index], item),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockHeader(VegetableItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      color: Get.theme.colorScheme.primary.withValues(alpha: 0.06),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Stock actual', style: Get.textTheme.bodyMedium),
          Text(
            '${item.stock.toStringAsFixed(item.pricingType.isWeight ? 3 : 0)} ${item.stockUnitLabel}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTile(VegetableStockMovement movement, VegetableItem? item) {
    final unit = item?.stockUnitLabel ?? '';
    final color = movement.isPositive ? Colors.green : Get.theme.colorScheme.error;
    final sign = movement.isPositive ? '+' : '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(_iconFor(movement.type), color: color, size: 20),
        ),
        title: Text(movement.type.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            movement.formattedCreatedAtWithTime,
            movement.createdBy,
            if (movement.reason != null && movement.reason!.isNotEmpty) movement.reason!,
          ].join(' · '),
        ),
        isThreeLine: movement.reason != null && movement.reason!.isNotEmpty,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign${movement.quantity.toStringAsFixed(3)} $unit',
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            Text(
              'Saldo: ${movement.resultingStock.toStringAsFixed(3)}',
              style: Get.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(StockMovementType type) {
    switch (type) {
      case StockMovementType.in_:
        return Icons.add_box_outlined;
      case StockMovementType.sale:
        return Icons.point_of_sale_outlined;
      case StockMovementType.merma:
        return Icons.report_problem_outlined;
      case StockMovementType.adjustment:
        return Icons.tune;
    }
  }
}
