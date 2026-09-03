// lib/features/vegetable_cash_sessions/presentation/pages/vegetable_cash_session_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../domain/entities/vegetable_cash_session.dart';
import '../../domain/usecases/vegetable_cash_sessions_usecases.dart';
import '../controllers/vegetable_cash_sessions_controller.dart';

/// Trazabilidad completa de un turno de caja: el resumen del cierre (o el
/// estado si sigue abierto) y el desglose de cuánto entró por cada método
/// de pago (efectivo, Nequi, Bancolombia, ...), filtrable por tipo.
class VegetableCashSessionDetailPage extends StatefulWidget {
  final String sessionId;
  const VegetableCashSessionDetailPage({super.key, required this.sessionId});

  @override
  State<VegetableCashSessionDetailPage> createState() => _VegetableCashSessionDetailPageState();
}

class _VegetableCashSessionDetailPageState extends State<VegetableCashSessionDetailPage> {
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
          getCashSessionBreakdownUseCase: getIt<GetCashSessionBreakdownUseCase>(),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadSessionById(widget.sessionId);
      controller.loadBreakdown(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Turno'), elevation: 0),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingSessionDetail.value && controller.selectedSession.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = controller.selectedSession.value;
          if (session == null) {
            return const Center(child: Text('No se encontró el turno'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(session),
                const SizedBox(height: AppConfig.paddingLarge),
                Text('Trazabilidad por método de pago', style: Get.textTheme.titleSmall),
                const SizedBox(height: 8),
                _buildFilterChips(),
                const SizedBox(height: AppConfig.paddingMedium),
                if (controller.isLoadingBreakdown.value)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (controller.filteredBreakdown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Sin movimientos en este período', style: Get.textTheme.bodySmall),
                  )
                else ...[
                  ...controller.filteredBreakdown.map(_buildBreakdownTile),
                  const Divider(height: AppConfig.paddingLarge),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        NumberFormatter.formatCurrency(controller.filteredBreakdownTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard(VegetableCashSession session) {
    Color? diffColor;
    String? diffLabel;
    if (!session.isOpen && session.difference != null) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abierta: ${session.formattedOpenedAt} · ${session.openedBy}', style: Get.textTheme.bodySmall),
            if (!session.isOpen)
              Text('Cerrada: ${session.formattedClosedAt} · ${session.closedBy}', style: Get.textTheme.bodySmall),
            const Divider(),
            _row('Fondo inicial', NumberFormatter.formatCurrency(session.openingAmount)),
            if (!session.isOpen) ...[
              _row('Esperado (efectivo)', NumberFormatter.formatCurrency(session.expectedAmount ?? 0)),
              _row('Contado', NumberFormatter.formatCurrency(session.closingAmount ?? 0)),
              if (diffLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(diffLabel, style: TextStyle(color: diffColor, fontWeight: FontWeight.w700)),
                ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Turno en curso', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Nota: ${session.notes}', style: Get.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      children: ['Todos', 'Efectivo', 'Transferencias'].map((option) {
        return ChoiceChip(
          label: Text(option),
          selected: controller.breakdownFilter.value == option,
          onSelected: (_) => controller.breakdownFilter.value = option,
        );
      }).toList(),
    );
  }

  Widget _buildBreakdownTile(CashSessionPaymentBreakdown breakdown) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: ListTile(
        leading: Icon(
          breakdown.isCash ? Icons.payments_outlined : Icons.account_balance_outlined,
          color: breakdown.isCash ? Colors.green : Get.theme.colorScheme.primary,
        ),
        title: Text(breakdown.paymentMethodName),
        subtitle: Text('${breakdown.count} venta(s)'),
        trailing: Text(
          NumberFormatter.formatCurrency(breakdown.total),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
