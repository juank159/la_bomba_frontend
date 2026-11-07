// lib/features/vegetable_cash_sessions/presentation/pages/vegetable_cash_session_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/core/utils/number_formatter.dart';
import '../../data/cash_session_receipt.dart';
import '../../data/cash_session_report_api.dart';
import '../widgets/print_cash_closing.dart';

/// Gris neutro legible tanto en tema claro como oscuro.
const _kMuted = Color(0xFF8A8F98);
const _kBorder = Color(0x33888888);


const _kBrebGreen = Color(0xFF32AF60);

/// Cuadre completo de un turno de caja de verduras — mismo estilo que el
/// cierre de caja de Food App: personal, efectivo (fondo + ventas − gastos −
/// compras = esperado), cierre (contado vs esperado → faltante/sobrante),
/// desglose por método, Bre-B por llave/banco con CADA transacción (hora,
/// cliente que pagó, referencia) y el detalle de ventas, gastos y compras.
///
/// La caja es A CIEGAS: este reporte solo se ve con la contraseña de
/// Adalberto, que valida el servidor. Se pide cada vez que se entra.
class VegetableCashSessionDetailPage extends StatefulWidget {
  final String sessionId;
  const VegetableCashSessionDetailPage({super.key, required this.sessionId});

  @override
  State<VegetableCashSessionDetailPage> createState() => _VegetableCashSessionDetailPageState();
}

class _VegetableCashSessionDetailPageState extends State<VegetableCashSessionDetailPage> {
  final _api = CashSessionReportApi();
  Map<String, dynamic>? _report;
  String? _password; // solo en memoria mientras la pantalla está abierta
  bool _loading = false;
  final Set<String> _expandedBreb = {};
  final Set<String> _expandedMethods = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (widget.sessionId.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    final report = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AdminPasswordDialog(
        onSubmit: (pw) async {
          final r = await _api.fetch(widget.sessionId, pw);
          if (r.report != null) _password = pw;
          return r;
        },
      ),
    );
    if (!mounted) return;
    if (report == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _report = report);
  }

  Future<void> _refresh() async {
    final pw = _password;
    if (pw == null) return _unlock();
    setState(() => _loading = true);
    final r = await _api.fetch(widget.sessionId, pw);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.report != null) _report = r.report;
    });
    if (r.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
    }
  }

  // ── helpers ──
  double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
  String _money(dynamic v) => NumberFormatter.formatCurrency(_d(v));
  DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
  String _dt(dynamic v) {
    final d = _date(v);
    return d == null ? '' : DateFormat('d/M/y h:mm a').format(d);
  }

  String _time(dynamic v) {
    final d = _date(v);
    return d == null ? '' : DateFormat('h:mm:ss a').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return Scaffold(
      appBar: AppBar(
        title: Text(r == null ? 'Cuadre de caja' : (r['isClosed'] == true ? 'Z de caja (cierre)' : 'X de caja (en curso)')),
        actions: [
          if (r != null && r['isClosed'] == true)
            IconButton(
              tooltip: 'Imprimir cierre',
              icon: const Icon(Icons.print_outlined),
              onPressed: () => printCashClosing(context, widget.sessionId, report: r),
            ),
          if (r != null)
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _loading ? null : _refresh,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
            ),
        ],
      ),
      body: r == null
          ? const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_outline, size: 48, color: _kMuted),
                SizedBox(height: 8),
                Text('Cuadre protegido con la contraseña de Adalberto'),
              ]),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: _buildReport(r),
                ),
              ),
            ),
    );
  }

  List<Widget> _buildReport(Map<String, dynamic> r) {
    final session = Map<String, dynamic>.from(r['session'] as Map);
    final isClosed = r['isClosed'] == true;
    final sales = ((r['sales'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final byMethod = ((r['byMethod'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final brebGroups = ((r['brebByLlave'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final expenses = ((r['expenses'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final purchases = ((r['purchases'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return [
      // ── Estado ──
      _InfoCard(children: [
        Row(children: [
          _StatusBadge(isClosed: isClosed),
          const SizedBox(width: 10),
          Expanded(child: Text('Apertura: ${_dt(session['openedAt'])}', style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
        if (session['closedAt'] != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.lock_outline, size: 14, color: _kMuted),
            const SizedBox(width: 6),
            Text('Cierre: ${_dt(session['closedAt'])}', style: const TextStyle(color: _kMuted)),
          ]),
        ],
        if ((session['notes'] as String?)?.trim().isNotEmpty == true) ...[
          const _Divider(),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.notes_outlined, size: 14, color: _kMuted),
            const SizedBox(width: 6),
            Expanded(child: Text(session['notes'] as String, style: const TextStyle(fontSize: 12, color: _kMuted))),
          ]),
        ],
      ]),
      const SizedBox(height: 12),
      _buildSalesSummaryCard(r),
      const SizedBox(height: 12),
      // ── Personal ──
      _InfoCard(header: 'PERSONAL', headerIcon: Icons.badge_outlined, children: [
        _staffRow('Abrió', session['openedBy']?.toString() ?? '—', Icons.lock_open, Colors.green),
        if (session['closedBy'] != null) ...[
          const SizedBox(height: 8),
          _staffRow('Cerró', session['closedBy'].toString(), Icons.lock_outline, Theme.of(context).colorScheme.primary),
        ],
      ]),
      const SizedBox(height: 12),
      // ── Efectivo ──
      _InfoCard(header: 'EFECTIVO', headerIcon: Icons.payments_outlined, children: [
        _amountRow('Fondo inicial', r['openingAmount'], Icons.savings_outlined, Colors.blue),
        const _Divider(),
        _amountRow('Ventas en efectivo', r['cashSales'], Icons.add_circle_outline, Colors.green, prefix: '+'),
        if (_d(r['cashExpenses']) > 0) ...[
          const _Divider(),
          _amountRow('Gastos pagados de la caja', r['cashExpenses'], Icons.remove_circle_outline, Colors.red, prefix: '−'),
        ],
        if (_d(r['cashPurchases']) > 0) ...[
          const _Divider(),
          _amountRow('Compras pagadas de la caja', r['cashPurchases'], Icons.shopping_basket_outlined, Colors.red, prefix: '−'),
        ],
        const _Divider(),
        _amountRow(isClosed ? 'Esperado al cierre' : 'Esperado en caja ahora', r['expectedAmount'],
            Icons.account_balance_wallet_outlined, Theme.of(context).colorScheme.primary,
            hero: true),
      ]),
      if (isClosed) ...[
        const SizedBox(height: 12),
        _buildCloseCard(r),
      ],
      const SizedBox(height: 12),
      // ── Desglose por método ──
      _InfoCard(
        header: 'DESGLOSE POR MÉTODO · ${sales.length} ventas · ${_money(r['totalSales'])}',
        headerIcon: Icons.pie_chart_outline,
        children: [
          if (byMethod.isEmpty) const Text('Sin ventas en este turno.', style: TextStyle(color: _kMuted)),
          for (final m in byMethod) _methodRow(m, sales),
        ],
      ),
      if (brebGroups.isNotEmpty) ...[
        const SizedBox(height: 12),
        _InfoCard(
          header: 'BRE-B POR LLAVE',
          headerIcon: Icons.bolt_outlined,
          headerColor: _kBrebGreen,
          children: [
            for (final g in brebGroups) _brebGroupRow(g, sales.where((s) => s['brebGroupKey'] == g['key']).toList()),
            const SizedBox(height: 4),
            const Text('Toca una llave para ver cada pago: hora, cliente y referencia del banco.',
                style: TextStyle(fontSize: 10, color: _kMuted)),
          ],
        ),
      ],
      if (expenses.isNotEmpty) ...[
        const SizedBox(height: 12),
        _InfoCard(header: 'GASTOS DE CAJA (${expenses.length})', headerIcon: Icons.receipt_long_outlined, headerColor: Colors.red, children: [
          for (final e in expenses)
            _lineRow(e['description']?.toString() ?? 'Gasto', '${_time(e['createdAt'])} · ${e['createdBy'] ?? ''}', e['amount'], prefix: '−'),
        ]),
      ],
      if (purchases.isNotEmpty) ...[
        const SizedBox(height: 12),
        _InfoCard(header: 'COMPRAS DE CAJA (${purchases.length})', headerIcon: Icons.shopping_basket_outlined, headerColor: Colors.red, children: [
          for (final p in purchases)
            _lineRow('Compra #${p['number']}', '${_time(p['createdAt'])} · ${p['createdBy'] ?? ''}', p['total'], prefix: '−'),
        ]),
      ],
    ];
  }

  /// La sumatoria del turno: todo lo vendido en esta caja (la "venta del
  /// día"), separado en efectivo y otros medios. Es lo mismo que sale
  /// impreso en el recibo de cierre.
  Widget _buildSalesSummaryCard(Map<String, dynamic> r) {
    final s = CashSessionSalesSummary.fromReport(r);
    return _InfoCard(header: 'VENTA DEL TURNO · ${s.salesCount} ventas', headerIcon: Icons.summarize_outlined, children: [
      _amountRow('Total vendido', s.totalSales, Icons.point_of_sale_outlined, Theme.of(context).colorScheme.primary, hero: true),
      const _Divider(),
      _amountRow('En efectivo', s.cashTotal, Icons.payments_outlined, Colors.green),
      const _Divider(),
      _amountRow('Transferencias, Bre-B y otros', s.otherTotal, Icons.account_balance_outlined, Colors.blue),
    ]);
  }

  Widget _buildCloseCard(Map<String, dynamic> r) {
    final diff = _d(r['difference']);
    final isOk = diff.abs() <= 0.01;
    final isMissing = diff < 0;
    final color = isOk ? Colors.green : (isMissing ? Colors.red : Colors.orange);
    return _InfoCard(header: 'CIERRE', headerIcon: Icons.lock_outline, children: [
      _amountRow('Contado al cierre (a ciegas)', r['closingAmount'], Icons.calculate_outlined, Colors.blueGrey),
      const _Divider(),
      _amountRow(
        isOk ? 'Cuadre exacto' : (isMissing ? 'Faltante' : 'Sobrante'),
        diff.abs(),
        isOk ? Icons.check_circle_outline : (isMissing ? Icons.error_outline : Icons.warning_amber_rounded),
        color,
        prefix: isOk ? '=' : (isMissing ? '−' : '+'),
        hero: true,
      ),
    ]);
  }

  Widget _methodRow(Map<String, dynamic> m, List<Map<String, dynamic>> sales) {
    final id = m['paymentMethodId']?.toString() ?? '';
    final isBreb = m['code'] == 'breb';
    final isCash = m['isCash'] == true;
    final color = isBreb ? _kBrebGreen : (isCash ? Colors.green : Colors.blue);
    final icon = isBreb ? Icons.bolt : (isCash ? Icons.payments_outlined : Icons.account_balance_outlined);
    // Una venta mixta (Bre-B + Efectivo) aparece en los dos métodos.
    final list = sales.where((s) => _parts(s).any((p) => p['paymentMethodId'] == id)).toList().reversed.toList();
    final expanded = _expandedMethods.contains(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => expanded ? _expandedMethods.remove(id) : _expandedMethods.add(id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              _iconBox(icon, color),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${m['name']} (${m['count']})${isCash ? '' : '  · no está en la caja física'}',
                    style: const TextStyle(fontSize: 13)),
              ),
              Text(_money(m['total']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: _kMuted),
            ]),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 6),
            child: Column(children: [for (final s in list) _saleRow(s, methodId: id)]),
          ),
      ],
    );
  }

  Widget _brebGroupRow(Map<String, dynamic> g, List<Map<String, dynamic>> sales) {
    final key = g['key']?.toString() ?? '';
    final expanded = _expandedBreb.contains(key);
    final adj = _d(g['total']) - _d(g['received']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => expanded ? _expandedBreb.remove(key) : _expandedBreb.add(key)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              _iconBox(Icons.bolt_outlined, _kBrebGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${g['label']} (${g['count']})', style: const TextStyle(fontSize: 13)),
                  if (adj > 0.009)
                    Text('Llegó al banco ${_money(g['received'])} (ajuste por monto único −${_money(adj)})',
                        style: const TextStyle(fontSize: 10, color: _kMuted)),
                ]),
              ),
              Text(_money(g['total']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: _kMuted),
            ]),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 6),
            child: Column(children: [for (final s in sales.reversed) _saleRow(s, brebOnly: true)]),
          ),
      ],
    );
  }

  /// Una venta: número, hora exacta, cliente que pagó (Bre-B), banco/llave
  /// y referencia — lo necesario para cruzarla con el extracto del banco.
  /// Partes del pago de una venta del reporte (ventas viejas: una sola).
  List<Map<String, dynamic>> _parts(Map<String, dynamic> s) {
    final raw = s['payments'];
    if (raw is List && raw.isNotEmpty) return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return [
      {'paymentMethodId': s['paymentMethodId'], 'paymentMethodName': s['paymentMethodName'], 'amount': s['total'], 'isBreb': s['isBreb']},
    ];
  }

  /// [methodId]/[brebOnly]: la venta se muestra dentro de un método o de una
  /// llave — en una venta mixta el valor de la derecha es solo esa parte.
  Widget _saleRow(Map<String, dynamic> s, {String? methodId, bool brebOnly = false}) {
    final isBreb = s['isBreb'] == true;
    final parts = _parts(s);
    final isSplit = parts.length > 1;
    final brebAmount = s['brebAmount'] ?? s['total'];
    final shown = !isSplit
        ? s['total']
        : brebOnly
            ? brebAmount
            : methodId != null
                ? parts.where((p) => p['paymentMethodId'] == methodId).fold<double>(0, (a, p) => a + _d(p['amount']))
                : s['total'];
    final payer = s['brebPayerName'] as String?;
    final llave = s['brebLlaveLabel'] ?? s['brebLlave'];
    final subtitle = <String>[
      _time(s['createdAt']),
      if (payer != null && payer.isNotEmpty) 'Cliente: $payer',
      if (isBreb && (s['brebBankLabel'] as String?)?.isNotEmpty == true) s['brebBankLabel'] as String,
      if (isBreb && llave != null) 'Llave: $llave',
      if (!isBreb) 'Vendió ${s['soldBy'] ?? ''}',
    ].join(' · ');
    final received = s['brebAmountReceived'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(Icons.receipt_outlined, Colors.green, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Venta #${s['number'].toString().padLeft(6, '0')}', style: const TextStyle(fontSize: 13)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
              if (isBreb && (s['brebReference'] as String?)?.isNotEmpty == true)
                Text('Ref: ${s['brebReference']}',
                    style: const TextStyle(fontSize: 10, color: _kMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (isSplit)
                Text(
                  'Pago mixto de ${_money(s['total'])}: '
                  '${parts.map((p) => '${p['paymentMethodName']} ${_money(p['amount'])}').join(' + ')}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange),
                ),
              if (isBreb && received != null && (_d(received) - _d(brebAmount)).abs() > 0.009)
                Text('Recibido en banco: ${_money(received)}', style: const TextStyle(fontSize: 10, color: _kMuted)),
            ]),
          ),
          const SizedBox(width: 8),
          Text(_money(shown), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _lineRow(String title, String subtitle, dynamic amount, {String prefix = ''}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
            ]),
          ),
          Text('$prefix${_money(amount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _staffRow(String label, String name, IconData icon, Color color) => Row(children: [
        _iconBox(icon, color, size: 32),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _kMuted, fontWeight: FontWeight.w600)),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ]);

  Widget _amountRow(String label, dynamic amount, IconData icon, Color color, {bool hero = false, String prefix = ''}) =>
      Row(children: [
        _iconBox(icon, color, size: hero ? 38 : 30),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: hero ? 13 : 12, fontWeight: hero ? FontWeight.w700 : FontWeight.w500)),
        ),
        Text('$prefix${_money(amount)}',
            style: TextStyle(fontSize: hero ? 18 : 14, fontWeight: FontWeight.w800, color: hero ? color : null)),
      ]);

  Widget _iconBox(IconData icon, Color color, {double size = 30}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: size / 2, color: color),
      );
}

class _StatusBadge extends StatelessWidget {
  final bool isClosed;
  const _StatusBadge({required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final color = isClosed ? Colors.blueGrey : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(isClosed ? 'Cerrada' : 'Abierta',
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String? header;
  final IconData? headerIcon;
  final Color? headerColor;
  final List<Widget> children;
  const _InfoCard({this.header, this.headerIcon, this.headerColor, required this.children});

  @override
  Widget build(BuildContext context) {
    final hc = headerColor ?? _kMuted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Row(children: [
              if (headerIcon != null) Icon(headerIcon, size: 13, color: hc),
              if (headerIcon != null) const SizedBox(width: 5),
              Flexible(
                child: Text(header!,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: hc, letterSpacing: 0.5)),
              ),
            ]),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1));
}

/// Pide la contraseña de Adalberto y la valida en el SERVIDOR (al pedir el
/// reporte). Devuelve el reporte si es correcta.
class _AdminPasswordDialog extends StatefulWidget {
  final Future<CashSessionReportResult> Function(String password) onSubmit;
  const _AdminPasswordDialog({required this.onSubmit});

  @override
  State<_AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<_AdminPasswordDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _ctrl.text;
    if (pw.isEmpty) {
      setState(() => _error = 'Ingresa la contraseña');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await widget.onSubmit(pw);
    if (!mounted) return;
    if (r.report != null) {
      Navigator.of(context).pop(r.report);
      return;
    }
    setState(() {
      _loading = false;
      _error = r.error;
      if (r.wrongPassword) _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.admin_panel_settings_outlined),
        SizedBox(width: 8),
        Expanded(child: Text('Ver cuadre de caja')),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('El cierre es a ciegas. Para ver cuánto debía haber y la diferencia, ingresa la '
              'contraseña de Adalberto Sanabria.'),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            obscureText: _obscure,
            enabled: !_loading,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: _error,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Ver cuadre'),
        ),
      ],
    );
  }
}
