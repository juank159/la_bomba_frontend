//lib /features/orders/presentation/widgets/order_card.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../domain/entities/order.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'order_status_badge.dart';

/// Order card widget for displaying order information in lists
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final VoidCallback? onStatusTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;
  final VoidCallback? onShare;
  final bool showActions;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onStatusTap,
    this.onEdit,
    this.onDelete,
    this.onComplete,
    this.onShare,
    this.showActions = false,
  });

  /// Check if current user is admin
  bool get _isAdmin {
    try {
      final authController = Get.find<AuthController>();
      return authController.isAdmin;
    } catch (e) {
      return false;
    }
  }

  /// Check if current user can edit this order
  bool get _canEditOrder {
    try {
      final authController = Get.find<AuthController>();

      // For completed orders, only admins can edit
      if (order.isCompleted && !authController.isAdmin) {
        return false;
      }

      // Admins can edit any order
      if (authController.isAdmin) {
        return true;
      }

      // Supervisors can edit:
      // - Their own pending orders
      // - Pending orders created by employees
      // - But NOT orders created by admins or other supervisors
      if (authController.isSupervisor && order.isPending) {
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
        return order.createdBy?.id == authController.user?.id && order.isPending;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Order Icon
                  Container(
                    padding: const EdgeInsets.all(AppConfig.paddingSmall),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        AppConfig.borderRadius,
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      size: 20,
                      color: Get.theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppConfig.paddingMedium),

                  // Order Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.description,
                          style: TextStyle(
                            fontSize: AppConfig.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: Get.theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (order.hasProvider) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 14,
                                color: Get.theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  order.provider!,
                                  style: TextStyle(
                                    fontSize: AppConfig.captionFontSize,
                                    color: Get.theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Badge
                  GestureDetector(
                    onTap: onStatusTap,
                    child: OrderStatusBadge(status: order.status),
                  ),
                ],
              ),

              const SizedBox(height: AppConfig.paddingMedium),

              // Order Details Row
              Row(
                children: [
                  // Items Count
                  _buildInfoItem(
                    icon: Icons.inventory,
                    label: 'Artículos',
                    value: '${order.totalItems}',
                  ),
                  const SizedBox(width: AppConfig.paddingLarge),

                  // Total Quantities
                  _buildInfoItem(
                    icon: Icons.numbers,
                    label: 'Cantidad',
                    value: '${order.totalExistingQuantity}',
                  ),
                  const SizedBox(width: AppConfig.paddingLarge),

                  // Created Date
                  _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Fecha',
                    value: order.formattedCreatedAt,
                  ),
                ],
              ),

              // Requested Quantities (only visible to admins)
              if (_isAdmin && order.totalRequestedQuantity > 0) ...[
                const SizedBox(height: AppConfig.paddingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConfig.paddingSmall,
                    vertical: AppConfig.paddingSmall / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.secondaryContainer.withOpacity(
                      0.5,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppConfig.borderRadius / 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.request_quote,
                        size: 14,
                        color: Get.theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Solicitado: ${order.totalRequestedQuantity}',
                        style: TextStyle(
                          fontSize: AppConfig.smallFontSize,
                          color: Get.theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Created By (if available)
              if (order.createdBy != null) ...[
                const SizedBox(height: AppConfig.paddingSmall),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Creado por ${order.createdBy!.displayName}',
                      style: TextStyle(
                        fontSize: AppConfig.smallFontSize,
                        color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],

              // Actions Row (always show, but with different options based on admin status and order status)
              const SizedBox(height: AppConfig.paddingMedium),
              const Divider(height: 1),
              const SizedBox(height: AppConfig.paddingSmall),
              Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 8,
                children: [
                  // Ver detalles - Always visible
                  _buildActionButton(
                    icon: Icons.visibility,
                    label: 'Ver detalles',
                    onTap: onTap ?? () {},
                    color: Get.theme.colorScheme.secondary,
                  ),

                  // Edit action - based on user permissions and order status
                  if (_canEditOrder && onEdit != null)
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'Editar',
                      onTap: onEdit!,
                      color: Get.theme.colorScheme.primary,
                    ),

                  // Admin-only actions
                  if (_isAdmin) ...[
                    // Complete - Only for pending orders
                    if (order.status == OrderStatus.pending &&
                        onComplete != null)
                      _buildActionButton(
                        icon: Icons.check_circle,
                        label: 'Completar',
                        onTap: onComplete!,
                        color: Get.theme.colorScheme.tertiary,
                      ),

                    // Share PDF - Only available for completed orders
                    if (order.status == OrderStatus.completed &&
                        onShare != null)
                      _buildActionButton(
                        icon: Icons.picture_as_pdf,
                        label: 'Compartir PDF',
                        onTap: onShare!,
                        color: Get.theme.colorScheme.primary.withValues(
                          alpha: 0.8,
                        ),
                      ),

                    // Delete - Only for pending orders
                    if (order.status == OrderStatus.pending && onDelete != null)
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'Eliminar',
                        onTap: onDelete!,
                        color: Get.theme.colorScheme.error,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Get.theme.colorScheme.primary),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: AppConfig.captionFontSize,
              fontWeight: FontWeight.w600,
              color: Get.theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: AppConfig.smallFontSize,
              color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConfig.paddingSmall,
          vertical: AppConfig.paddingSmall / 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: AppConfig.smallFontSize, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
