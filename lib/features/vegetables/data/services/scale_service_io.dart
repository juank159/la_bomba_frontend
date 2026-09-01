import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'scale_service.dart';

/// Serial-port implementation of [ScaleService] using flutter_libserialport
/// (desktop only: Windows, macOS, Linux — no Web or mobile support, since
/// browsers/phones can't open a raw COM port. This file is only ever
/// compiled on those platforms, see scale_service.dart's conditional import).
///
/// IMPORTANT — protocolo de la báscula: no encontramos documentación pública
/// del protocolo de trama exacto de la Rochi RC-A01E (fabricante colombiano,
/// sin manual técnico publicado). La mayoría de básculas de mostrador de este
/// tipo transmiten continuamente una línea de texto ASCII por cada lectura de
/// peso (terminada en \r y/o \n) con el número, con o sin signo/unidad
/// (ej. "+001.250kg", "ST,GS,+1.250", "001250"). Este parser genérico busca el
/// primer número decimal (con signo opcional) en cada línea recibida.
///
/// Si al conectar la báscula real los números no coinciden (por ejemplo si
/// el peso viene en gramos en vez de kg, o el separador decimal es distinto),
/// ajusta únicamente [_parseWeightKg] — el resto del servicio no cambia.
class SerialScaleService implements ScaleService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;
  final StreamController<double> _weightController = StreamController<double>.broadcast();
  String _buffer = '';

  static final RegExp _numberPattern = RegExp(r'[-+]?\d+(?:[.,]\d+)?');

  @override
  List<String> listAvailablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      throw ScaleException('No se pudieron listar los puertos seriales: ${e.toString()}');
    }
  }

  @override
  Stream<double> get weightStream => _weightController.stream;

  @override
  bool get isConnected => _port?.isOpen ?? false;

  @override
  void connect({required String portName, required int baudRate}) {
    disconnect();

    final port = SerialPort(portName);
    try {
      if (!port.openReadWrite()) {
        throw ScaleException(
          'No se pudo abrir el puerto $portName. Verifica que la báscula esté '
          'encendida, conectada, y que ninguna otra aplicación esté usando el puerto.',
        );
      }

      final config = SerialPortConfig()
        ..baudRate = baudRate
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1
        ..setFlowControl(SerialPortFlowControl.none);
      port.config = config;

      _port = port;
      _buffer = '';
      _reader = SerialPortReader(port);
      _subscription = _reader!.stream.listen(
        _onData,
        onError: (Object error) {
          _weightController.addError(ScaleException('Error leyendo la báscula: ${error.toString()}'));
        },
      );
    } catch (e) {
      port.dispose();
      _port = null;
      if (e is ScaleException) rethrow;
      throw ScaleException('No se pudo conectar con la báscula en $portName: ${e.toString()}');
    }
  }

  void _onData(Uint8List bytes) {
    _buffer += utf8.decode(bytes, allowMalformed: true);

    // Cada línea (separada por \r o \n) es una lectura de peso.
    final lines = _buffer.split(RegExp(r'[\r\n]+'));
    // La última "línea" puede estar incompleta (llegó a mitad de trama):
    // la dejamos en el buffer para completarla con el próximo chunk.
    _buffer = lines.removeLast();

    for (final line in lines) {
      final weight = _parseWeightKg(line);
      if (weight != null) {
        _weightController.add(weight);
      }
    }
  }

  double? _parseWeightKg(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final match = _numberPattern.firstMatch(trimmed);
    if (match == null) return null;

    return double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  @override
  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _reader = null;
    try {
      _port?.close();
    } catch (_) {
      // Puerto ya cerrado o desconectado - no hay nada que limpiar.
    }
    _port?.dispose();
    _port = null;
  }
}
