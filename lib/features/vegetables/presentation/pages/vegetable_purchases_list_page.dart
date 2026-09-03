// lib/features/vegetables/presentation/pages/vegetable_purchases_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
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

          if (controller.purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 48, color: Get.theme.disabledColor),
                  const SizedBox(height: 8),
                  const Text('Aún no hay compras registradas'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadPurchases,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              itemCount: controller.purchases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final purchase = controller.purchases[index];
                return Card(
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
              },
            ),
          );
        }),
      ),
    );
  }
}
