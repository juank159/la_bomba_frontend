import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('labombaSpeak')
external JSBoolean _labombaSpeak(JSString text, JSString? key);

/// Habla con la MISMA función que usa el service worker (web/index.html):
/// una sola cola de voz y un solo "ya lo dije" por cobro, así un pago no se
/// anuncia dos veces aunque lleguen el push y la confirmación del diálogo.
/// Devuelve false si la página no tiene la función (index.html viejo).
bool webSpeak(String text, {String? key}) {
  if (!globalContext.has('labombaSpeak')) return false;
  try {
    _labombaSpeak(text.toJS, key?.toJS);
    return true;
  } catch (_) {
    return false;
  }
}
