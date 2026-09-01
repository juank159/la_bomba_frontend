import 'scale_service.dart';

/// Web stub for [ScaleService]: browsers can't open a raw serial (COM) port,
/// so every operation just reports that clearly instead of being available.
/// The real implementation (scale_service_io.dart) only compiles on desktop.
class SerialScaleService implements ScaleService {
  static const _unsupportedMessage =
      'La conexión con la báscula por puerto serial no está disponible en la '
      'versión web. Usa la app de escritorio (Windows/macOS) donde está '
      'conectada la báscula.';

  @override
  List<String> listAvailablePorts() {
    throw const ScaleException(_unsupportedMessage);
  }

  @override
  Stream<double> get weightStream => const Stream.empty();

  @override
  bool get isConnected => false;

  @override
  void connect({required String portName, required int baudRate}) {
    throw const ScaleException(_unsupportedMessage);
  }

  @override
  void disconnect() {}
}
