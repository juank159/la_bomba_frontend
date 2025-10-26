// lib/features/orders/presentation/pages/orders_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_filter.dart';
import '../widgets/empty_orders_widget.dart';

/// Orders list page displaying all orders with search, filter, and pagination
class OrdersListPage extends StatelessWidget {
  const OrdersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();
    final scrollController = ScrollController();

    // Setup infinite scroll
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.loadMoreOrders();
      }
    });

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Pedidos'),
        elevation: 0,
        automaticallyImplyLeading: true, // Show drawer button
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.toNamed('/orders/create');
            },
            tooltip: 'Crear pedido',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.refreshOrders();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                CustomInput(
                  hintText: 'Buscar por descripción o proveedor...',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (value) {
                    controller.searchOrders(value);
                  },
                  suffixIcon: Obx(() {
                    return controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clearFilters();
                            },
                          )
                        : const SizedBox.shrink();
                  }),
                ),
                const SizedBox(height: AppConfig.paddingMedium),

                // Status Filter
                const OrderStatusFilter(),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.filteredOrders.isEmpty) {
                return const LoadingWidget(message: 'Cargando pedidos...');
              }

              if (controller.showErrorState) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Get.theme.colorScheme.error,
                      ),
                      const SizedBox(height: AppConfig.paddingMedium),
                      Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppConfig.bodyFontSize,
                          color: Get.theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: AppConfig.paddingLarge),
                      ElevatedButton(
                        onPressed: () {
                          controller.loadOrders();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.showEmptyState) {
                return const EmptyOrdersWidget();
              }

              return RefreshIndicator(
                onRefresh: () => controller.refreshOrders(),
                child: Column(
                  children: [
                    // Status Text
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConfig.paddingMedium,
                        vertical: AppConfig.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.primaryContainer
                            .withOpacity(0.3),
                      ),
                      child: Text(
                        controller.statusText,
                        style: TextStyle(
                          fontSize: AppConfig.captionFontSize,
                          color: Get.theme.colorScheme.onSurface.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ),

                    // Orders List
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(AppConfig.paddingMedium),
                        itemCount:
                            controller.filteredOrders.length +
                            (controller.isLoadingMore.value ? 1 : 0),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppConfig.paddingSmall),
                        itemBuilder: (context, index) {
                          if (index == controller.filteredOrders.length) {
                            // Loading more indicator
                            return const Padding(
                              padding: EdgeInsets.all(AppConfig.paddingMedium),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final order = controller.filteredOrders[index];
                          return OrderCard(
                            order: order,
                            onTap: () {
                              Get.toNamed(
                                '/orders/detail',
                                arguments: order.id,
                              );
                            },
                            onStatusTap: () {
                              controller.filterByStatus(order.status.value);
                            },
                            onEdit: () {
                              Get.offNamed('/orders/edit', arguments: order.id);
                            },
                            onComplete: () async {
                              final result = await Get.dialog<bool>(
                                AlertDialog(
                                  title: const Text('Completar Pedido'),
                                  content: Text(
                                    '¿Está seguro de que desea completar el pedido "${order.description}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(result: false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Get.back(result: true),
                                      child: const Text('Completar'),
                                    ),
                                  ],
                                ),
                              );

                              if (result == true) {
                                await controller.completeOrder(order.id);
                              }
                            },
                            onShare: () async {
                              await controller.shareOrderPdf(order);
                            },
                            onDelete: () async {
                              final result = await Get.dialog<bool>(
                                AlertDialog(
                                  title: const Text('Eliminar Pedido'),
                                  content: Text(
                                    '¿Está seguro de que desea eliminar el pedido "${order.description}"?\n\nEsta acción no se puede deshacer.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(result: false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Get.back(result: true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Get.theme.colorScheme.error,
                                        foregroundColor:
                                            Get.theme.colorScheme.onError,
                                      ),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );

                              if (result == true) {
                                await controller.deleteOrder(order.id);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed('/orders/create');
        },
        child: const Icon(Icons.add),
        tooltip: 'Crear pedido',
      ),
    );
  }
}
