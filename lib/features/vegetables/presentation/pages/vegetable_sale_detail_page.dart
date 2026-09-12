// lib/features/vegetables/presentation/pages/vegetable_sale_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/services/password_gate_service.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../controllers/vegetables_controller.dart';

class VegetableSaleDetailPage extends StatefulWidget {
  final String saleId;
  const VegetableSaleDetailPage({super.key, required this.saleId});

  @override
  State<VegetableSaleDetailPage> createState() => _VegetableSaleDetailPageState();
}

class _VegetableSaleDetailPageState extends State<VegetableSaleDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadSaleById(widget.saleId);
    });
  }

  Future<void> _confirmDelete(VegetablesController controller, String saleId) async {
    // Cierra con el Navigator nativo (no Get.back()): encadenar Get.back()
    // con safeSnackbar/otro Get.dialog en la sesión deja el overlay de GetX
    // en un estado donde este diálogo deja de responder a sus botones (ni
    // confirmar ni cancelar hacen nada) - mismo patrón ya usado en
    // ExpensesListPage._showDeleteConfirmation.
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Eliminar venta'),
        content: const Text(
          '¿Seguro que quieres eliminar esta venta? Se revertirá el stock que descontó y, si afecta una caja ya cerrada, se recalculará el cuadre. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    // Igual que en Gastos: eliminar requiere la contraseña del usuario
    // administrador, sin importar quién esté logueado (ver PasswordGateService
    // y AuthService.verifyPassword) - así solo esa persona puede autorizar
    // borrar una venta ya registrada.
    final granted = await PasswordGateService().requestAccess(
      gateId: 'delete_vegetable_sale',
      title: 'Verificación requerida',
      message: 'Ingresa la contraseña para eliminar esta venta',
    );
    if (!granted) return;

    final success = await controller.deleteSale(saleId);
    if (success && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Venta'),
        elevation: 0,
        actions: [
          Obx(() {
            final sale = controller.selectedSale.value;
            if (sale == null || !sale.isActive) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Eliminar venta',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(controller, sale.id),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingSaleDetail.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final sale = controller.selectedSale.value;
          if (sale == null) {
            return const Center(child: Text('No se encontró la venta'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sale.formattedNumber, style: Get.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(sale.formattedCreatedAtWithTime, style: Get.textTheme.bodyMedium),
                Text('Atendido por: ${sale.soldBy}', style: Get.textTheme.bodySmall),
                Text('Pago: ${sale.paymentMethodName}', style: Get.textTheme.bodySmall),
                const SizedBox(height: AppConfig.paddingLarge),
                ...sale.items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    child: ListTile(
                      title: Text(item.description),
                      subtitle: Text(
                        item.pricingType.isWeight
                            ? '${item.quantityLabel} x ${NumberFormatter.formatCurrency(item.unitPrice)}/kg'
                            : '${item.quantityLabel} x ${NumberFormatter.formatCurrency(item.unitPrice)}',
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
                      NumberFormatter.formatCurrency(sale.total),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppConfig.paddingLarge),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => controller.printSale(sale),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Reimprimir recibo'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
