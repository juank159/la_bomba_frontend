import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';

/// Empty state widget for when no orders are found
class EmptyOrdersWidget extends StatelessWidget {
  const EmptyOrdersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty State Icon
            Container(
              padding: const EdgeInsets.all(AppConfig.paddingLarge),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Get.theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: AppConfig.paddingLarge),
            
            // Empty State Title
            Text(
              'No hay pedidos',
              style: TextStyle(
                fontSize: AppConfig.headingFontSize,
                fontWeight: FontWeight.w600,
                color: Get.theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppConfig.paddingMedium),
            
            // Empty State Description
            Text(
              'Cuando crees o recibas pedidos, aparecerán aquí. '
              '¡Comienza creando tu primer pedido!',
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppConfig.paddingXLarge),
            
            // Create Order Button
            ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/orders/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Pedido'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConfig.paddingLarge,
                  vertical: AppConfig.paddingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}