// lib/features/vegetables/presentation/pages/vegetable_sales_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../expenses/presentation/widgets/custom_date_range_picker.dart';
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

  void _showDateFilterDialog(VegetablesController controller) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            child: CustomDateRangePicker(
              rangeStart: controller.salesFilterStart.value,
              rangeEnd: controller.salesFilterEnd.value,
              onApplyFilter: (start, end, label) {
                controller.applySalesFilter(start, end, label);
                Navigator.of(context, rootNavigator: true).pop();
              },
              onClearFilter: () => controller.clearSalesFilter(),
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
                  Text('Total ${controller.salesFilterLabel.value} · ${controller.filteredSales.length} venta(s)', style: Get.textTheme.bodyMedium),
                  Text(
                    NumberFormatter.formatCurrency(controller.filteredSalesTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            if (controller.salesFilterStart.value != null)
              IconButton(
                tooltip: 'Volver a hoy',
                icon: const Icon(Icons.close),
                onPressed: controller.clearSalesFilter,
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

          final filtered = controller.filteredSales;

          return RefreshIndicator(
            onRefresh: controller.loadSales,
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
                          Icon(Icons.receipt_long_outlined, size: 48, color: Get.theme.disabledColor),
                          const SizedBox(height: 8),
                          const Text('Sin ventas en este período'),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((sale) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.eco_outlined, color: Get.theme.colorScheme.primary),
                        ),
                        title: Text(sale.formattedNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${sale.formattedCreatedAtWithTime} · ${sale.soldBy} · ${sale.paymentMethodName}'),
                        trailing: Text(
                          NumberFormatter.formatCurrency(sale.total),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        onTap: () => Get.toNamed(AppRoutes.vegetableSaleDetail, arguments: sale.id),
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
