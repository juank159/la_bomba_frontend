// lib/features/vegetable_cash_sessions/presentation/widgets/cash_session_block_banner.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../domain/entities/vegetable_cash_session.dart';
import '../controllers/vegetable_cash_sessions_controller.dart';

/// Pantalla de apertura/cierre de cada caja.
String cashSessionRouteFor(CashRegister register) => switch (register) {
      CashRegister.verduras => '/vegetables/cash-session',
      CashRegister.facturacion => '/invoices/cash-session',
    };

/// Aviso rojo que bloquea vender (o facturar) sin caja abierta HOY, con el
/// botón para ir a abrirla. Lo usan Vender Verduras y Nueva Factura: cada
/// una mira SU caja. No muestra nada mientras no se sabe el estado.
class CashSessionBlockBanner extends StatelessWidget {
  const CashSessionBlockBanner({super.key, required this.register});

  final CashRegister register;

  @override
  Widget build(BuildContext context) {
    final controller = VegetableCashSessionsController.forRegister(register);
    return Obx(() {
      final message = controller.blockMessage;
      if (message == null) return const SizedBox.shrink();
      final error = Get.theme.colorScheme.error;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(AppConfig.paddingMedium, AppConfig.paddingMedium, AppConfig.paddingMedium, 0),
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: error),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: error, fontWeight: FontWeight.w600))),
            TextButton(
              onPressed: () async {
                await Get.toNamed(cashSessionRouteFor(register));
                controller.loadCurrent();
              },
              child: Text(controller.hasOpenSession ? 'Ir a Caja' : 'Abrir Caja'),
            ),
          ],
        ),
      );
    });
  }
}
