import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/supervisor_controller.dart';
import '../../domain/entities/product_update_task.dart';

class TaskFilterWidget extends StatelessWidget {
  final SupervisorController controller;

  const TaskFilterWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        TextField(
          onChanged: (value) => controller.setSearchQuery(value),
          decoration: InputDecoration(
            labelText: 'Buscar productos...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: Obx(() => controller.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.setSearchQuery(''),
                  )
                : const SizedBox.shrink()),
          ),
        ),
        
        const SizedBox(height: 12),

        // Filter chips - Using Wrap for better responsiveness
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Obx(() => _buildFilterChip(
              'all',
              'Todas',
              Icons.list,
              controller.selectedFilter == 'all',
            )),
            Obx(() => _buildFilterChip(
              'price',
              'Precio',
              Icons.monetization_on,
              controller.selectedFilter == 'price',
            )),
            Obx(() => _buildFilterChip(
              'info',
              'Info',
              Icons.info,
              controller.selectedFilter == 'info',
            )),
            Obx(() => _buildFilterChip(
              'inventory',
              'Inventario',
              Icons.inventory,
              controller.selectedFilter == 'inventory',
            )),
            Obx(() => _buildFilterChip(
              'new_product',
              'Nuevos',
              Icons.new_releases,
              controller.selectedFilter == 'new_product',
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, bool isSelected) {
    final count = _getCountForFilter(value);

    return FilterChip(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          if (value != 'all' && count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        controller.setFilter(value);
      },
    );
  }

  int _getCountForFilter(String filter) {
    if (filter == 'all') {
      return controller.pendingTasks.length + controller.pendingTemporaryProducts.length;
    }

    if (filter == 'new_product') {
      return controller.pendingTemporaryProducts.length;
    }

    try {
      final changeType = ChangeType.fromString(filter);
      return controller.getPendingCountByType(changeType);
    } catch (e) {
      return 0;
    }
  }
}