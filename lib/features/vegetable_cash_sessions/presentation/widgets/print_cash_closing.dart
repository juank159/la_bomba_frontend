// lib/features/vegetable_cash_sessions/presentation/widgets/print_cash_closing.dart

import 'package:flutter/material.dart';

import '../../../../app/shared/utils/thermal_print_flow.dart';
import '../../data/cash_session_receipt.dart';
import '../../data/cash_session_report_api.dart';

/// Imprime el recibo de cierre del turno [sessionId] (solo cajas cerradas).
/// Si ya se tiene el reporte (pantalla de cuadre), se pasa en [report] y no
/// se vuelve a pedir. Lo usan el aviso de "Caja cerrada", el historial y
/// el cuadre.
Future<void> printCashClosing(BuildContext context, String sessionId, {Map<String, dynamic>? report}) async {
  var data = report;
  if (data == null) {
    final r = await CashSessionReportApi().fetchReceipt(sessionId);
    if (!context.mounted) return;
    if (r.report == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error ?? 'No se pudo cargar el cierre')));
      return;
    }
    data = r.report!;
  }
  await printWithThermalPrinter(
    context,
    (destination) => CashSessionReceipt.print(data!, destination),
    successMessage: 'Cierre de caja enviado a la impresora',
  );
}
