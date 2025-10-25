import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../domain/entities/supplier.dart';

/// SupplierCard - Widget to display supplier information in a card
class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback? onTap;

  const SupplierCard({
    super.key,
    required this.supplier,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: AppConfig.paddingMedium,
        vertical: AppConfig.paddingSmall,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Row(
            children: [
              // Avatar with initials
              _buildAvatar(),
              const SizedBox(width: AppConfig.paddingMedium),
              // Supplier info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      supplier.nombre,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Contact info
                    if (supplier.celular != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: Get.theme.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            supplier.celular!,
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Get.theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (supplier.email != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 16,
                            color: Get.theme.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              supplier.email!,
                              style: Get.textTheme.bodySmall?.copyWith(
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
              // Trailing icon
              Icon(
                Icons.chevron_right,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build avatar with initials
  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      child: Text(
        supplier.initials,
        style: TextStyle(
          color: Get.theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
