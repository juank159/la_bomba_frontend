// lib/features/breb/presentation/pages/breb_history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/core/utils/number_formatter.dart';
import '../../data/breb_api.dart';

/// Gris neutro legible tanto en tema claro como oscuro.
const _kMuted = Color(0xFF8A8F98);


/// Historial de cobros Bre-B (solo admin): a qué hora, de qué caja, cuánto,
/// quién pagó, por qué banco/llave entró, qué venta/factura generó y qué
/// cajero lo cobró. Sirve para cuadrar contra el extracto del banco.
class BrebHistoryPage extends StatefulWidget {
  const BrebHistoryPage({super.key});

  @override
  State<BrebHistoryPage> createState() => _BrebHistoryPageState();
}

enum _Range { hoy, ayer, semana, mes }

class _BrebHistoryPageState extends State<BrebHistoryPage> {
  final _api = BrebApi();
  _Range _range = _Range.hoy;
  String? _module; // null = todos
  bool _onlyPaid = true;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  (DateTime, DateTime) _bounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_range) {
      case _Range.hoy:
        return (today, today.add(const Duration(days: 1)));
      case _Range.ayer:
        return (today.subtract(const Duration(days: 1)), today);
      case _Range.semana:
        return (today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1)));
      case _Range.mes:
        return (today.subtract(const Duration(days: 29)), today.add(const Duration(days: 1)));
    }
  }

  Future<List<Map<String, dynamic>>> _load() {
    final (from, to) = _bounds();
    return _api.charges(from: from, to: to, module: _module);
  }

  void _reload() => setState(() => _future = _load());

  double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Bre-B'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final r in _Range.values)
                  ChoiceChip(
                    label: Text(const {
                      _Range.hoy: 'Hoy',
                      _Range.ayer: 'Ayer',
                      _Range.semana: '7 días',
                      _Range.mes: '30 días',
                    }[r]!),
                    selected: _range == r,
                    onSelected: (_) {
                      _range = r;
                      _reload();
                    },
                  ),
                const SizedBox(width: 8),
                for (final m in const [null, 'vegetables', 'invoices'])
                  ChoiceChip(
                    label: Text(m == null ? 'Todo' : (m == 'vegetables' ? 'Verduras' : 'Facturación')),
                    selected: _module == m,
                    onSelected: (_) {
                      _module = m;
                      _reload();
                    },
                  ),
                FilterChip(
                  label: const Text('Solo pagados'),
                  selected: _onlyPaid,
                  onSelected: (v) => setState(() => _onlyPaid = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text(BrebApi.errorMessage(snap.error!)));
                final all = snap.data ?? const [];
                final rows = _onlyPaid ? all.where((c) => c['status'] == 'matched').toList() : all;
                final paid = all.where((c) => c['status'] == 'matched');
                final total = paid.fold<double>(0, (s, c) => s + _d(c['receivedAmount'] ?? c['amount']));
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.bolt, color: Color(0xFF32AF60)),
                        title: Text(NumberFormatter.formatCurrency(total),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        subtitle: Text('${paid.length} pagos Bre-B confirmados en el periodo'),
                      ),
                    ),
                    if (rows.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No hay cobros Bre-B en este periodo.')),
                      ),
                    for (final c in rows) _ChargeTile(charge: c),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargeTile extends StatelessWidget {
  final Map<String, dynamic> charge;
  const _ChargeTile({required this.charge});

  @override
  Widget build(BuildContext context) {
    final status = charge['status'] as String? ?? '';
    final (label, color) = switch (status) {
      'matched' => ('Pagado', Colors.green),
      'pending' || 'matching' => ('Esperando', Colors.orange),
      'expired' => ('Expiró', Colors.grey),
      'cancelled' => ('Cancelado', Colors.grey),
      _ => (status, Colors.grey),
    };
    final isVeg = charge['module'] == 'vegetables';
    final created = DateTime.tryParse(charge['createdAt'] as String? ?? '')?.toLocal();
    final confirmed = DateTime.tryParse(charge['confirmedAt'] as String? ?? '')?.toLocal();
    final when = confirmed ?? created;
    final amount = double.tryParse('${charge['receivedAmount'] ?? charge['amount']}') ?? 0;
    final saleNumber = charge['saleNumber'];
    final details = <String>[
      if (when != null) DateFormat('d/M h:mm a').format(when),
      if ((charge['payerName'] as String?)?.isNotEmpty == true) charge['payerName'] as String,
      if ((charge['bankLabel'] as String?)?.isNotEmpty == true) charge['bankLabel'] as String,
      if ((charge['matchedLlave'] as String?)?.isNotEmpty == true) 'llave ${charge['matchedLlave']}',
      if (charge['restPaymentMethodId'] != null && charge['saleTotal'] != null)
        'mixto: cuenta de ${NumberFormatter.formatCurrency(double.tryParse('${charge['saleTotal']}') ?? 0)}',
      if (charge['confirmedVia'] == 'manual') 'asignado a mano',
      'cajero ${charge['initiatedByUsername'] ?? ''}',
    ];
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(isVeg ? Icons.eco_outlined : Icons.receipt_long_outlined, color: color),
        ),
        title: Row(
          children: [
            Text(NumberFormatter.formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            if (saleNumber != null)
              Text('${isVeg ? 'Venta' : 'Factura'} #${saleNumber.toString().padLeft(6, '0')}',
                  style: const TextStyle(fontSize: 12, color: _kMuted)),
          ],
        ),
        subtitle: Text(details.join(' · ')),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ),
    );
  }
}
