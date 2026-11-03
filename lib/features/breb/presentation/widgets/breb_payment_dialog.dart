// lib/features/breb/presentation/widgets/breb_payment_dialog.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/core/utils/number_formatter.dart';
import '../controllers/breb_payment_controller.dart';

const _kBrebGreen = Color(0xFF32AF60);

/// Abre el cobro Bre-B y devuelve la venta/factura ya registrada cuando el
/// banco confirma el pago, o `null` si se canceló.
///
/// [draft] es el cuerpo de la venta (sin `paymentMethodId`): el backend la
/// registra sola al llegar el correo del banco, así que aunque se cierre la
/// app justo después de que el cliente pague, la venta queda guardada.
Future<BrebChargeResult?> showBrebPaymentDialog(
  BuildContext context, {
  required BrebModule module,
  required Map<String, dynamic> draft,
  required double amount,
}) async {
  final controller = BrebPaymentController();
  try {
    final paid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrebPaymentDialog(controller: controller, module: module, draft: draft, amount: amount),
    );
    return paid == true ? controller.result.value : null;
  } finally {
    controller.cancel();
    controller.onClose();
  }
}

void _toast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger != null) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
  }
}

String _money(double v) => NumberFormatter.formatCurrency(v);

/// Diálogo completo de cobro Bre-B (transferencia directa con llave). Igual
/// al de Food App: el cajero le muestra la llave o el QR (con el monto ya
/// incrustado) al cliente, que transfiere desde su banco; la confirmación
/// llega sola por el correo del banco (push + polling cada 3 s).
class BrebPaymentDialog extends StatefulWidget {
  final BrebPaymentController controller;
  final BrebModule module;
  final Map<String, dynamic> draft;
  final double amount;

  const BrebPaymentDialog({
    super.key,
    required this.controller,
    required this.module,
    required this.draft,
    required this.amount,
  });

  @override
  State<BrebPaymentDialog> createState() => _BrebPaymentDialogState();
}

class _BrebPaymentDialogState extends State<BrebPaymentDialog> {
  /// Segundos que se muestra "¡Pago confirmado!" antes de cerrarse solo.
  static const _autoCloseSeconds = 5;

  ModalRoute<dynamic>? _route;
  Worker? _stateWorker;
  Timer? _autoCloseTimer;
  final RxInt _closeIn = 0.obs;
  bool _closed = false;

  BrebPaymentController get c => widget.controller;

  void _createCharge() => c.createCharge(module: widget.module, draft: widget.draft, amount: widget.amount);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _createCharge());
    // El cierre automático se arranca UNA vez al pasar a pagado (si se
    // agendara en build, cada redibujo sumaría otro pop).
    _stateWorker = ever<BrebPaymentState>(c.state, (s) {
      if (s == BrebPaymentState.paid) _startAutoClose();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= ModalRoute.of(context);
  }

  @override
  void dispose() {
    _stateWorker?.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _startAutoClose() {
    if (_autoCloseTimer != null || _closed) return;
    // Lo que esté abierto encima (QR ampliado, "Buscar pago") se cierra ya.
    final route = _route;
    if (mounted && route != null && route.isActive && !route.isCurrent) {
      Navigator.of(context).popUntil((r) => r == route);
    }
    HapticFeedback.mediumImpact();
    _closeIn.value = _autoCloseSeconds;
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _closeIn.value = _closeIn.value - 1;
      if (_closeIn.value <= 0) _closeAsPaid();
    });
  }

  void _closeAsPaid() {
    _autoCloseTimer?.cancel();
    if (_closed || !mounted) return;
    final route = _route;
    if (route == null || !route.isActive) return;
    _closed = true;
    final nav = Navigator.of(context);
    nav.popUntil((r) => r == route);
    nav.pop(true);
  }

  void _cancel() {
    // Con el pago ya confirmado, la X es "cerrar", nunca "cancelar".
    if (c.state.value == BrebPaymentState.paid) {
      _closeAsPaid();
      return;
    }
    c.cancel();
    Navigator.of(context).pop(false);
  }

  double get _amount => c.chargeAmount.value > 0 ? c.chargeAmount.value : widget.amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final isSmall = mq.size.height < 700;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 24, vertical: isSmall ? 12 : 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: mq.size.height * 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Container(
                padding: EdgeInsets.all(isSmall ? 14 : 20),
                decoration: const BoxDecoration(
                  color: _kBrebGreen,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        final adj = c.adjustment;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pago con Bre-B',
                                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(_money(_amount),
                                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                            if (adj > 0 && c.state.value == BrebPaymentState.waiting)
                              Text(
                                'Ajustado −${_money(adj)} para identificar el pago al instante. '
                                'Pídele al cliente este valor exacto.',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                              ),
                          ],
                        );
                      }),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _cancel),
                  ],
                ),
              ),
              // ── Cuerpo reactivo ──
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmall ? 14 : 20),
                  child: Obx(() => _buildBody(context, theme)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    switch (c.state.value) {
      case BrebPaymentState.idle:
      case BrebPaymentState.creatingCharge:
        return _buildLoading(theme);
      case BrebPaymentState.waiting:
        return _buildWaiting(context, theme);
      case BrebPaymentState.paid:
        return _buildSuccess(theme);
      case BrebPaymentState.expired:
        return _buildExpired(theme);
      case BrebPaymentState.error:
        return _buildError(theme);
    }
  }

  Widget _buildLoading(ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          const CircularProgressIndicator(color: _kBrebGreen),
          const SizedBox(height: 16),
          Text('Iniciando cobro…', style: theme.textTheme.bodyLarge),
        ]),
      );

  Widget _buildWaiting(BuildContext context, ThemeData theme) {
    final llaves = c.llaves;
    final seconds = c.secondsLeft.value;
    final expired = seconds <= 0 && c.expiresAt.value != null;

    return Column(
      children: [
        Text(
          llaves.length > 1
              ? 'Dale al cliente cualquiera de estas llaves para que transfiera desde su banco'
              : 'Dale esta llave al cliente para que transfiera desde su banco',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < llaves.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _LlaveCard(llave: llaves[i], amount: _amount),
        ],
        const SizedBox(height: 16),
        if (!expired) ...[
          _CountdownBar(secondsLeft: seconds, totalSeconds: _totalSeconds()),
          const SizedBox(height: 4),
          Text(
            'Expira en ${_formatSeconds(seconds)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: seconds <= 60 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          const Icon(Icons.timer_off_outlined, color: Colors.orange, size: 28),
          const SizedBox(height: 4),
          Text('Cobro expirado', style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kBrebGreen)),
            const SizedBox(width: 8),
            Text('Esperando confirmación del banco…', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        _findReceivedButton(),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _cancel,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }

  /// Red de seguridad: el cliente ya transfirió pero el pago no se asignó
  /// solo (mandó otro valor, llegó tarde…). El cajero lo busca y lo asigna.
  Widget _findReceivedButton() => TextButton.icon(
        icon: const Icon(Icons.manage_search, size: 18),
        label: const Text('¿Ya pagó y no se confirma? Buscar pago'),
        onPressed: _openReceivedPayments,
      );

  Future<void> _openReceivedPayments() async {
    final picked = await showDialog<BrebReceivedPayment>(
      context: context,
      builder: (_) => _ReceivedPaymentsDialog(controller: c, expected: _amount),
    );
    if (picked == null || !mounted) return;
    final err = await c.assignReceived(picked);
    if (err != null && mounted) _toast(context, err);
  }

  Widget _buildSuccess(ThemeData theme) {
    final payer = c.payerName.value;
    final saleNumber = c.result.value?.saleNumber ?? 0;
    final what = widget.module == BrebModule.vegetables ? 'Venta' : 'Factura';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 56),
          ),
          const SizedBox(height: 16),
          Text('¡Pago confirmado!',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 8),
          Text(_money(_amount), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            payer.isNotEmpty ? 'Transferencia de $payer confirmada.' : 'Transferencia confirmada.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (saleNumber > 0) ...[
            const SizedBox(height: 4),
            Text('$what #${saleNumber.toString().padLeft(6, '0')} registrada.',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _closeAsPaid,
              child: Obx(() => Text(_closeIn.value > 0 ? 'Listo (${_closeIn.value})' : 'Listo')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpired(ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.timer_off, color: Colors.orange, size: 48),
            const SizedBox(height: 12),
            Text('El cobro expiró', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('El cliente no transfirió a tiempo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            _findReceivedButton(),
            const SizedBox(height: 12),
            _retryRow(),
          ],
        ),
      );

  Widget _buildError(ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text('No se pudo iniciar el cobro',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(c.errorMsg.value,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            _retryRow(),
          ],
        ),
      );

  Widget _retryRow() => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              onPressed: () {
                c.cancel();
                _createCharge();
              },
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: _kBrebGreen),
            ),
          ),
        ],
      );

  int _totalSeconds() => c.totalSeconds;

  String _formatSeconds(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Una llave del negocio como tarjeta copiable, con botón para mostrar su
/// QR (con el monto ya incrustado) si el admin configuró la plantilla.
class _LlaveCard extends StatelessWidget {
  final BrebLlave llave;
  final double amount;
  const _LlaveCard({required this.llave, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBrebGreen, width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () {
              Clipboard.setData(ClipboardData(text: llave.llave));
              _toast(context, '${llave.label} copiada');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                children: [
                  Text(llave.label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.black54)),
                  const SizedBox(height: 4),
                  SelectableText(llave.llave,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900, color: const Color(0xFF1A1A2E), letterSpacing: 1)),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, size: 14, color: Colors.black45),
                      SizedBox(width: 4),
                      Text('Toca para copiar', style: TextStyle(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (llave.qrPayload != null) ...[
            const Divider(height: 1),
            InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              onTap: () => showDialog(context: context, builder: (_) => _QrPreviewDialog(llave: llave, amount: amount)),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 18, color: _kBrebGreen),
                    SizedBox(width: 6),
                    Text('Mostrar QR', style: TextStyle(fontWeight: FontWeight.w800, color: _kBrebGreen)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// QR grande — el cliente lo escanea con la app de su banco; el monto ya
/// viene incluido, no hay que pedirle que lo escriba.
class _QrPreviewDialog extends StatelessWidget {
  final BrebLlave llave;
  final double amount;
  const _QrPreviewDialog({required this.llave, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(llave.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_money(amount), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: QrImageView(data: llave.qrPayload!, size: 260, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'El cliente escanea con la app de su banco — el monto ya viene incluido.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pagos Bre-B recibidos sin asignar (últimas 24 h). El cajero toca el que
/// corresponde a esta venta.
class _ReceivedPaymentsDialog extends StatefulWidget {
  final BrebPaymentController controller;
  final double expected;
  const _ReceivedPaymentsDialog({required this.controller, required this.expected});

  @override
  State<_ReceivedPaymentsDialog> createState() => _ReceivedPaymentsDialogState();
}

class _ReceivedPaymentsDialogState extends State<_ReceivedPaymentsDialog> {
  late Future<List<BrebReceivedPayment>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.loadUnassigned();
  }

  void _reload() => setState(() => _future = widget.controller.loadUnassigned());

  Future<void> _pick(BrebReceivedPayment p) async {
    final diff = widget.expected - p.amount;
    if (diff > 9.009) {
      _toast(context,
          'Ese pago (${_money(p.amount)}) es menor que el cobro. Cobra la diferencia aparte o elige el pago correcto.');
      return;
    }
    final warning = diff < -0.009
        ? '\n\nEste pago es MAYOR que el cobro: la venta se registra por ${_money(widget.expected)}.'
        : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Asignar este pago a la venta?'),
        content: Text(
            '${_money(p.amount)}${p.payerName != null && p.payerName!.isNotEmpty ? ' de ${p.payerName}' : ''}$warning'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Asignar')),
        ],
      ),
    );
    if ((ok ?? false) && mounted) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('h:mm a');
    return AlertDialog(
      title: const Text('Pagos recibidos sin asignar'),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      content: SizedBox(
        width: 380,
        child: FutureBuilder<List<BrebReceivedPayment>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No se pudo cargar (¿hay internet?).',
                    textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Todavía no llegó ningún pago sin asignar. Si el cliente acaba de transferir, '
                  'espera unos segundos y actualiza.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = items[i];
                final exact = (widget.expected - p.amount).abs() < 0.01;
                return ListTile(
                  leading: Icon(exact ? Icons.check_circle : Icons.payments_outlined,
                      color: exact ? Colors.green : theme.colorScheme.onSurfaceVariant),
                  title: Text(_money(p.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text([
                    if (p.payerName != null && p.payerName!.isNotEmpty) p.payerName!,
                    if (p.bankLabel != null && p.bankLabel!.isNotEmpty) p.bankLabel!,
                    if (p.receivedAt != null) timeFmt.format(p.receivedAt!.toLocal()),
                  ].join(' · ')),
                  onTap: () => _pick(p),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton.icon(icon: const Icon(Icons.refresh, size: 18), label: const Text('Actualizar'), onPressed: _reload),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}

class _CountdownBar extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  const _CountdownBar({required this.secondsLeft, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    final ratio = totalSeconds > 0 ? secondsLeft / totalSeconds : 0.0;
    final Color color = ratio > 0.4 ? Colors.green : (ratio > 0.15 ? Colors.orange : Colors.red);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: ratio.clamp(0.0, 1.0),
        backgroundColor: color.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: 6,
      ),
    );
  }
}
