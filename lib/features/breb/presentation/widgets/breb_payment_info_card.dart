// lib/features/breb/presentation/widgets/breb_payment_info_card.dart

import 'package:flutter/material.dart';

import '../../../../app/core/utils/number_formatter.dart';
import '../../domain/breb_payment_info.dart';

/// Gris neutro legible tanto en tema claro como oscuro.
const _kMuted = Color(0xFF8A8F98);


/// Recuadro con los datos del pago Bre-B de una venta/factura: el cliente
/// que pagó (según el banco), banco, llave, referencia y lo que llegó.
class BrebPaymentInfoCard extends StatelessWidget {
  final BrebPaymentInfo info;
  final double saleTotal;
  const BrebPaymentInfoCard({super.key, required this.info, required this.saleTotal});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF32AF60);
    final received = info.amountReceived;
    final rows = <(IconData, String)>[
      if (info.payerName?.isNotEmpty == true) (Icons.person_outline, 'Pagó: ${info.payerName}'),
      if (info.originLabel.isNotEmpty) (Icons.account_balance_outlined, info.originLabel),
      if (info.reference?.isNotEmpty == true) (Icons.tag, 'Ref: ${info.reference}'),
      if (received != null && (received - saleTotal).abs() > 0.009)
        (Icons.savings_outlined,
            'Llegó al banco ${NumberFormatter.formatCurrency(received)} (ajuste por monto único)'),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: green.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.bolt, size: 16, color: green),
            SizedBox(width: 4),
            Text('Pago Bre-B confirmado por el banco', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(r.$1, size: 14, color: _kMuted),
                const SizedBox(width: 6),
                Expanded(child: Text(r.$2, style: const TextStyle(fontSize: 12))),
              ]),
            ),
        ],
      ),
    );
  }
}
