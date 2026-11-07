// lib/features/vegetable_cash_sessions/data/cash_session_report_api.dart

import '../../../app/config/api_config.dart';
import '../../../app/core/di/service_locator.dart';
import '../../../app/core/errors/http_error_info.dart';
import '../../../app/core/network/dio_client.dart';

/// Resultado de pedir el cuadre: el reporte, o un error legible.
class CashSessionReportResult {
  final Map<String, dynamic>? report;
  final String? error;
  final bool wrongPassword;
  const CashSessionReportResult({this.report, this.error, this.wrongPassword = false});
}

/// Cuadre completo de un turno (POST /vegetable-cash-sessions/:id/report).
/// La contraseña de Adalberto viaja en la petición y la valida el SERVIDOR
/// contra la base de datos: sin ella el backend nunca devuelve lo esperado
/// ni la diferencia (cierre a ciegas).
class CashSessionReportApi {
  CashSessionReportApi([DioClient? client]) : _dio = client ?? getIt<DioClient>();
  final DioClient _dio;

  Future<CashSessionReportResult> fetch(String sessionId, String password) async {
    try {
      final res = await _dio.post(
        '${ApiConfig.vegetableCashSessionsEndpoint}/$sessionId/report',
        data: {'password': password},
      );
      return CashSessionReportResult(report: Map<String, dynamic>.from(res.data as Map));
    } catch (e) {
      final info = HttpErrorInfo.of(e);
      // El backend responde 403 (no 401, para no disparar la renovación del
      // token) cuando la contraseña no es la de Adalberto.
      if (info.statusCode == 403) {
        return const CashSessionReportResult(error: 'Contraseña incorrecta', wrongPassword: true);
      }
      if (info.hasResponse) return CashSessionReportResult(error: info.message);
      return const CashSessionReportResult(error: 'Sin conexión con el servidor');
    }
  }

  /// Reporte para IMPRIMIR el cierre: sin contraseña, pero el servidor solo
  /// lo entrega si el turno ya está cerrado (en pantalla sigue con clave).
  Future<CashSessionReportResult> fetchReceipt(String sessionId) async {
    try {
      final res = await _dio.get('${ApiConfig.vegetableCashSessionsEndpoint}/$sessionId/receipt');
      return CashSessionReportResult(report: Map<String, dynamic>.from(res.data as Map));
    } catch (e) {
      final info = HttpErrorInfo.of(e);
      if (info.hasResponse) return CashSessionReportResult(error: info.message);
      return const CashSessionReportResult(error: 'Sin conexión con el servidor');
    }
  }
}
