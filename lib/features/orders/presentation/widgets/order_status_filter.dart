import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../controllers/orders_controller.dart';

/// Status filter widget for filtering orders by status
class OrderStatusFilter extends StatelessWidget {
  const OrderStatusFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrdersController>();

    return Obx(() {
      return Column(
        children: [
          // Filter chips row
          Row(
            children: [
          Expanded(
            child: _buildFilterChip(
              label: 'Todos',
              isSelected: controller.statusFilter.value.isEmpty,
              onTap: () => controller.filterByStatus(''),
              count: controller.allOrdersCount,
            ),
          ),
          const SizedBox(width: AppConfig.paddingSmall),
          Expanded(
            child: _buildFilterChip(
              label: 'Pendientes',
              isSelected: controller.statusFilter.value == 'pending',
              onTap: () => controller.filterByStatus('pending'),
              count: controller.pendingOrdersCount,
              color: AppConfig.warningColor,
            ),
          ),
          const SizedBox(width: AppConfig.paddingSmall),
          Expanded(
            child: _buildFilterChip(
              label: 'Completados',
              isSelected: controller.statusFilter.value == 'completed',
              onTap: () => controller.filterByStatus('completed'),
              count: controller.completedOrdersCount,
              color: AppConfig.successColor,
            ),
            ),
          ],
        ),
        
        // Active filter indicator
        if (controller.statusFilter.value.isNotEmpty) ...[
          const SizedBox(height: AppConfig.paddingSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConfig.paddingSmall,
              vertical: AppConfig.paddingSmall / 2,
            ),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
              border: Border.all(
                color: Get.theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt,
                  size: 16,
                  color: Get.theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mostrando: ${_getFilterLabel(controller.statusFilter.value)}',
                  style: TextStyle(
                    fontSize: AppConfig.smallFontSize,
                    color: Get.theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => controller.filterByStatus(''),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Get.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        ],
      );
    });
  }
  
  String _getFilterLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pedidos Pendientes';
      case 'completed':
        return 'Pedidos Completados';
      default:
        return 'Todos los Pedidos';
    }
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required int count,
    Color? color,
  }) {
    final chipColor = color ?? Get.theme.colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.paddingMedium,
            vertical: AppConfig.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            border: Border.all(
              color: isSelected
                  ? chipColor
                  : Get.theme.colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppConfig.captionFontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? chipColor
                      : Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConfig.paddingSmall / 2,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withOpacity(0.2)
                      : Get.theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: AppConfig.smallFontSize,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? chipColor
                        : Get.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}