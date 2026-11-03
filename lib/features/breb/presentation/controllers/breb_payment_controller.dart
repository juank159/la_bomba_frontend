// lib/features/breb/presentation/controllers/breb_payment_controller.dart

import 'dart:async';

import 'package:get/get.dart';

import '../../data/breb_api.dart';

/// Estados posibles del flujo de cobro Bre-B.
enum BrebPaymentState { idle, creatingCharge, waiting, paid, expired, error }

/// Módulo desde el que se cobra — define qué llaves/QR se muestran (lo
/// decide el admin en Configuración) y qué se registra al confirmar.
enum BrebModule {
  vegetables('vegetables'),
  invoices('invoices');

  const BrebModule(this.value);
  final String value;
}

/// Una llave Bre-B del negocio, tal cual la devuelve el backend al crear el
/// cobro (ya filtrada por módulo). Se muestran TODAS al cliente para que
/// transfiera a la que tenga a mano.
class BrebLlave {
  final String id;
  final String label;
  final String llave;

  /// QR ya armado con el monto de ESTE cobro — `null` si la llave no tiene
  /// plantilla de QR (el cliente igual puede usar el texto de la llave).
  final String? qrPayload;

  const BrebLlave({required this.id, required this.label, required this.llave, this.qrPayload});

  factory BrebLlave.fromJson(Map<String, dynamic> json) => BrebLlave(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? 'Llave',
        llave: json['llave'] as String? ?? '',
        qrPayload: json['qrPayload'] as String?,
      );
}

/// Un pago que SÍ llegó al banco pero no se pudo asignar solo (otro valor,
/// llegó tarde, dos iguales a la vez...). El cajero lo asigna a mano.
class BrebReceivedPayment {
  final String id;
  final double amount;
  final String? payerName;
  final String? bankLabel;
  final DateTime? receivedAt;

  const BrebReceivedPayment({required this.id, required this.amount, this.payerName, this.bankLabel, this.receivedAt});

  factory BrebReceivedPayment.fromJson(Map<String, dynamic> json) => BrebReceivedPayment(
        id: json['id'] as String? ?? '',
        amount: _toDouble(json['amount']),
        payerName: json['payerName'] as String?,
        bankLabel: json['bankLabel'] as String?,
        receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? ''),
      );
}

/// Resultado de un cobro confirmado: la venta/factura que el backend ya
/// registró sola al llegar el correo del banco.
class BrebChargeResult {
  final String saleId;
  final int saleNumber;
  final String payerName;
  final double amountReceived;

  const BrebChargeResult({
    required this.saleId,
    required this.saleNumber,
    required this.payerName,
    required this.amountReceived,
  });
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

/// Controla el cobro Bre-B (transferencia con llave, conciliada por el
/// backend a partir del correo del banco):
///   1. Crea el cobro en el backend con el borrador de la venta.
///   2. Muestra llaves + QR y hace polling cada 3 s (red de seguridad: la
///      confirmación casi siempre llega antes por push, ver [markConfirmed]).
///   3. Cuando el banco confirma, el backend YA registró la venta → `paid`.
class BrebPaymentController extends GetxController {
  BrebPaymentController({BrebApi? api}) : _api = api ?? BrebApi();
  final BrebApi _api;

  /// El cobro que está esperando confirmación ahora mismo — lo usa el
  /// handler de push para confirmarlo al instante. Solo puede haber uno
  /// abierto a la vez (un cajero cobra una venta por vez).
  static BrebPaymentController? active;

  final Rx<BrebPaymentState> state = BrebPaymentState.idle.obs;
  final RxString chargeId = ''.obs;
  final RxList<BrebLlave> llaves = <BrebLlave>[].obs;
  final Rx<DateTime?> expiresAt = Rx<DateTime?>(null);

  /// Monto EXACTO que debe transferir el cliente. Puede ser hasta $9 menor
  /// que lo pedido: el backend lo baja para que no haya dos cobros
  /// pendientes del mismo valor (el negocio absorbe la diferencia).
  final RxDouble chargeAmount = 0.0.obs;
  final RxDouble requestedAmount = 0.0.obs;
  final RxString payerName = ''.obs;
  final RxString errorMsg = ''.obs;
  final RxInt secondsLeft = 0.obs;
  /// Duración total del cobro (para la barra de cuenta regresiva).
  int totalSeconds = 600;

  /// Venta/factura registrada al confirmar.
  final Rx<BrebChargeResult?> result = Rx<BrebChargeResult?>(null);

  double get adjustment {
    final d = requestedAmount.value - chargeAmount.value;
    return d > 0.009 ? d : 0;
  }

  Timer? _pollingTimer;
  Timer? _countdownTimer;
  bool _polling = false;

  @override
  void onClose() {
    _stopTimers();
    if (identical(active, this)) active = null;
    super.onClose();
  }

  Future<void> createCharge({
    required BrebModule module,
    required Map<String, dynamic> draft,
    required double amount,
  }) async {
    state.value = BrebPaymentState.creatingCharge;
    errorMsg.value = '';
    result.value = null;
    payerName.value = '';
    requestedAmount.value = amount;
    chargeAmount.value = amount;
    _stopTimers();
    active = this;

    try {
      final data = await _api.createCharge(module: module.value, draft: draft, amount: amount);
      chargeId.value = data['chargeId'] as String;
      chargeAmount.value = _toDouble(data['amount']);
      requestedAmount.value = _toDouble(data['requestedAmount']);
      llaves.value = ((data['llaves'] as List?) ?? [])
          .map((e) => BrebLlave.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final exp = data['expiresAt'] as String?;
      expiresAt.value = exp != null ? DateTime.parse(exp) : null;
      if (expiresAt.value != null) {
        totalSeconds = expiresAt.value!.difference(DateTime.now()).inSeconds.clamp(1, 3600);
      }
      state.value = BrebPaymentState.waiting;
      _startPolling();
      _startCountdown();
    } catch (e) {
      errorMsg.value = BrebApi.errorMessage(e, 'Error iniciando el cobro');
      state.value = BrebPaymentState.error;
    }
  }

  /// Llamado por el handler de push cuando llega la confirmación en tiempo
  /// real. Hace una consulta inmediata para traer la venta registrada.
  void markConfirmed({String? payer}) {
    if (state.value != BrebPaymentState.waiting) return;
    if (payer != null && payer.isNotEmpty) payerName.value = payer;
    _poll();
  }

  Future<List<BrebReceivedPayment>> loadUnassigned() async {
    final raw = await _api.unassigned();
    return raw.map(BrebReceivedPayment.fromJson).toList();
  }

  /// Asigna a mano [payment] a ESTE cobro (el backend registra la venta en
  /// ese momento). Devuelve `null` si salió bien o el mensaje de error.
  Future<String?> assignReceived(BrebReceivedPayment payment) async {
    final id = chargeId.value;
    if (id.isEmpty) return 'No hay un cobro activo';
    try {
      final data = await _api.assign(id, payment.id);
      _stopTimers();
      payerName.value = payment.payerName ?? '';
      final received = payment.amount < requestedAmount.value ? payment.amount : requestedAmount.value;
      chargeAmount.value = received;
      result.value = BrebChargeResult(
        saleId: data['saleId'] as String? ?? '',
        saleNumber: (data['saleNumber'] as num?)?.toInt() ?? 0,
        payerName: payerName.value,
        amountReceived: received,
      );
      state.value = BrebPaymentState.paid;
      return null;
    } catch (e) {
      return BrebApi.errorMessage(e, 'No se pudo asignar el pago');
    }
  }

  /// Cancela el cobro (si sigue pendiente) y limpia todo.
  void cancel() {
    final id = chargeId.value;
    final wasWaiting = state.value == BrebPaymentState.waiting || state.value == BrebPaymentState.expired;
    _stopTimers();
    if (id.isNotEmpty && wasWaiting) {
      // Si falla, el cobro igual expira solo.
      _api.cancel(id).catchError((_) {});
    }
    state.value = BrebPaymentState.idle;
    chargeId.value = '';
    llaves.clear();
    expiresAt.value = null;
    secondsLeft.value = 0;
    if (identical(active, this)) active = null;
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  void _startCountdown() {
    final exp = expiresAt.value;
    if (exp == null) return;
    void tick() {
      final remaining = exp.difference(DateTime.now()).inSeconds;
      secondsLeft.value = remaining < 0 ? 0 : remaining;
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _stopTimers() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _poll() async {
    if (state.value != BrebPaymentState.waiting || _polling || chargeId.value.isEmpty) return;
    _polling = true;
    try {
      final data = await _api.status(chargeId.value);
      final status = data['status'] as String? ?? 'pending';
      if (status == 'matched') {
        _stopTimers();
        final payer = data['payerName'] as String? ?? payerName.value;
        payerName.value = payer;
        result.value = BrebChargeResult(
          saleId: data['saleId'] as String? ?? '',
          saleNumber: (data['saleNumber'] as num?)?.toInt() ?? 0,
          payerName: payer,
          amountReceived: chargeAmount.value,
        );
        state.value = BrebPaymentState.paid;
      } else if (status == 'expired' || status == 'cancelled') {
        _stopTimers();
        state.value = BrebPaymentState.expired;
      }
    } catch (_) {
      // Errores de red: se reintenta en el próximo tick; el countdown avisa.
    } finally {
      _polling = false;
    }
  }
}
