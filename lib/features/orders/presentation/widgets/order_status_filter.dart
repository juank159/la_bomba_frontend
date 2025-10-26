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
          // Filter chips row - Responsive with Wrap
          Wrap(
            spacing: AppConfig.paddingSmall,
            runSpacing: AppConfig.paddingSmall,
            children: [
              _buildFilterChip(
                label: 'Todos',
                isSelected: controller.statusFilter.value.isEmpty,
                onTap: () => controller.filterByStatus(''),
                count: controller.allOrdersCount,
              ),
              _buildFilterChip(
                label: 'Pendientes',
                isSelected: controller.statusFilter.value == 'pending',
                onTap: () => controller.filterByStatus('pending'),
                count: controller.pendingOrdersCount,
                color: AppConfig.warningColor,
              ),
              _buildFilterChip(
                label: 'Completados',
                isSelected: controller.statusFilter.value == 'completed',
                onTap: () => controller.filterByStatus('completed'),
                count: controller.completedOrdersCount,
                color: AppConfig.successColor,
              ),
            ],
          ),

          // Sub-filters for Pending orders (Mixtos and Unificados)
          if (controller.statusFilter.value == 'pending') ...[
            const SizedBox(height: AppConfig.paddingSmall),
            Wrap(
              spacing: AppConfig.paddingSmall,
              runSpacing: AppConfig.paddingSmall,
              children: [
                _buildSubFilterChip(
                  label: 'Mixtos',
                  icon: Icons.merge_type,
                  count: controller.pendingMixedOrdersCount,
                  color: Get.theme.colorScheme.tertiary,
                  isSelected: controller.subTypeFilter.value == 'mixed',
                  onTap: () => controller.filterBySubType(
                    controller.subTypeFilter.value == 'mixed' ? '' : 'mixed',
                  ),
                ),
                _buildSubFilterChip(
                  label: 'Unificados',
                  icon: Icons.business,
                  count: controller.pendingUnifiedOrdersCount,
                  color: Get.theme.colorScheme.secondary,
                  isSelected: controller.subTypeFilter.value == 'unified',
                  onTap: () => controller.filterBySubType(
                    controller.subTypeFilter.value == 'unified' ? '' : 'unified',
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
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

  Widget _buildSubFilterChip({
    required String label,
    required IconData icon,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConfig.paddingSmall,
            vertical: AppConfig.paddingSmall / 2,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppConfig.smallFontSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: AppConfig.smallFontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
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
