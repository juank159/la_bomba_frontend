// lib/app/core/services/thermal_printer_sender_web.dart

import 'printer_destination.dart';
import 'thermal_printer_sender.dart';

/// Web stub for [ThermalPrinterSender]: un navegador no puede abrir un
/// socket TCP crudo ni hablar con el Print Spooler de Windows, así que
/// cada operación reporta eso claramente en vez de estar disponible. La
/// implementación real (thermal_printer_sender_io.dart) solo compila fuera
/// de la web.
class ThermalPrinterSender {
  bool get isUsbSupported => false;

  Future<void> send(List<int> bytes, PrinterDestination destination) async {
    throw const ThermalPrinterSenderException(
      'La impresión térmica no está disponible en la versión web.',
    );
  }

  Future<List<String>> listInstalledPrinters() async => const [];
}
