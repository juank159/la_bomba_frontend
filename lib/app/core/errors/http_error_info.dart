// lib/app/core/errors/http_error_info.dart

import 'package:dio/dio.dart';

import 'exceptions.dart';

/// Distingue "el servidor respondió con error" de "no hubo conexión".
///
/// El interceptor de DioClient re-envuelve cada error en un DioException
/// nuevo sin conservar su tipo, así que al final casi todo llega como
/// NetworkException aunque el servidor SÍ haya respondido (un 400/403). El
/// mensaje del servidor se conserva en `message`, y la respuesta original
/// en `originalError` — de ahí se saca el código HTTP real.
class HttpErrorInfo {
  final int? statusCode;
  final String message;
  const HttpErrorInfo(this.statusCode, this.message);

  bool get hasResponse => statusCode != null;

  static HttpErrorInfo of(Object e) {
    if (e is ServerException) return HttpErrorInfo(e.statusCode, e.message);
    if (e is AppException) {
      final orig = e.originalError;
      final status = orig is DioException ? orig.response?.statusCode : null;
      return HttpErrorInfo(status, e.message);
    }
    if (e is DioException) return HttpErrorInfo(e.response?.statusCode, e.message ?? '');
    return HttpErrorInfo(null, e.toString());
  }
}
