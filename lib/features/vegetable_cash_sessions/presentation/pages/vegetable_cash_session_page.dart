// lib/features/vegetable_cash_sessions/presentation/pages/vegetable_cash_session_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../domain/entities/vegetable_cash_session.dart';
import '../controllers/vegetable_cash_sessions_controller.dart';

/// Apertura y cierre de caja del puesto de verduras. El cierre es A CIEGAS:
/// el cajero solo cuenta el efectivo y escribe el total — no ve cuánto
/// "debería" haber ni la diferencia (así no pierde tiempo contando la plata
/// a cada rato durante el turno). El cuadre completo (esperado, faltante/
/// sobrante, desglose, Bre-B por llave) se abre con la contraseña de
/// Adalberto en el detalle de cada turno.
///
/// La misma pantalla sirve para cada caja ([register]): verduras o
/// facturación, cada una con su propio turno e historial.
class VegetableCashSessionPage extends StatefulWidget {
  const VegetableCashSessionPage({super.key, this.register = CashRegister.verduras});

  final CashRegister register;

  @override
  State<VegetableCashSessionPage> createState() => _VegetableCashSessionPageState();
}

class _VegetableCashSessionPageState extends State<VegetableCashSessionPage> {
  late final VegetableCashSessionsController controller;

  @override
  void initState() {
    super.initState();
    controller = VegetableCashSessionsController.forRegister(widget.register);

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
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceInputFormatter()],
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
                          if (amountController.text.trim().isEmpty) {
                            setDialogState(() => errorText = 'Ingresa un monto válido');
                            return;
                          }
                          final amount = PriceFormatter.parse(amountController.text.trim());
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

  /// Abre el cuadre del turno (pide la contraseña de Adalberto ahí mismo).
  void _openReport(String sessionId) =>
      Get.toNamed(AppRoutes.vegetableCashSessionDetail, arguments: sessionId);

  /// Confirmación después de cerrar a ciegas: solo lo que el cajero contó.
  Future<void> _showClosedReceipt(double counted) => Get.dialog<void>(
        Builder(builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Caja cerrada'),
          content: Text(
            'Registraste ${NumberFormatter.formatCurrency(counted)} en efectivo.\n\n'
            'El cuadre (si sobró o faltó) lo revisa el administrador.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(), child: const Text('Listo')),
          ],
        )),
      );

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.visibility_off_outlined, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cierre a ciegas: cuenta TODO el efectivo del cajón (billetes y monedas) y escribe el total.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Efectivo contado',
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
                          if (amountController.text.trim().isEmpty) {
                            setDialogState(() => errorText = 'Ingresa un monto válido');
                            return;
                          }
                          final amount = PriceFormatter.parse(amountController.text.trim());
                          final ok = await controller.closeSession(
                            closingAmount: amount,
                            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                          );
                          if (ok && context.mounted) {
                            Navigator.of(context, rootNavigator: true).pop();
                            controller.loadHistory();
                            await _showClosedReceipt(amount);
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
      appBar: AppBar(title: Text(widget.register.title), elevation: 0),
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
            Text('Abre la caja para empezar a ${widget.register.sellVerb} con control de efectivo', style: Get.textTheme.bodySmall, textAlign: TextAlign.center),
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
    final isStale = summary.isStale;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        side: isStale ? const BorderSide(color: Colors.orange, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isStale ? Icons.warning_amber_rounded : Icons.lock_open, color: isStale ? Colors.orange : Colors.green),
                const SizedBox(width: 8),
                Text(isStale ? 'Caja sin cerrar de un día anterior' : 'Caja abierta', style: Get.textTheme.titleMedium),
              ],
            ),
            Text('Desde ${session.formattedOpenedAt} · ${session.openedBy}', style: Get.textTheme.bodySmall),
            if (isStale) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Esta caja quedó abierta de un día anterior. No se puede ${widget.register.sellVerb} hasta que la cierres y abras una caja nueva para hoy.',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
            const Divider(height: AppConfig.paddingLarge),
            _totalsRow('Fondo inicial', session.openingAmount),
            const SizedBox(height: 8),
            Text(
              'Cierre a ciegas: no necesitas contar la plata durante el día. Al final del turno cuentas el '
              'efectivo una sola vez y lo registras.',
              style: Get.textTheme.bodySmall,
            ),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _openReport(session.id),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Ver cuadre en vivo (clave de Adalberto)'),
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
    // A ciegas: el historial no muestra faltantes/sobrantes. Se ven al abrir
    // el turno con la contraseña de Adalberto.
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: ListTile(
        onTap: () => _openReport(session.id),
        leading: CircleAvatar(
          backgroundColor: (session.isOpen ? Colors.green : Get.theme.colorScheme.primary).withValues(alpha: 0.1),
          child: Icon(session.isOpen ? Icons.lock_open : Icons.lock_outline,
              color: session.isOpen ? Colors.green : Get.theme.colorScheme.primary),
        ),
        title: Text(session.formattedOpenedAt, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          session.isOpen
              ? 'Abierta por ${session.openedBy}'
              : 'Cerrada por ${session.closedBy} · ${session.formattedClosedAt}',
        ),
        trailing: session.isOpen
            ? const Text('En curso', style: TextStyle(fontStyle: FontStyle.italic))
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver cuadre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.admin_panel_settings_outlined, size: 16),
                ],
              ),
      ),
    );
  }
}
