// lib/features/vegetables/presentation/pages/vegetable_purchase_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/services/password_gate_service.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../controllers/vegetables_controller.dart';

class VegetablePurchaseDetailPage extends StatefulWidget {
  final String purchaseId;
  const VegetablePurchaseDetailPage({super.key, required this.purchaseId});

  @override
  State<VegetablePurchaseDetailPage> createState() => _VegetablePurchaseDetailPageState();
}

class _VegetablePurchaseDetailPageState extends State<VegetablePurchaseDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadPurchaseById(widget.purchaseId);
    });
  }

  Future<void> _confirmDelete(VegetablesController controller, String purchaseId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar compra'),
        content: const Text(
          '¿Seguro que quieres eliminar esta compra? Se revertirá el stock que ingresó y, si afecta una caja ya cerrada, se recalculará el cuadre. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Igual que en Gastos: eliminar requiere la contraseña del usuario
    // administrador, sin importar quién esté logueado (ver PasswordGateService
    // y AuthService.verifyPassword) - así solo esa persona puede autorizar
    // borrar una compra ya registrada.
    final granted = await PasswordGateService().requestAccess(
      gateId: 'delete_vegetable_purchase',
      title: 'Verificación requerida',
      message: 'Ingresa la contraseña para eliminar esta compra',
    );
    if (!granted) return;

    final success = await controller.deletePurchase(purchaseId);
    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Compra'),
        elevation: 0,
        actions: [
          Obx(() {
            final purchase = controller.selectedPurchase.value;
            if (purchase == null || !purchase.isActive) return const SizedBox.shrink();
            return Row(
              children: [
                IconButton(
                  tooltip: 'Editar compra',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Get.toNamed(AppRoutes.createVegetablePurchase, arguments: purchase.id),
                ),
                IconButton(
                  tooltip: 'Eliminar compra',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(controller, purchase.id),
                ),
              ],
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingPurchaseDetail.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final purchase = controller.selectedPurchase.value;
          if (purchase == null) {
            return const Center(child: Text('No se encontró la compra'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(purchase.formattedNumber, style: Get.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(purchase.formattedCreatedAtWithTime, style: Get.textTheme.bodyMedium),
                Text('Registrada por: ${purchase.createdBy}', style: Get.textTheme.bodySmall),
                Text('Pagada con: ${purchase.fundingSource.label}', style: Get.textTheme.bodySmall),
                const SizedBox(height: AppConfig.paddingLarge),
                ...purchase.items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    child: ListTile(
                      title: Text(item.description),
                      subtitle: Text(
                        item.isFreePurchase
                            ? 'Compra libre'
                            : '${NumberFormatter.formatQuantity(item.quantity ?? 0)} x ${NumberFormatter.formatCurrency(item.unitCost ?? 0)}',
                      ),
                      trailing: Text(
                        NumberFormatter.formatCurrency(item.total),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }),
                const Divider(height: AppConfig.paddingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      NumberFormatter.formatCurrency(purchase.total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
