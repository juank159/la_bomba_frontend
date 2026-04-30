import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/supervisor_controller.dart';
import '../../domain/entities/product_update_task.dart';

class TaskFilterWidget extends StatelessWidget {
  final SupervisorController controller;

  /// Rol al que se está filtrando la pantalla. Determina qué chips mostrar:
  ///   - supervisor → Todas / Precio / Llegada / Nuevos
  ///   - digitador  → Todas / Precio / Nombre / IVA / Código / Nuevos
  ///   - null (admin sin filtro) → todos los chips
  final AssignedRole? roleScope;

  const TaskFilterWidget({
    super.key,
    required this.controller,
    this.roleScope,
  });

  /// Definición de cada chip disponible
  static const _AllFilter = _FilterDef('all', 'Todas', Icons.list);
  static const _PriceFilter = _FilterDef('price', 'Precio', Icons.monetization_on);
  static const _ArrivalFilter = _FilterDef('arrival', 'Llegada', Icons.local_shipping);
  static const _NameFilter = _FilterDef('name', 'Nombre', Icons.badge);
  static const _IvaFilter = _FilterDef('iva', 'IVA', Icons.percent);
  static const _BarcodeFilter = _FilterDef('barcode', 'Código', Icons.qr_code);
  static const _InfoFilter = _FilterDef('info', 'Información', Icons.info);
  static const _InventoryFilter = _FilterDef('inventory', 'Inventario', Icons.inventory);
  static const _NewFilter = _FilterDef('new_product', 'Nuevos', Icons.new_releases);

  /// Lista de chips a mostrar según el rol al que aplica la pantalla
  List<_FilterDef> get _filtersForScope {
    switch (roleScope) {
      case AssignedRole.supervisor:
        // Supervisor: precio, llegada, productos nuevos
        return const [_AllFilter, _PriceFilter, _ArrivalFilter, _NewFilter];
      case AssignedRole.digitador:
        // Digitador: precio, nombre, iva, código, productos nuevos
        return const [
          _AllFilter,
          _PriceFilter,
          _NameFilter,
          _IvaFilter,
          _BarcodeFilter,
          _NewFilter,
        ];
      case null:
      default:
        // Admin sin filtro: todos los tipos
        return const [
          _AllFilter,
          _PriceFilter,
          _NameFilter,
          _IvaFilter,
          _BarcodeFilter,
          _InfoFilter,
          _ArrivalFilter,
          _InventoryFilter,
          _NewFilter,
        ];
    }
  }

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

        // Filter chips: solo los que aplican al rol actual
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filtersForScope
              .map((f) => Obx(() => _buildFilterChip(
                    f.value,
                    f.label,
                    f.icon,
                    controller.selectedFilter == f.value,
                  )))
              .toList(),
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

/// Definición inmutable de un chip de filtro: valor interno, label visible e icono.
class _FilterDef {
  final String value;
  final String label;
  final IconData icon;
  const _FilterDef(this.value, this.label, this.icon);
}