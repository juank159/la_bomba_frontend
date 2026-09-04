// lib/app/core/services/thermal_printer_sender.dart

// Conditional export: la implementación real habla con Windows (socket TCP
// crudo + Print Spooler de Windows vía dart:ffi/win32), y eso ni siquiera
// se puede *compilar* para web (los structs FFI de win32 rompen dart2js,
// no es solo que fallen en tiempo de ejecución). En web se usa un stub que
// siempre reporta "no disponible". Mismo patrón que scale_service.dart /
// pdf_service.dart (io/web split).
export 'thermal_printer_sender_io.dart'
    if (dart.library.html) 'thermal_printer_sender_web.dart';

/// Thrown when sending raw bytes to the configured printer fails, for
/// either transport (network or USB).
class ThermalPrinterSenderException implements Exception {
  final String message;
  const ThermalPrinterSenderException(this.message);

  @override
  String toString() => message;
}
