// lib/app/core/services/printer_destination.dart

/// How the app reaches the physical thermal printer.
enum PrinterConnectionType { network, usb }

/// Describes where to send raw ESC/POS bytes for a receipt: either a
/// network printer (IP:port over TCP, port 9100 is the ESC/POS
/// convention) or a printer connected by USB and installed as a regular
/// Windows printer (identified by the exact name Windows gave it).
///
/// Built once from [PreferencesService] (see `getPrinterDestination`) so
/// every feature that prints a receipt - Facturación, Verduras, and any
/// future one - reads the exact same global printer configuration instead
/// of each keeping its own copy of the IP/port/printer name.
class PrinterDestination {
  final PrinterConnectionType type;
  final String ip;
  final int port;
  final String usbPrinterName;

  const PrinterDestination.network({required this.ip, this.port = 9100})
      : type = PrinterConnectionType.network,
        usbPrinterName = '';

  const PrinterDestination.usb({required this.usbPrinterName})
      : type = PrinterConnectionType.usb,
        ip = '',
        port = 9100;

  bool get isNetwork => type == PrinterConnectionType.network;
  bool get isUsb => type == PrinterConnectionType.usb;
}
