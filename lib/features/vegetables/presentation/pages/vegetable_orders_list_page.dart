// lib/features/vegetables/presentation/pages/vegetable_orders_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/vegetables_controller.dart';

class VegetableOrdersListPage extends StatefulWidget {
  const VegetableOrdersListPage({super.key});

  @override
  State<VegetableOrdersListPage> createState() => _VegetableOrdersListPageState();
}

class _VegetableOrdersListPageState extends State<VegetableOrdersListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<VegetablesController>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos de Verduras'),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createVegetableOrder),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo pedido'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingOrders.value && controller.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConfig.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list_alt_outlined, size: 48, color: Get.theme.disabledColor),
                    const SizedBox(height: 8),
                    const Text('Aún no hay pedidos registrados'),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadOrders,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              itemCount: controller.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = controller.orders[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.list_alt_outlined, color: Get.theme.colorScheme.primary),
                    ),
                    title: Text(order.formattedNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${order.formattedCreatedAtWithTime} · ${order.createdBy}'),
                    trailing: Text(
                      '${order.items.length} producto${order.items.length == 1 ? '' : 's'}',
                      style: Get.textTheme.bodySmall,
                    ),
                    onTap: () => Get.toNamed(AppRoutes.vegetableOrderDetail, arguments: order.id),
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
