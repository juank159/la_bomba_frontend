// lib/features/breb/data/breb_api.dart

import '../../../app/core/di/service_locator.dart';
import '../../../app/core/errors/exceptions.dart';
import '../../../app/core/errors/http_error_info.dart';
import '../../../app/core/network/dio_client.dart';

/// Acceso HTTP a `/breb/*` del backend. Fino a propósito: la lógica vive en
/// el backend (BrebService) y en [BrebPaymentController].
class BrebApi {
  BrebApi([DioClient? client]) : _dio = client ?? getIt<DioClient>();
  final DioClient _dio;

  Future<Map<String, dynamic>> createCharge({
    required String module,
    required Map<String, dynamic> draft,
    required double amount,
    String? restPaymentMethodId,
  }) async {
    final res = await _dio.post('/breb/charge', data: {
      'module': module,
      'draft': draft,
      'amount': amount,
      if (restPaymentMethodId != null) 'restPaymentMethodId': restPaymentMethodId,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> status(String chargeId) async {
    final res = await _dio.get('/breb/status/$chargeId');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> cancel(String chargeId) => _dio.post('/breb/cancel/$chargeId');

  Future<List<Map<String, dynamic>>> unassigned() async {
    final res = await _dio.get('/breb/unassigned');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> assign(String chargeId, String emailId, {String? restPaymentMethodId}) async {
    final res = await _dio.post('/breb/assign', data: {
      'chargeId': chargeId,
      'emailId': emailId,
      if (restPaymentMethodId != null) 'restPaymentMethodId': restPaymentMethodId,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  // ── Admin ──
  Future<Map<String, dynamic>> getSettings() async {
    final res = await _dio.get('/breb/settings');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> saveSettings(List<Map<String, dynamic>> llaves) async {
    final res = await _dio.put('/breb/settings', data: {'llaves': llaves});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<String> previewQr(String template, double amount) async {
    final res = await _dio.post('/breb/qr-preview', data: {'template': template, 'amount': amount});
    return (res.data as Map)['payload'] as String;
  }

  Future<List<Map<String, dynamic>>> recentEmails() async {
    final res = await _dio.get('/breb/recent-emails');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> charges({DateTime? from, DateTime? to, String? module}) async {
    final res = await _dio.get('/breb/charges', queryParameters: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      if (module != null) 'module': module,
    });
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Mensaje legible de un error del backend (o de red).
  static String errorMessage(Object e, [String fallback = 'Ocurrió un error']) {
    final info = HttpErrorInfo.of(e);
    if (info.hasResponse) return info.message.isNotEmpty ? info.message : fallback;
    if (e is AppException) {
      return 'Sin conexión con el servidor. Bre-B necesita internet para confirmar '
          'el pago con el banco. Cobra con otro método (efectivo/transferencia).';
    }
    return fallback;
  }
}
