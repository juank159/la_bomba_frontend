// lib/features/vegetable_cash_sessions/data/cash_session_receipt.dart

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../../../app/core/di/service_locator.dart';
import '../../../app/core/services/printer_destination.dart';
import '../../../app/core/services/receipt_template.dart';
import '../../../app/core/services/thermal_printer_sender.dart';
import '../../../app/core/utils/number_formatter.dart';

/// La impresora solo entiende Latin-1: un emoji o una raya larga en una
/// nota o un nombre haría fallar todo el recibo, así que se reemplazan.
String _safe(Object? v) => String.fromCharCodes(
    (v ?? '-').toString().replaceAll('—', '-').replaceAll('–', '-').runes.map((c) => c <= 0xFF ? c : 0x3F));

double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

List<Map<String, dynamic>> _list(dynamic v) =>
    ((v as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

/// La "venta del turno" sumada: todo lo vendido en esa caja, y cuánto entró
/// en efectivo y cuánto por otros medios (transferencias, Bre-B, tarjeta).
/// Sale del mismo desglose por método del cuadre, así la pantalla y el
/// recibo impreso siempre dicen lo mismo.
class CashSessionSalesSummary {
  final double totalSales;
  final int salesCount;
  final double cashTotal;
  final double otherTotal;

  const CashSessionSalesSummary({
    required this.totalSales,
    required this.salesCount,
    required this.cashTotal,
    required this.otherTotal,
  });

  factory CashSessionSalesSummary.fromReport(Map<String, dynamic> report) {
    var cash = 0.0, other = 0.0;
    for (final m in _list(report['byMethod'])) {
      if (m['isCash'] == true) {
        cash += _d(m['total']);
      } else {
        other += _d(m['total']);
      }
    }
    return CashSessionSalesSummary(
      totalSales: _d(report['totalSales']),
      salesCount: (report['salesCount'] as num?)?.toInt() ?? 0,
      cashTotal: cash,
      otherTotal: other,
    );
  }
}

/// Recibo impreso del cierre de caja (Z): apertura y cierre, venta total
/// del turno, desglose por método, Bre-B por llave, efectivo esperado,
/// contado y si sobró o faltó.
class CashSessionReceipt {
  static Future<void> print(Map<String, dynamic> report, PrinterDestination destination) async {
    final bytes = await build(report);
    await getIt<ThermalPrinterSender>().send(bytes, destination);
  }

  static Future<List<int>> build(Map<String, dynamic> r) async {
    final g = await ReceiptTemplate.newGenerator();
    final session = Map<String, dynamic>.from(r['session'] as Map);
    final register = (r['register'] ?? session['register'])?.toString();
    final caja = register == 'facturacion' ? 'Caja de Facturación' : 'Caja de Verduras';
    final summary = CashSessionSalesSummary.fromReport(r);
    String money(dynamic v) => NumberFormatter.formatCurrency(_d(v));
    String date(dynamic v) {
      final d = v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
      return d == null ? '-' : DateFormat('d/M/y h:mm a').format(d);
    }

    List<int> row(String label, String value, {bool bold = false, bool big = false}) => g.row([
          PosColumn(text: label, width: 7, styles: PosStyles(bold: bold, height: big ? PosTextSize.size2 : PosTextSize.size1)),
          PosColumn(
            text: value,
            width: 5,
            styles: PosStyles(align: PosAlign.right, bold: bold, height: big ? PosTextSize.size2 : PosTextSize.size1),
          ),
        ]);
    List<int> section(String title) => [...g.hr(), ...g.text(title, styles: const PosStyles(bold: true))];

    final bytes = <int>[
      ...ReceiptTemplate.header(g, caja),
      ...g.text('CIERRE DE CAJA', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)),
      ...g.text('Apertura: ${date(session['openedAt'])}'),
      ...g.text('Abrió: ${_safe(session['openedBy'])}'),
      ...g.text('Cierre: ${date(session['closedAt'])}'),
      ...g.text('Cerró: ${_safe(session['closedBy'])}'),

      // ── La sumatoria: lo vendido en el turno ──
      ...section('VENTA DEL TURNO'),
      ...row('Total vendido', money(summary.totalSales), bold: true, big: true),
      ...row('Ventas', '${summary.salesCount}'),
      ...row('En efectivo', money(summary.cashTotal)),
      ...row('Otros medios', money(summary.otherTotal)),

      ...section('POR MÉTODO DE PAGO'),
      for (final m in _list(r['byMethod'])) ...row('${_safe(m['name'])} (${m['count']})', money(m['total'])),
    ];

    final breb = _list(r['brebByLlave']);
    if (breb.isNotEmpty) {
      bytes.addAll(section('BRE-B POR LLAVE'));
      for (final b in breb) {
        bytes.addAll(row('${_safe(b['label'])} (${b['count']})', money(b['total'])));
      }
    }

    bytes.addAll(section('EFECTIVO'));
    bytes.addAll(row('Fondo inicial', money(r['openingAmount'])));
    bytes.addAll(row('+ Ventas efectivo', money(r['cashSales'])));
    if (_d(r['cashExpenses']) > 0) bytes.addAll(row('- Gastos de caja', money(r['cashExpenses'])));
    if (_d(r['cashPurchases']) > 0) bytes.addAll(row('- Compras de caja', money(r['cashPurchases'])));
    bytes.addAll(row('= Esperado', money(r['expectedAmount']), bold: true));
    bytes.addAll(row('Contado', money(r['closingAmount']), bold: true));

    final diff = _d(r['difference']);
    final diffLabel = diff.abs() <= 0.01 ? 'Cuadre exacto' : (diff < 0 ? 'FALTANTE' : 'SOBRANTE');
    bytes.addAll(g.hr());
    bytes.addAll(row(diffLabel, money(diff.abs()), bold: true, big: true));

    final notes = (session['notes'] as String?)?.trim();
    if (notes != null && notes.isNotEmpty) {
      bytes.addAll(g.hr());
      bytes.addAll(g.text('Notas: ${_safe(notes)}'));
    }

    bytes.addAll(g.feed(2));
    bytes.addAll(g.text('Firma: ______________________', styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(g.feed(3));
    bytes.addAll(g.cut());
    return bytes;
  }
}
