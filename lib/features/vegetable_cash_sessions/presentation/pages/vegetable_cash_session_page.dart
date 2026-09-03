// lib/features/vegetable_cash_sessions/presentation/pages/vegetable_cash_session_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../domain/entities/vegetable_cash_session.dart';
import '../../domain/usecases/vegetable_cash_sessions_usecases.dart';
import '../controllers/vegetable_cash_sessions_controller.dart';

/// Apertura y cierre de caja del puesto de verduras: fondo inicial al
/// abrir, conteo físico al cerrar comparado contra lo esperado (fondo +
/// ventas en efectivo - gastos pagados de la caja), más el historial de
/// turnos anteriores.
class VegetableCashSessionPage extends StatefulWidget {
  const VegetableCashSessionPage({super.key});

  @override
  State<VegetableCashSessionPage> createState() => _VegetableCashSessionPageState();
}

class _VegetableCashSessionPageState extends State<VegetableCashSessionPage> {
  late final VegetableCashSessionsController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<VegetableCashSessionsController>()) {
      controller = Get.find<VegetableCashSessionsController>();
    } else {
      controller = Get.put(
        VegetableCashSessionsController(
          openCashSessionUseCase: getIt<OpenCashSessionUseCase>(),
          closeCashSessionUseCase: getIt<CloseCashSessionUseCase>(),
          getCurrentCashSessionUseCase: getIt<GetCurrentCashSessionUseCase>(),
          getCashSessionsHistoryUseCase: getIt<GetCashSessionsHistoryUseCase>(),
          getCashSessionByIdUseCase: getIt<GetCashSessionByIdUseCase>(),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadCurrent();
      controller.loadHistory();
    });
  }

  Future<void> _openSessionDialog() async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String? errorText;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Abrir Caja'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Fondo inicial en efectivo',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Nota (opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cancelar'),
              ),
              Obx(() {
                return ElevatedButton(
                  onPressed: controller.isOpeningOrClosing.value
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));
                          if (amount == null || amount < 0) {
                            setDialogState(() => errorText = 'Ingresa un monto válido');
                            return;
                          }
                          final ok = await controller.openSession(
                            openingAmount: amount,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );
                          if (ok && context.mounted) Navigator.of(context, rootNavigator: true).pop();
                        },
                  child: controller.isOpeningOrClosing.value
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Abrir Caja'),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _closeSessionDialog(VegetableCashSessionSummary summary) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String? errorText;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Cerrar Caja'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debería haber en caja: ${NumberFormatter.formatCurrency(summary.expectedAmount)}',
                  style: Get.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Conteo físico real',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Nota (opcional, ej. explicar una diferencia)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cancelar'),
              ),
              Obx(() {
                return ElevatedButton(
                  onPressed: controller.isOpeningOrClosing.value
                      ? null
                      : () async {
                          final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));
                          if (amount == null || amount < 0) {
                            setDialogState(() => errorText = 'Ingresa un monto válido');
                            return;
                          }
                          final ok = await controller.closeSession(
                            closingAmount: amount,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );
                          if (ok && context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                            controller.loadHistory();
                          }
                        },
                  child: controller.isOpeningOrClosing.value
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Cerrar Caja'),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caja'), elevation: 0),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingCurrent.value && controller.current.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = controller.current.value;

          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadCurrent();
              await controller.loadHistory();
            },
            child: ListView(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              children: [
                if (summary == null || !summary.isOpen) _buildClosedCard() else _buildOpenCard(summary),
                const SizedBox(height: AppConfig.paddingLarge),
                Text('Historial de turnos', style: Get.textTheme.titleSmall),
                const SizedBox(height: 8),
                if (controller.isLoadingHistory.value && controller.history.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (controller.history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Aún no hay turnos registrados', style: Get.textTheme.bodySmall),
                  )
                else
                  ...controller.history.map(_buildHistoryTile),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildClosedCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 40, color: Get.theme.disabledColor),
            const SizedBox(height: 8),
            Text('Caja cerrada', style: Get.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Abre la caja para empezar a vender con control de efectivo', style: Get.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppConfig.paddingMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openSessionDialog,
                icon: const Icon(Icons.lock_open),
                label: const Text('Abrir Caja'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenCard(VegetableCashSessionSummary summary) {
    final session = summary.session!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_open, color: Colors.green),
                const SizedBox(width: 8),
                Text('Caja abierta', style: Get.textTheme.titleMedium),
              ],
            ),
            Text('Desde ${session.formattedOpenedAt} · ${session.openedBy}', style: Get.textTheme.bodySmall),
            const Divider(height: AppConfig.paddingLarge),
            _totalsRow('Fondo inicial', session.openingAmount),
            _totalsRow('+ Ventas en efectivo', summary.cashSales),
            _totalsRow('- Gastos de caja', summary.cashExpenses),
            const Divider(),
            _totalsRow('Debería haber en caja', summary.expectedAmount, isBold: true),
            const SizedBox(height: AppConfig.paddingMedium),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _closeSessionDialog(summary),
                icon: const Icon(Icons.lock_outline),
                label: const Text('Cerrar Caja'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsRow(String label, double amount, {bool isBold = false}) {
    final style = TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(NumberFormatter.formatCurrency(amount), style: style),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(VegetableCashSession session) {
    final isClosed = !session.isOpen;
    Color? diffColor;
    String? diffLabel;
    if (isClosed && session.difference != null) {
      if (session.difference == 0) {
        diffColor = Colors.green;
        diffLabel = 'Cuadrada';
      } else if (session.isSurplus) {
        diffColor = Colors.blue;
        diffLabel = 'Sobrante ${NumberFormatter.formatCurrency(session.difference)}';
      } else {
        diffColor = Get.theme.colorScheme.error;
        diffLabel = 'Faltante ${NumberFormatter.formatCurrency(session.difference!.abs())}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (session.isOpen ? Colors.green : Get.theme.colorScheme.primary).withValues(alpha: 0.1),
          child: Icon(session.isOpen ? Icons.lock_open : Icons.lock_outline, color: session.isOpen ? Colors.green : Get.theme.colorScheme.primary),
        ),
        title: Text(session.formattedOpenedAt, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          session.isOpen
              ? 'Abierta por ${session.openedBy}'
              : 'Cerrada por ${session.closedBy} · ${session.formattedClosedAt}',
        ),
        trailing: session.isOpen
            ? const Text('En curso', style: TextStyle(fontStyle: FontStyle.italic))
            : Text(diffLabel ?? '', style: TextStyle(color: diffColor, fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}
