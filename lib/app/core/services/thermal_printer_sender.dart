// lib/app/core/services/thermal_printer_sender.dart

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:win32/win32.dart' as win32;

import 'printer_destination.dart';

/// Thrown when sending raw bytes to the configured printer fails, for
/// either transport (network or USB).
class ThermalPrinterSenderException implements Exception {
  final String message;
  const ThermalPrinterSenderException(this.message);

  @override
  String toString() => message;
}

/// The single place in the app that actually pushes raw ESC/POS bytes to a
/// physical thermal printer. Shared by every feature that prints receipts
/// (Facturación, Verduras) so "how do we reach the printer" is defined
/// once, not duplicated per feature.
///
/// Two transports:
/// - **network**: raw TCP socket to `ip:port` - works on Android, iOS,
///   macOS, Windows and Linux; not on Flutter Web (no raw sockets in a
///   browser).
/// - **usb**: sent through the Windows Print Spooler using the `RAW`
///   datatype, to a printer already installed in Windows. This is how a
///   USB thermal printer is reached - Windows exposes it as an installed
///   printer (via its driver) once plugged in, and RAW datatype means the
///   spooler forwards our ESC/POS bytes untouched instead of trying to
///   interpret them as text/GDI drawing commands. Windows desktop only.
class ThermalPrinterSender {
  static const Duration _connectTimeout = Duration(seconds: 5);

  // winspool.h PRINTER_ACCESS_USE - not exposed as a named constant by the
  // win32 package, value is stable/documented by Microsoft.
  static const int _printerAccessUse = 0x00000008;

  bool get isUsbSupported => !kIsWeb && Platform.isWindows;

  Future<void> send(List<int> bytes, PrinterDestination destination) async {
    switch (destination.type) {
      case PrinterConnectionType.network:
        await _sendNetwork(bytes, destination.ip, destination.port);
      case PrinterConnectionType.usb:
        await _sendUsb(bytes, destination.usbPrinterName);
    }
  }

  Future<void> _sendNetwork(List<int> bytes, String ip, int port) async {
    if (kIsWeb) {
      throw const ThermalPrinterSenderException(
        'La impresión térmica por red no está disponible en la versión web.',
      );
    }

    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: _connectTimeout);
      socket.add(bytes);
      await socket.flush();
    } on SocketException catch (e) {
      throw ThermalPrinterSenderException(
        'No se pudo conectar a la impresora en $ip:$port. Verifica la IP y que '
        'la impresora esté encendida y en la misma red. (${e.message})',
      );
    } catch (e) {
      throw ThermalPrinterSenderException('Error al imprimir: $e');
    } finally {
      await socket?.close();
    }
  }

  Future<void> _sendUsb(List<int> bytes, String printerName) async {
    if (!isUsbSupported) {
      throw const ThermalPrinterSenderException(
        'La impresión por USB solo está disponible en la app de escritorio para Windows.',
      );
    }
    if (printerName.isEmpty) {
      throw const ThermalPrinterSenderException('No has seleccionado una impresora USB.');
    }

    final pPrinterName = printerName.toNativeUtf16();
    final phPrinter = calloc<IntPtr>();
    final defaults = calloc<win32.PRINTER_DEFAULTS>();
    try {
      defaults.ref
        ..pDatatype = nullptr
        ..pDevMode = nullptr
        ..DesiredAccess = _printerAccessUse;

      if (win32.OpenPrinter(pPrinterName, phPrinter, defaults) == 0) {
        throw ThermalPrinterSenderException(
          'No se pudo abrir la impresora "$printerName". Verifica que siga instalada y conectada.',
        );
      }

      final hPrinter = phPrinter.value;
      try {
        _writeRawJob(hPrinter, bytes);
      } finally {
        win32.ClosePrinter(hPrinter);
      }
    } finally {
      calloc.free(pPrinterName);
      calloc.free(phPrinter);
      calloc.free(defaults);
    }
  }

  void _writeRawJob(int hPrinter, List<int> bytes) {
    final docName = 'La Bomba - Recibo'.toNativeUtf16();
    final dataType = 'RAW'.toNativeUtf16();
    final docInfo = calloc<win32.DOC_INFO_1>();
    try {
      docInfo.ref
        ..pDocName = docName
        ..pOutputFile = nullptr
        ..pDatatype = dataType;

      if (win32.StartDocPrinter(hPrinter, 1, docInfo) == 0) {
        throw const ThermalPrinterSenderException('No se pudo iniciar el trabajo de impresión.');
      }

      try {
        if (win32.StartPagePrinter(hPrinter) == 0) {
          throw const ThermalPrinterSenderException('No se pudo iniciar la página de impresión.');
        }

        final buffer = calloc<Uint8>(bytes.length);
        final written = calloc<Uint32>();
        try {
          buffer.asTypedList(bytes.length).setAll(0, bytes);
          final ok = win32.WritePrinter(hPrinter, buffer.cast(), bytes.length, written);
          if (ok == 0 || written.value != bytes.length) {
            throw const ThermalPrinterSenderException('No se pudieron enviar todos los datos a la impresora.');
          }
        } finally {
          calloc.free(buffer);
          calloc.free(written);
          win32.EndPagePrinter(hPrinter);
        }
      } finally {
        win32.EndDocPrinter(hPrinter);
      }
    } finally {
      calloc.free(docInfo);
      calloc.free(docName);
      calloc.free(dataType);
    }
  }

  /// Lists the printers currently installed in Windows (local printers -
  /// which is how a USB thermal printer shows up once its driver is
  /// installed - plus network printer connections), so the settings
  /// screen can offer a picker instead of asking for an exact driver
  /// name. Empty on any platform other than Windows desktop.
  Future<List<String>> listInstalledPrinters() async {
    if (!isUsbSupported) return const [];

    const flags = win32.PRINTER_ENUM_LOCAL | win32.PRINTER_ENUM_CONNECTIONS;
    const level = 4;

    final pcbNeeded = calloc<Uint32>();
    final pcReturned = calloc<Uint32>();
    try {
      // First call with no buffer just to learn how many bytes we need.
      win32.EnumPrinters(flags, nullptr, level, nullptr, 0, pcbNeeded, pcReturned);
      final neededBytes = pcbNeeded.value;
      if (neededBytes == 0) return const [];

      final buffer = calloc<Uint8>(neededBytes);
      try {
        final ok = win32.EnumPrinters(flags, nullptr, level, buffer, neededBytes, pcbNeeded, pcReturned);
        if (ok == 0) return const [];

        final infos = buffer.cast<win32.PRINTER_INFO_4>();
        final names = <String>[];
        for (var i = 0; i < pcReturned.value; i++) {
          final name = infos[i].pPrinterName.toDartString();
          if (name.isNotEmpty) names.add(name);
        }
        return names;
      } finally {
        calloc.free(buffer);
      }
    } finally {
      calloc.free(pcbNeeded);
      calloc.free(pcReturned);
    }
  }
}
