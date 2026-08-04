import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../../app/core/utils/number_formatter.dart';
import '../../domain/entities/invoice.dart';

/// Thrown when printing is attempted on a platform without raw TCP socket
/// support (Flutter Web) or when the printer connection fails.
class PrinterException implements Exception {
  final String message;
  const PrinterException(this.message);

  @override
  String toString() => message;
}

/// Abstract contract for thermal receipt printing, kept independent from
/// the concrete ESC/POS + TCP socket implementation (SOLID: dependency
/// inversion so the presentation layer never talks to dart:io directly).
abstract class PrinterService {
  /// Prints a formatted 80mm receipt for [invoice] to the network printer
  /// at [ip]:[port]. Throws [PrinterException] on failure.
  Future<void> printInvoice(
    Invoice invoice, {
    required String ip,
    int port = 9100,
  });

  /// Sends a short test ticket to verify the printer is reachable and
  /// configured correctly. Returns true on success.
  Future<bool> testConnection({required String ip, int port = 9100});
}

/// ESC/POS implementation that talks to a network thermal printer over a
/// raw TCP socket (standard port 9100). Only available on platforms with
/// dart:io socket support - Android, iOS, macOS, Windows and Linux. Not
/// available on Flutter Web, since browsers cannot open raw TCP sockets.
class EscPosPrinterService implements PrinterService {
  static const Duration _connectTimeout = Duration(seconds: 5);

  @override
  Future<void> printInvoice(
    Invoice invoice, {
    required String ip,
    int port = 9100,
  }) async {
    _assertPlatformSupported();

    final bytes = await _buildReceiptBytes(invoice);
    await _sendBytes(ip, port, bytes);
  }

  @override
  Future<bool> testConnection({required String ip, int port = 9100}) async {
    _assertPlatformSupported();

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      final bytes = <int>[
        ...generator.text(
          'La Bomba - Prueba de impresora',
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        ...generator.text(
          'Conexión exitosa',
          styles: const PosStyles(align: PosAlign.center),
        ),
        ...generator.feed(2),
        ...generator.cut(),
      ];

      await _sendBytes(ip, port, bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _assertPlatformSupported() {
    if (kIsWeb) {
      throw const PrinterException(
        'La impresión térmica por red no está disponible en la versión web. '
        'Usa la app móvil o de escritorio para imprimir recibos.',
      );
    }
  }

  Future<void> _sendBytes(String ip, int port, List<int> bytes) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: _connectTimeout);
      socket.add(bytes);
      await socket.flush();
    } on SocketException catch (e) {
      throw PrinterException(
        'No se pudo conectar a la impresora en $ip:$port. Verifica la IP y que '
        'la impresora esté encendida y en la misma red. (${e.message})',
      );
    } catch (e) {
      throw PrinterException('Error al imprimir: ${e.toString()}');
    } finally {
      await socket?.close();
    }
  }

  Future<List<int>> _buildReceiptBytes(Invoice invoice) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text(
      'LA BOMBA',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.text(
      'Factura de Venta',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());

    bytes.addAll(generator.text(
      invoice.formattedNumber,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ));
    bytes.addAll(generator.text(
      invoice.formattedCreatedAtWithTime,
      styles: const PosStyles(align: PosAlign.center),
    ));

    if (invoice.client != null) {
      bytes.addAll(generator.text('Cliente: ${invoice.client!.nombre}'));
    }
    bytes.addAll(generator.text(
      'Atendido por: ${invoice.createdBy}',
    ));
    if (invoice.paymentMethod != null) {
      bytes.addAll(generator.text('Pago: ${invoice.paymentMethod!.name}'));
    }

    bytes.addAll(generator.hr());

    for (final item in invoice.items) {
      bytes.addAll(generator.text(item.description, styles: const PosStyles(bold: true)));
      bytes.addAll(generator.row([
        PosColumn(
          text: '${item.quantity} x ${NumberFormatter.formatCurrency(item.unitPrice)}',
          width: 7,
        ),
        PosColumn(
          text: NumberFormatter.formatCurrency(item.total),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.hr());

    bytes.addAll(generator.row([
      PosColumn(text: 'Subtotal', width: 7),
      PosColumn(
        text: NumberFormatter.formatCurrency(invoice.subtotal),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
    bytes.addAll(generator.row([
      PosColumn(text: 'IVA', width: 7),
      PosColumn(
        text: NumberFormatter.formatCurrency(invoice.tax),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));
    bytes.addAll(generator.row([
      PosColumn(text: 'TOTAL', width: 7, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: NumberFormatter.formatCurrency(invoice.total),
        width: 5,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]));

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      '¡Gracias por su compra!',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.feed(3));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
