// lib/app/shared/widgets/free_sale_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../core/utils/price_input_formatter.dart';

/// Lo que el cajero escribió en "Venta libre".
class FreeSaleInput {
  final String description;
  final double amount;
  const FreeSaleInput(this.description, this.amount);
}

/// Diálogo de "Venta libre": algo puntual que no está en el catálogo, con
/// descripción y monto a mano. Lo comparten Vender Verduras y Nueva Factura
/// (mismo diálogo, mismo comportamiento). Devuelve null si se cancela.
Future<FreeSaleInput?> showFreeSaleDialog() {
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  String? descriptionError;
  String? amountError;

  return Get.dialog<FreeSaleInput>(
    StatefulBuilder(
      builder: (context, setDialogState) {
        void submit() {
          final description = descriptionController.text.trim();
          final amount = PriceFormatter.parse(amountController.text.trim());
          setDialogState(() {
            descriptionError = description.isEmpty ? 'Ingresa una descripción' : null;
            amountError = amount <= 0 ? 'Ingresa un monto mayor a 0' : null;
          });
          if (descriptionError != null || amountError != null) return;
          Navigator.of(context, rootNavigator: true).pop(FreeSaleInput(description, amount));
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Venta libre'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Para vender algo puntual que no está en el catálogo.', style: Get.textTheme.bodySmall),
              const SizedBox(height: AppConfig.paddingMedium),
              TextField(
                controller: descriptionController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: bolsa de hielo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  errorText: descriptionError,
                ),
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [PriceInputFormatter()],
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  errorText: amountError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(onPressed: submit, child: const Text('Agregar')),
          ],
        );
      },
    ),
  );
}
