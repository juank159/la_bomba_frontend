// lib/features/vegetables/presentation/pages/vegetable_purchase_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
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

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Compra'), elevation: 0),
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
                const SizedBox(height: AppConfig.paddingLarge),
                ...purchase.items.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    child: ListTile(
                      title: Text(item.description),
                      subtitle: Text(
                        '${NumberFormatter.formatQuantity(item.quantity)} x ${NumberFormatter.formatCurrency(item.unitCost)}',
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
