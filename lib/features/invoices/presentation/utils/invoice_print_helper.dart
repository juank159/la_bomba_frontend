// lib/features/invoices/presentation/utils/invoice_print_helper.dart

import 'package:flutter/material.dart';

import '../../../../app/core/di/service_locator.dart';
import '../../../../app/shared/utils/thermal_print_flow.dart';
import '../../data/services/printer_service.dart';
import '../../domain/entities/invoice.dart';

/// Imprime [invoice] con la impresora térmica configurada. Compartido por
/// CreateInvoicePage ("Cobrar e Imprimir") e InvoiceDetailPage ("Imprimir
/// recibo"); el flujo (web, configurar impresora, avisos) es el común.
Future<void> printInvoiceWithFallback(BuildContext context, Invoice invoice) => printWithThermalPrinter(
      context,
      (destination) => getIt<PrinterService>().printInvoice(invoice, destination: destination),
    );
