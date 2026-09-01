// Conditional import: the real serial-port implementation only exists on
// desktop (needs dart:ffi via flutter_libserialport, which cannot even be
// *compiled* for the web - not just unsupported at runtime). On web we swap
// in a stub that throws ScaleException on use. Same pattern as
// app/core/services/pdf_service.dart's pdf_service_mobile/pdf_service_web.
import 'scale_service_io.dart' if (dart.library.html) 'scale_service_web.dart' as scale_platform;

/// Thrown when the serial connection to the scale fails.
class ScaleException implements Exception {
  final String message;
  const ScaleException(this.message);

  @override
  String toString() => message;
}

/// Contract for reading live weight readings from the electronic scale
/// (Rochi RC-A01E, connected by USB/serial cable to a COM port), kept
/// independent from the concrete serial implementation.
abstract class ScaleService {
  /// Lists the serial ports currently available on this machine
  /// (e.g. "COM3" on Windows, "/dev/tty.usbserial-XXXX" on macOS/Linux).
  List<String> listAvailablePorts();

  /// Opens [portName] at [baudRate] and starts emitting weight readings (kg)
  /// on [weightStream]. Throws [ScaleException] if the port can't be opened.
  void connect({required String portName, required int baudRate});

  /// Stream of weight readings in kilograms, one per line/frame received
  /// from the scale. Emits a [ScaleException] via addError() on read errors.
  Stream<double> get weightStream;

  bool get isConnected;

  void disconnect();
}

/// Creates the platform-appropriate [ScaleService]: real serial port access
/// on desktop, a stub that reports "not supported" on web.
ScaleService createScaleService() => scale_platform.SerialScaleService();
