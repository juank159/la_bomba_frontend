import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../domain/entities/client.dart';

/// ClientCard - Widget to display client information in a card
class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;

  const ClientCard({
    super.key,
    required this.client,
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
              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      client.nombre,
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Contact info
                    if (client.celular != null) ...[
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
                            client.celular!,
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Get.theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (client.email != null) ...[
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
                              client.email!,
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
        client.initials,
        style: TextStyle(
          color: Get.theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
