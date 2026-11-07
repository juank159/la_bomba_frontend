// lib/app/shared/utils/thermal_print_flow.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/preferences_service.dart';
import '../../core/services/printer_destination.dart';

/// Flujo único para imprimir en la impresora térmica configurada
/// (Administración > Impresora Térmica): en web avisa que no se puede, si
/// no hay impresora lleva a configurarla, y muestra si salió o el error.
/// Lo usan las facturas y el cierre de caja; [send] solo arma y manda.
Future<bool> printWithThermalPrinter(
  BuildContext context,
  Future<void> Function(PrinterDestination destination) send, {
  String successMessage = 'Recibo enviado a la impresora',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (kIsWeb) {
    messenger.showSnackBar(const SnackBar(
      content: Text('La impresión no está disponible en la versión web. Usa la app móvil o de escritorio.'),
    ));
    return false;
  }

  final preferencesService = getIt<PreferencesService>();
  var destination = preferencesService.getPrinterDestination();
  if (destination == null) {
    final configured = await Navigator.of(context).pushNamed(AppRoutes.printerSettings);
    if (configured == null || !context.mounted) return false;
    destination = preferencesService.getPrinterDestination();
  }
  if (destination == null) return false;

  try {
    await send(destination);
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    return true;
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    return false;
  }
}
