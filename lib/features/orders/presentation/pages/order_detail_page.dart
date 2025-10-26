// lib/features/orders/presentation/pages/order_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_item_card.dart';
import '../../domain/entities/order.dart' as order_entity;

/// Order detail page showing full order information
class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _isGroupedBySupplier = false;
  Map<String, List<dynamic>>? _groupedItems;

  /// Check if current user can edit the given order
  bool _canEditOrder(order_entity.Order order) {
    try {
      final authController = Get.find<AuthController>();

      // Admins can edit any order (pending or completed)
      if (authController.isAdmin) {
        return true;
      }

      // For completed orders: only admins can edit
      if (order.isCompleted) {
        return false;
      }

      // Supervisors can edit pending orders:
      // - Their own orders
      // - Orders created by employees
      // - But NOT orders created by admins or other supervisors
      if (authController.isSupervisor) {
        // Can edit their own orders
        if (order.createdBy?.id == authController.user?.id) {
          return true;
        }

        // Can edit orders created by employees only
        // Cannot edit orders created by admins or other supervisors
        if (order.createdBy?.role.isEmployee ?? false) {
          return true;
        }

        return false;
      }

      // Employees can only edit their own pending orders
      if (authController.isEmployee) {
        return order.createdBy?.id == authController.user?.id;
      }

      return false;
    } catch (e) {
      // If AuthController is not available, default to false for security
      return false;
    }
  }

  /// Build menu items based on user role and order permissions
  List<PopupMenuEntry<String>> _buildMenuItems(order_entity.Order order) {
    final authController = Get.find<AuthController>();
    List<PopupMenuEntry<String>> items = [];

    // Edit option - only show if user can edit this order
    if (_canEditOrder(order)) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: AppConfig.paddingSmall),
              Text('Editar'),
            ],
          ),
        ),
      );
    }

    // Admin-only options
    if (authController.isAdmin) {
      // Complete order option (only for pending orders)
      if (order.isPending) {
        items.add(
          PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppConfig.successColor,
                ),
                SizedBox(width: AppConfig.paddingSmall),
                Text('Marcar como Completado'),
              ],
            ),
          ),
        );
      }

      // Delete option
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: AppConfig.errorColor),
              SizedBox(width: AppConfig.paddingSmall),
              Text('Eliminar', style: TextStyle(color: AppConfig.errorColor)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();

    // Load order details on page init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getOrderById(widget.orderId);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        elevation: 0,
        actions: [
          Obx(() {
            final order = controller.selectedOrder.value;
            if (order != null && _canEditOrder(order)) {
              return PopupMenuButton(
                itemBuilder: (context) => _buildMenuItems(order),
                onSelected: (value) => _handleMenuAction(value, order.id),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const LoadingWidget(message: 'Cargando pedido...');
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return _buildErrorState(controller);
          }

          final order = controller.selectedOrder.value;
          if (order == null) {
            return _buildNotFoundState();
          }

          return RefreshIndicator(
          onRefresh: () => controller.getOrderById(widget.orderId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                _buildOrderHeader(order),

                const SizedBox(height: AppConfig.paddingLarge),

                // Order Items
                _buildItemsSection(order),

                const SizedBox(height: AppConfig.paddingLarge),

                // Order Summary
                _buildSummarySection(order),
              ],
            ),
          ),
        );
      }),  // Close Obx
    ),     // Close SafeArea
  );
  }

  Widget _buildOrderHeader(order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.description,
                    style: TextStyle(
                      fontSize: AppConfig.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Get.theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                OrderStatusBadge(status: order.status, isLarge: true),
              ],
            ),

            if (order.hasProvider) ...[
              const SizedBox(height: AppConfig.paddingMedium),
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 20,
                    color: Get.theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppConfig.paddingSmall),
                  Text(
                    'Proveedor: ${order.provider}',
                    style: TextStyle(
                      fontSize: AppConfig.bodyFontSize,
                      color: Get.theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppConfig.paddingMedium),

            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: AppConfig.paddingSmall),
                Text(
                  'Creado: ${order.formattedCreatedAtWithTime}',
                  style: TextStyle(
                    fontSize: AppConfig.captionFontSize,
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),

            if (order.createdBy != null) ...[
              const SizedBox(height: AppConfig.paddingSmall),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: AppConfig.paddingSmall),
                  Text(
                    'Por: ${order.createdBy!.displayName}',
                    style: TextStyle(
                      fontSize: AppConfig.captionFontSize,
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory, color: Get.theme.colorScheme.primary),
            const SizedBox(width: AppConfig.paddingSmall),
            Expanded(
              child: Text(
                'Productos (${order.totalItems})',
                style: TextStyle(
                  fontSize: AppConfig.headingFontSize,
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.onSurface,
                ),
              ),
            ),
            // Toggle para vista agrupada (solo si el pedido no tiene proveedor general)
            if (!order.hasProvider) ...[
              Text(
                'Agrupar',
                style: TextStyle(
                  fontSize: AppConfig.captionFontSize,
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: AppConfig.paddingSmall),
              Switch(
                value: _isGroupedBySupplier,
                onChanged: (value) {
                  setState(() {
                    _isGroupedBySupplier = value;
                    if (value) {
                      _loadGroupedItems();
                    }
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppConfig.paddingMedium),

        if (order.items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConfig.paddingLarge),
              child: Center(
                child: Text(
                  'No hay productos en este pedido',
                  style: TextStyle(
                    fontSize: AppConfig.bodyFontSize,
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          )
        else if (_isGroupedBySupplier)
          _buildGroupedItemsView(order)
        else
          ...order.items.map((item) {
            // Determinar si mostrar cantidades solicitadas basado en el rol
            bool showRequestedQuantities = false;
            try {
              final authController = Get.find<AuthController>();
              showRequestedQuantities = authController.isAdmin;
            } catch (e) {
              showRequestedQuantities = false;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppConfig.paddingSmall),
              child: OrderItemCard(
                item: item,
                showQuantityControls: false,
                isReadOnly: true,
                showRequestedQuantities: showRequestedQuantities,
              ),
            );
          }).toList(),
      ],
    );
  }

  /// Load items grouped by supplier using the use case
  Future<void> _loadGroupedItems() async {
    try {
      final controller = Get.find<OrdersController>();
      // Here we would call the use case if needed, but for now we'll group locally
      // since the Order entity already contains the items with supplier info
      final order = controller.selectedOrder.value;
      if (order != null) {
        // Group items by supplier locally
        final Map<String, List<dynamic>> grouped = {};

        for (var item in order.items) {
          final supplierKey = item.supplier?.nombre ?? 'Sin Asignar';
          if (!grouped.containsKey(supplierKey)) {
            grouped[supplierKey] = [];
          }
          grouped[supplierKey]!.add(item);
        }

        setState(() {
          _groupedItems = grouped;
        });
      }
    } catch (e) {
      print('Error loading grouped items: $e');
    }
  }

  /// Build the grouped items view
  Widget _buildGroupedItemsView(order) {
    if (_groupedItems == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConfig.paddingLarge),
          child: LoadingWidget(message: 'Agrupando productos...'),
        ),
      );
    }

    // Determinar si mostrar cantidades solicitadas basado en el rol
    bool showRequestedQuantities = false;
    try {
      final authController = Get.find<AuthController>();
      showRequestedQuantities = authController.isAdmin;
    } catch (e) {
      showRequestedQuantities = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _groupedItems!.entries.map((entry) {
        final supplierName = entry.key;
        final items = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConfig.paddingMedium),
                decoration: BoxDecoration(
                  color: supplierName == 'Sin Asignar'
                      ? Get.theme.colorScheme.surface.withOpacity(0.5)
                      : Get.theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      supplierName == 'Sin Asignar'
                          ? Icons.help_outline
                          : Icons.business,
                      size: 20,
                      color: supplierName == 'Sin Asignar'
                          ? Get.theme.colorScheme.onSurface.withOpacity(0.6)
                          : Get.theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppConfig.paddingSmall),
                    Expanded(
                      child: Text(
                        supplierName,
                        style: TextStyle(
                          fontSize: AppConfig.bodyFontSize,
                          fontWeight: FontWeight.bold,
                          color: supplierName == 'Sin Asignar'
                              ? Get.theme.colorScheme.onSurface.withOpacity(0.6)
                              : Get.theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConfig.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length} ${items.length == 1 ? 'producto' : 'productos'}',
                        style: TextStyle(
                          fontSize: AppConfig.captionFontSize,
                          fontWeight: FontWeight.w600,
                          color: Get.theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Items for this supplier
              Padding(
                padding: const EdgeInsets.all(AppConfig.paddingMedium),
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppConfig.paddingSmall),
                      child: OrderItemCard(
                        item: item,
                        showQuantityControls: false,
                        isReadOnly: true,
                        showRequestedQuantities: showRequestedQuantities,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummarySection(order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen',
              style: TextStyle(
                fontSize: AppConfig.headingFontSize,
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConfig.paddingMedium),

            _buildSummaryRow(
              'Total de Productos:',
              '${order.totalItems}',
              Icons.inventory,
            ),

            _buildSummaryRow(
              'Cantidad Existente:',
              '${order.totalExistingQuantity}',
              Icons.inventory_2,
            ),

            // Solo mostrar cantidad solicitada a administradores
            if (order.totalRequestedQuantity > 0) ...[
              Builder(
                builder: (context) {
                  try {
                    final authController = Get.find<AuthController>();
                    if (authController.isAdmin) {
                      return _buildSummaryRow(
                        'Cantidad Solicitada:',
                        '${order.totalRequestedQuantity}',
                        Icons.request_quote,
                        color: Get.theme.colorScheme.secondary,
                      );
                    }
                    return const SizedBox.shrink();
                  } catch (e) {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConfig.paddingSmall),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Get.theme.colorScheme.primary),
          const SizedBox(width: AppConfig.paddingSmall),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppConfig.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: color ?? Get.theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OrdersController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
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
              'Error al cargar pedido',
              style: TextStyle(
                fontSize: AppConfig.headingFontSize,
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            Text(
              controller.errorMessage.value,
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingLarge),
            ElevatedButton(
              onPressed: () => controller.getOrderById(widget.orderId),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Get.theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            Text(
              'Pedido no encontrado',
              style: TextStyle(
                fontSize: AppConfig.headingFontSize,
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingSmall),
            Text(
              'El pedido que buscas no existe o ha sido eliminado',
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConfig.paddingLarge),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, String orderId) {
    final controller = Get.find<OrdersController>();

    switch (action) {
      case 'edit':
        Get.offNamed('/orders/edit', arguments: orderId);
        break;
      case 'complete':
        _showCompleteOrderDialog(controller, orderId);
        break;
      case 'delete':
        _showDeleteOrderDialog(controller, orderId);
        break;
    }
  }

  void _showCompleteOrderDialog(OrdersController controller, String orderId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Completar Pedido'),
        content: const Text(
          '¿Estás seguro de que quieres marcar este pedido como completado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.updateOrder(
                id: orderId,
                status: 'completed',
              );
              if (success) {
                Get.back(); // Return to orders list
              }
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteOrderDialog(OrdersController controller, String orderId) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Eliminar Pedido',
          style: TextStyle(color: AppConfig.errorColor),
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este pedido? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteOrder(orderId);
              if (success) {
                Get.back(); // Return to orders list
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
