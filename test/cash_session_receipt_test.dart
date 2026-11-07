import 'package:flutter_test/flutter_test.dart';
import 'package:pedidos_frontend/features/vegetable_cash_sessions/data/cash_session_receipt.dart';

Map<String, dynamic> report() => {
      'register': 'facturacion',
      'session': {
        'openedAt': '2026-11-07T13:00:00.000Z',
        'openedBy': 'adalberto',
        'closedAt': '2026-11-07T23:00:00.000Z',
        'closedBy': 'adalberto',
        'notes': 'Faltó cambio 🙈 — revisar',
      },
      'openingAmount': 50000,
      'cashSales': 30000,
      'cashExpenses': 0,
      'cashPurchases': 0,
      'expectedAmount': 80000,
      'closingAmount': 79000,
      'difference': -1000,
      'totalSales': 75500,
      'salesCount': 4,
      'byMethod': [
        {'name': 'Efectivo', 'isCash': true, 'count': 3, 'total': 30000},
        {'name': 'Bre-B', 'isCash': false, 'count': 1, 'total': 25500},
        {'name': 'Tarjeta', 'isCash': false, 'count': 1, 'total': 20000},
      ],
      'brebByLlave': [
        {'label': 'Bancolombia negocio (@labomba)', 'count': 1, 'total': 25500},
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la venta del turno suma todo y separa efectivo de otros medios', () {
    final s = CashSessionSalesSummary.fromReport(report());
    expect(s.totalSales, 75500);
    expect(s.salesCount, 4);
    expect(s.cashTotal, 30000);
    expect(s.otherTotal, 45500);
  });

  test('arma el recibo de cierre aunque la nota traiga emojis', () async {
    final bytes = await CashSessionReceipt.build(report());
    final text = String.fromCharCodes(bytes);
    expect(text, contains('CIERRE DE CAJA'));
    expect(text, contains('Caja de Facturaci'));
    expect(text, contains('Total vendido'));
    expect(text, contains('FALTANTE'));
    expect(text, contains('Bancolombia negocio'));
  });
}
