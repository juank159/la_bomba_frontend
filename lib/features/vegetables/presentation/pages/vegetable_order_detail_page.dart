// lib/features/vegetables/presentation/pages/vegetable_order_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../controllers/vegetables_controller.dart';

class VegetableOrderDetailPage extends StatefulWidget {
  final String orderId;
  const VegetableOrderDetailPage({super.key, required this.orderId});

  @override
  State<VegetableOrderDetailPage> createState() => _VegetableOrderDetailPageState();
}

class _VegetableOrderDetailPageState extends State<VegetableOrderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Pedido'), elevation: 0),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingOrderDetail.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = controller.selectedOrder.value;
          if (order == null) {
            return const Center(child: Text('No se encontró el pedido'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.formattedNumber, style: Get.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(order.formattedCreatedAtWithTime, style: Get.textTheme.bodyMedium),
                Text('Hecho por: ${order.createdBy}', style: Get.textTheme.bodySmall),
                const SizedBox(height: AppConfig.paddingLarge),
                ...order.items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    child: ListTile(
                      leading: const Icon(Icons.eco_outlined),
                      title: Text(item.description),
                      trailing: Text(
                        item.quantityLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppConfig.paddingLarge),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.printOrder(order),
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Reimprimir'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.shareOrderPdf(order),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Compartir PDF'),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
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
