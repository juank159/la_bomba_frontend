//lib frontend/lib/features/orders/presentation/widgets/order_item_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../domain/entities/order_item.dart';
import '../../../suppliers/domain/entities/supplier.dart';

/// Order item card widget for displaying order item information
class OrderItemCard extends StatefulWidget {
  final OrderItem item;
  final Function(int existingQty, int? requestedQty)? onQuantityChanged;
  final Function(MeasurementUnit unit)? onMeasurementUnitChanged;
  final Function(String? supplierId)? onSupplierChanged;
  final List<Supplier>? suppliers;
  final VoidCallback? onRemove;
  final bool showRemoveButton;
  final bool showQuantityControls;
  final bool isReadOnly;
  final bool isEditingOrder;
  final bool canEditRequestedQuantity;
  final bool startCollapsed;
  final bool showRequestedQuantities;
  final bool showSupplierSelector;

  const OrderItemCard({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.onMeasurementUnitChanged,
    this.onSupplierChanged,
    this.suppliers,
    this.onRemove,
    this.showRemoveButton = false,
    this.showQuantityControls = false,
    this.isReadOnly = false,
    this.isEditingOrder = false,
    this.canEditRequestedQuantity = false,
    this.startCollapsed = false,
    this.showRequestedQuantities = true,
    this.showSupplierSelector = false,
  });

  @override
  State<OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<OrderItemCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.startCollapsed;
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.startCollapsed ? _toggleExpansion : null,
        child: Padding(
          padding: const EdgeInsets.all(AppConfig.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact Product Header
              Row(
                children: [
                  // Smaller Product Icon
                  Container(
                    padding: const EdgeInsets.all(AppConfig.paddingSmall / 2),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      size: 14,
                      color: Get.theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppConfig.paddingSmall),

                  // Compact Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.productDescription,
                          style: TextStyle(
                            fontSize: AppConfig.smallFontSize,
                            fontWeight: FontWeight.w600,
                            color: Get.theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!widget.startCollapsed || _isExpanded) ...[
                          if (widget.item.productBarcode != 'N/A') ...[
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 10,
                                  color: Get.theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.item.productBarcode,
                                  style: TextStyle(
                                    fontSize: AppConfig.smallFontSize - 1,
                                    color: Get.theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  // Expand/Collapse button (if collapsible)
                  if (widget.startCollapsed) ...[
                    IconButton(
                      onPressed: _toggleExpansion,
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],

                  // Smaller Remove Button
                  if (widget.showRemoveButton && widget.onRemove != null)
                    IconButton(
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Eliminar producto',
                      color: Get.theme.colorScheme.error,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                ],
              ),

              // Expanded content (only show if expanded or not collapsible)
              if (!widget.startCollapsed || _isExpanded) ...[
                const SizedBox(height: AppConfig.paddingSmall),

                // Compact Content Based on State
                if (widget.isEditingOrder) ...[
                  _buildCompactEditableLayout(),
                ] else ...[
                  _buildCompactReadOnlyLayout(),
                ],

                // Compact Quantity Controls (if enabled)
                if (widget.showQuantityControls && !widget.isReadOnly) ...[
                  const SizedBox(height: AppConfig.paddingSmall),
                  const Divider(height: 1),
                  const SizedBox(height: AppConfig.paddingSmall),
                  _buildQuantityControls(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build compact editable layout for order creation
  Widget _buildCompactEditableLayout() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.paddingSmall),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
        border: Border.all(
          color: Get.theme.colorScheme.surfaceVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // Unit selector row
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 12,
                color: Get.theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: DropdownButtonFormField<MeasurementUnit>(
                  value: widget.item.measurementUnit,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingSmall,
                      vertical: 2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
                    ),
                    filled: true,
                    fillColor: Get.theme.colorScheme.surface,
                  ),
                  style: TextStyle(
                    fontSize: AppConfig.smallFontSize,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                  items: MeasurementUnit.values.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(
                        unit.displayName,
                        style: TextStyle(fontSize: AppConfig.smallFontSize),
                      ),
                    );
                  }).toList(),
                  onChanged: widget.onMeasurementUnitChanged != null 
                      ? (MeasurementUnit? newUnit) {
                          if (newUnit != null) {
                            widget.onMeasurementUnitChanged!(newUnit);
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConfig.paddingSmall),
          
          // Quantities row
          Row(
            children: [
              // Existing quantity
              Expanded(
                child: _buildCompactQuantityField(
                  label: 'Existente',
                  value: widget.item.existingQuantity,
                  unit: widget.item.measurementUnit.shortDisplayName,
                  icon: Icons.inventory,
                  color: Get.theme.colorScheme.primary,
                  enabled: true,
                  onChanged: (value) {
                    final newQty = int.tryParse(value) ?? 0;
                    if (newQty >= 0 && widget.onQuantityChanged != null) {
                      widget.onQuantityChanged!(newQty, widget.item.requestedQuantity);
                    }
                  },
                ),
              ),
              // Requested quantity (solo para administradores)
              if (widget.showRequestedQuantities) ...[
                const SizedBox(width: AppConfig.paddingSmall),
                Expanded(
                  child: _buildCompactQuantityField(
                    label: 'Solicitado',
                    value: widget.item.requestedQuantity ?? 0,
                    unit: widget.item.measurementUnit.shortDisplayName,
                    icon: Icons.request_quote,
                    color: Get.theme.colorScheme.secondary,
                    enabled: widget.canEditRequestedQuantity,
                    onChanged: (value) {
                      if (widget.canEditRequestedQuantity) {
                        final newQty = int.tryParse(value);
                        if (widget.onQuantityChanged != null) {
                          widget.onQuantityChanged!(widget.item.existingQuantity, newQty);
                        }
                      }
                    },
                  ),
                ),
              ],
            ],
          ),

          // Supplier selector row (solo para ADMIN en pedidos mixtos)
          if (widget.showSupplierSelector && widget.suppliers != null) ...[
            const SizedBox(height: AppConfig.paddingSmall),
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  size: 12,
                  color: Get.theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: widget.item.supplierId,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Proveedor',
                      labelStyle: TextStyle(fontSize: AppConfig.smallFontSize - 1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConfig.paddingSmall,
                        vertical: 2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
                      ),
                      filled: true,
                      fillColor: Get.theme.colorScheme.surface,
                    ),
                    style: TextStyle(
                      fontSize: AppConfig.smallFontSize,
                      color: Get.theme.colorScheme.onSurface,
                    ),
                    hint: Text(
                      'Sin asignar',
                      style: TextStyle(
                        fontSize: AppConfig.smallFontSize,
                        color: Get.theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    items: [
                      // Opción "Sin asignar"
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Sin asignar'),
                      ),
                      // Lista de proveedores
                      ...widget.suppliers!.map((supplier) {
                        return DropdownMenuItem<String>(
                          value: supplier.id,
                          child: Text(
                            supplier.nombre,
                            style: TextStyle(fontSize: AppConfig.smallFontSize),
                          ),
                        );
                      }),
                    ],
                    onChanged: widget.onSupplierChanged,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build compact quantity input field
  Widget _buildCompactQuantityField({
    required String label,
    required int value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool enabled,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 10,
              color: enabled ? color : Get.theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppConfig.smallFontSize - 1,
                  fontWeight: FontWeight.w500,
                  color: enabled 
                      ? Get.theme.colorScheme.onSurface.withOpacity(0.7)
                      : Get.theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 32,
          child: TextFormField(
            initialValue: value.toString(),
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppConfig.smallFontSize,
              fontWeight: FontWeight.w600,
              color: enabled ? color : Get.theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
              ),
              suffixText: unit,
              suffixStyle: TextStyle(
                fontSize: AppConfig.smallFontSize - 1,
                color: enabled ? color : Get.theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: enabled 
                  ? Get.theme.colorScheme.surface
                  : Get.theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            onChanged: enabled ? onChanged : null,
          ),
        ),
        if (!enabled) ...[
          Text(
            'Solo admin',
            style: TextStyle(
              fontSize: AppConfig.smallFontSize - 2,
              color: Get.theme.colorScheme.onSurface.withOpacity(0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  /// Build compact read-only layout
  Widget _buildCompactReadOnlyLayout() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.paddingSmall),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
      ),
      child: Column(
        children: [
          // Unit display
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 10,
                color: Get.theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                widget.item.measurementUnit.displayName,
                style: TextStyle(
                  fontSize: AppConfig.smallFontSize,
                  color: Get.theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Quantities row
          Row(
            children: [
              Expanded(
                child: _buildCompactQuantityDisplay(
                  label: 'Existente',
                  quantity: widget.item.existingQuantity,
                  unit: widget.item.measurementUnit.shortDisplayName,
                  color: Get.theme.colorScheme.primary,
                ),
              ),
              // Solo mostrar cantidad solicitada a administradores
              if (widget.showRequestedQuantities) ...[
                const SizedBox(width: AppConfig.paddingSmall),
                Expanded(
                  child: _buildCompactQuantityDisplay(
                    label: 'Solicitado',
                    quantity: widget.item.requestedQuantity ?? 0,
                    unit: widget.item.measurementUnit.shortDisplayName,
                    color: Get.theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build compact quantity display
  Widget _buildCompactQuantityDisplay({
    required String label,
    required int quantity,
    required String unit,
    required Color color,
    String prefix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            '$prefix$quantity $unit',
            style: TextStyle(
              fontSize: AppConfig.smallFontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: AppConfig.smallFontSize - 1,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build quantity controls (used only when showQuantityControls is true)
  Widget _buildQuantityControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajustar Cantidades',
          style: TextStyle(
            fontSize: AppConfig.captionFontSize,
            fontWeight: FontWeight.w600,
            color: Get.theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConfig.paddingSmall),
        Row(
          children: [
            // Existing Quantity Controls
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Existente',
                    style: TextStyle(
                      fontSize: AppConfig.smallFontSize,
                      color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () => _updateExistingQuantity(widget.item.existingQuantity - 1),
                        enabled: widget.item.existingQuantity > 0,
                      ),
                      Expanded(
                        child: Text(
                          '${widget.item.existingQuantity}',
                          style: TextStyle(
                            fontSize: AppConfig.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: Get.theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () => _updateExistingQuantity(widget.item.existingQuantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Solo mostrar controles de cantidad solicitada a administradores
            if (widget.showRequestedQuantities) ...[
              const SizedBox(width: AppConfig.paddingMedium),
              // Requested Quantity Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicitado',
                      style: TextStyle(
                        fontSize: AppConfig.smallFontSize,
                        color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onPressed: () => _updateRequestedQuantity((widget.item.requestedQuantity ?? 1) - 1),
                          enabled: (widget.item.requestedQuantity ?? 0) > 0,
                        ),
                        Expanded(
                          child: Text(
                            '${widget.item.requestedQuantity ?? 0}',
                            style: TextStyle(
                              fontSize: AppConfig.bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: Get.theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onPressed: () => _updateRequestedQuantity((widget.item.requestedQuantity ?? 0) + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 16),
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? Get.theme.colorScheme.primaryContainer
              : Get.theme.colorScheme.surfaceVariant,
          foregroundColor: enabled
              ? Get.theme.colorScheme.onPrimaryContainer
              : Get.theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _updateExistingQuantity(int newQuantity) {
    if (newQuantity >= 0 && widget.onQuantityChanged != null) {
      widget.onQuantityChanged!(newQuantity, widget.item.requestedQuantity);
    }
  }

  void _updateRequestedQuantity(int newQuantity) {
    if (newQuantity >= 0 && widget.onQuantityChanged != null) {
      widget.onQuantityChanged!(widget.item.existingQuantity, newQuantity);
    }
  }
}