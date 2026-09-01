// lib/features/vegetables/presentation/pages/vegetable_sales_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/vegetables_controller.dart';

class VegetableSalesListPage extends StatefulWidget {
  const VegetableSalesListPage({super.key});

  @override
  State<VegetableSalesListPage> createState() => _VegetableSalesListPageState();
}

class _VegetableSalesListPageState extends State<VegetableSalesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas de Verduras'),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingSales.value && controller.sales.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Get.theme.disabledColor),
                  const SizedBox(height: 8),
                  const Text('Aún no hay ventas registradas'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadSales,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              itemCount: controller.sales.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sale = controller.sales[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.eco_outlined, color: Get.theme.colorScheme.primary),
                    ),
                    title: Text(sale.formattedNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${sale.formattedCreatedAtWithTime} · ${sale.soldBy}'),
                    trailing: Text(
                      NumberFormatter.formatCurrency(sale.total),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    onTap: () => Get.toNamed(AppRoutes.vegetableSaleDetail, arguments: sale.id),
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
