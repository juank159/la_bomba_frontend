// lib/features/invoices/presentation/utils/invoice_print_helper.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../app/config/routes.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/services/preferences_service.dart';
import '../../data/services/printer_service.dart';
import '../../domain/entities/invoice.dart';

/// Imprime [invoice] con la impresora térmica configurada globalmente
/// (Administración > Impresora Térmica), redirigiendo a configurarla si
/// hace falta. Compartido por CreateInvoicePage ("Cobrar e Imprimir") e
/// InvoiceDetailPage ("Imprimir recibo") para que el comportamiento sea
/// idéntico sin importar desde dónde se imprima.
Future<void> printInvoiceWithFallback(BuildContext context, Invoice invoice) async {
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La impresión no está disponible en la versión web. Usa la app móvil o de escritorio.'),
      ),
    );
    return;
  }

  final preferencesService = getIt<PreferencesService>();
  var destination = preferencesService.getPrinterDestination();
  if (destination == null) {
    final configured = await Navigator.of(context).pushNamed(AppRoutes.printerSettings);
    if (configured == null || !context.mounted) return;
    destination = preferencesService.getPrinterDestination();
  }
  if (destination == null) return;

  final printerService = getIt<PrinterService>();
  try {
    await printerService.printInvoice(invoice, destination: destination);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recibo enviado a la impresora')),
    );
  } on PrinterException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}
