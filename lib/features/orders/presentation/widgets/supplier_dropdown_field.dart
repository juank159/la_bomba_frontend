import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../suppliers/domain/entities/supplier.dart';

/// Optimized supplier dropdown field with caching
class SupplierDropdownField extends StatefulWidget {
  final String? value;
  final List<Supplier> suppliers;
  final ValueChanged<String?>? onChanged;
  final bool isRequired;
  final bool isDense;
  final String? labelText;
  final String? hintText;

  const SupplierDropdownField({
    super.key,
    this.value,
    required this.suppliers,
    this.onChanged,
    this.isRequired = false,
    this.isDense = true,
    this.labelText,
    this.hintText,
  });

  @override
  State<SupplierDropdownField> createState() => _SupplierDropdownFieldState();
}

class _SupplierDropdownFieldState extends State<SupplierDropdownField> {
  // Cache dropdown items to avoid rebuilding on every frame
  List<DropdownMenuItem<String>>? _cachedItems;
  int? _lastSupplierCount;

  @override
  void didUpdateWidget(SupplierDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Invalidate cache if suppliers list changed
    if (oldWidget.suppliers.length != widget.suppliers.length) {
      _cachedItems = null;
    }
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    // Return cached items if available and suppliers haven't changed
    if (_cachedItems != null && _lastSupplierCount == widget.suppliers.length) {
      return _cachedItems!;
    }

    // Build and cache items
    final items = widget.suppliers.map((supplier) {
      return DropdownMenuItem<String>(
        value: supplier.id,
        child: Text(
          supplier.nombre,
          style: TextStyle(
            fontSize: widget.isDense ? AppConfig.smallFontSize : AppConfig.bodyFontSize,
          ),
        ),
      );
    }).toList();

    _cachedItems = items;
    _lastSupplierCount = widget.suppliers.length;

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.isRequired && widget.value == null;

    return DropdownButtonFormField<String>(
      value: widget.value,
      isDense: widget.isDense,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Proveedor${widget.isRequired ? ' *' : ''}',
        labelStyle: TextStyle(
          fontSize: widget.isDense ? AppConfig.smallFontSize - 1 : AppConfig.bodyFontSize,
          color: hasError ? Get.theme.colorScheme.error : null,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: widget.isDense ? AppConfig.paddingSmall : AppConfig.paddingMedium,
          vertical: widget.isDense ? 2 : AppConfig.paddingSmall,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isDense ? AppConfig.borderRadius / 2 : AppConfig.borderRadius),
          borderSide: hasError
              ? BorderSide(color: Get.theme.colorScheme.error, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isDense ? AppConfig.borderRadius / 2 : AppConfig.borderRadius),
          borderSide: hasError
              ? BorderSide(color: Get.theme.colorScheme.error, width: 1.5)
              : BorderSide(color: Get.theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.isDense ? AppConfig.borderRadius / 2 : AppConfig.borderRadius),
          borderSide: BorderSide(
            color: hasError
                ? Get.theme.colorScheme.error
                : Get.theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: hasError
            ? Get.theme.colorScheme.error.withOpacity(0.05)
            : Get.theme.colorScheme.surface,
        helperText: hasError ? 'Requerido' : null,
        helperStyle: TextStyle(
          fontSize: AppConfig.smallFontSize - 2,
          color: Get.theme.colorScheme.error,
        ),
      ),
      style: TextStyle(
        fontSize: widget.isDense ? AppConfig.smallFontSize : AppConfig.bodyFontSize,
        color: Get.theme.colorScheme.onSurface,
      ),
      hint: Text(
        widget.hintText ?? 'Seleccione un proveedor...',
        style: TextStyle(
          fontSize: widget.isDense ? AppConfig.smallFontSize : AppConfig.bodyFontSize,
          color: hasError
              ? Get.theme.colorScheme.error.withOpacity(0.7)
              : Get.theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      items: _buildDropdownItems(),
      onChanged: widget.onChanged,
      isExpanded: true,
      // Performance optimization: reduce menu max height
      menuMaxHeight: 300,
    );
  }
}
