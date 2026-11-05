// lib/app/core/services/session_events.dart

import 'dart:convert';

/// Fecha de vencimiento (`exp`) de un JWT, leída sin verificar la firma (eso
/// lo hace el servidor). `null` si el token no es un JWT válido.
DateTime? jwtExpiry(String? token) {
  if (token == null || token.isEmpty) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
    final exp = payload is Map ? payload['exp'] : null;
    if (exp is num) return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
  } catch (_) {}
  return null;
}

/// Hasta cuándo se puede seguir usando la sesión sin volver a ingresar: el
/// token de acceso se renueva solo mientras el de renovación siga vigente,
/// así que manda el MÁS tardío de los dos. `null` = no se sabe (no hay
/// tokens legibles).
DateTime? sessionEndsAt(String? accessToken, String? refreshToken) {
  final a = jwtExpiry(accessToken);
  final r = jwtExpiry(refreshToken);
  if (a == null) return r;
  if (r == null) return a;
  return r.isAfter(a) ? r : a;
}

/// Aviso global "la sesión se terminó": lo dispara el cliente HTTP cuando el
/// servidor rechaza la renovación, y lo escucha AuthController para cerrar
/// sesión y llevar al login (en vez de dejar pantallas con errores).
class SessionEvents {
  SessionEvents._();

  static void Function()? onExpired;

  static void notifyExpired() => onExpired?.call();
}
