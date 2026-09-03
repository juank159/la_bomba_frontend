// lib/features/vegetables/presentation/pages/vegetable_purchases_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../expenses/presentation/widgets/custom_date_range_picker.dart';
import '../controllers/vegetables_controller.dart';

class VegetablePurchasesListPage extends StatefulWidget {
  const VegetablePurchasesListPage({super.key});

  @override
  State<VegetablePurchasesListPage> createState() => _VegetablePurchasesListPageState();
}

class _VegetablePurchasesListPageState extends State<VegetablePurchasesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadPurchases();
    });
  }

  void _showDateFilterDialog(VegetablesController controller) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            child: CustomDateRangePicker(
              rangeStart: controller.purchasesFilterStart.value,
              rangeEnd: controller.purchasesFilterEnd.value,
              onApplyFilter: (start, end, label) {
                controller.applyPurchasesFilter(start, end, label);
                Navigator.of(context, rootNavigator: true).pop();
              },
              onClearFilter: () => controller.clearPurchasesFilter(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(VegetablesController controller) {
    return Obx(() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total ${controller.purchasesFilterLabel.value} · ${controller.filteredPurchases.length} compra(s)', style: Get.textTheme.bodyMedium),
                  Text(
                    NumberFormatter.formatCurrency(controller.filteredPurchasesTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            if (controller.purchasesFilterStart.value != null)
              IconButton(
                tooltip: 'Volver a hoy',
                icon: const Icon(Icons.close),
                onPressed: controller.clearPurchasesFilter,
              ),
            IconButton(
              tooltip: 'Filtrar por fecha',
              icon: const Icon(Icons.date_range),
              onPressed: () => _showDateFilterDialog(controller),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Compras de Verduras'), elevation: 0),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createVegetablePurchase),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva compra'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingPurchases.value && controller.purchases.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = controller.filteredPurchases;

          return RefreshIndicator(
            onRefresh: controller.loadPurchases,
            child: ListView(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              children: [
                _buildTotalCard(controller),
                const SizedBox(height: AppConfig.paddingMedium),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 48, color: Get.theme.disabledColor),
                          const SizedBox(height: 8),
                          const Text('Sin compras en este período'),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((purchase) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.shopping_cart_outlined, color: Get.theme.colorScheme.primary),
                        ),
                        title: Text(purchase.formattedNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${purchase.formattedCreatedAtWithTime} · ${purchase.createdBy}'),
                        trailing: Text(
                          NumberFormatter.formatCurrency(purchase.total),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        onTap: () => Get.toNamed(AppRoutes.vegetablePurchaseDetail, arguments: purchase.id),
                      ),
                    );
                  }),
              ],
            ),
          );
        }),
      ),
    );
  }
}
