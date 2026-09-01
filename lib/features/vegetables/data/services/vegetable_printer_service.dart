import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../../app/core/utils/number_formatter.dart';
import '../../domain/entities/vegetable_sale.dart';

/// Thrown when printing is attempted on a platform without raw TCP socket
/// support (Flutter Web) or when the printer connection fails.
class VegetablePrinterException implements Exception {
  final String message;
  const VegetablePrinterException(this.message);

  @override
  String toString() => message;
}

/// Prints vegetable sale receipts to the same network ESC/POS thermal
/// printer used by the invoicing (Facturación) module — reuses the IP/port
/// saved in PreferencesService, configured from the same "Impresora
/// Térmica" screen. Kept as its own service (not a shared PrinterService)
/// since the receipt layout is different (weight/unit lines, no IVA).
abstract class VegetablePrinterService {
  Future<void> printSale(VegetableSale sale, {required String ip, int port = 9100});
}

class EscPosVegetablePrinterService implements VegetablePrinterService {
  static const Duration _connectTimeout = Duration(seconds: 5);

  @override
  Future<void> printSale(VegetableSale sale, {required String ip, int port = 9100}) async {
    if (kIsWeb) {
      throw const VegetablePrinterException(
        'La impresión térmica por red no está disponible en la versión web. '
        'Usa la app de escritorio para imprimir recibos.',
      );
    }

    final bytes = await _buildReceiptBytes(sale);

    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: _connectTimeout);
      socket.add(bytes);
      await socket.flush();
    } on SocketException catch (e) {
      throw VegetablePrinterException(
        'No se pudo conectar a la impresora en $ip:$port. Verifica la IP y que '
        'la impresora esté encendida y en la misma red. (${e.message})',
      );
    } catch (e) {
      throw VegetablePrinterException('Error al imprimir: ${e.toString()}');
    } finally {
      await socket?.close();
    }
  }

  Future<List<int>> _buildReceiptBytes(VegetableSale sale) async {
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
      'Venta de Verduras',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());

    bytes.addAll(generator.text(
      sale.formattedNumber,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ));
    bytes.addAll(generator.text(
      sale.formattedCreatedAtWithTime,
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.text('Atendido por: ${sale.soldBy}'));

    bytes.addAll(generator.hr());

    for (final item in sale.items) {
      bytes.addAll(generator.text(item.description, styles: const PosStyles(bold: true)));
      bytes.addAll(generator.row([
        PosColumn(
          text: item.pricingType.isWeight
              ? '${item.quantityLabel} x ${NumberFormatter.formatCurrency(item.unitPrice)}/kg'
              : '${item.quantityLabel} x ${NumberFormatter.formatCurrency(item.unitPrice)}',
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

    // Las verduras no llevan IVA: se imprime directo el TOTAL.
    bytes.addAll(generator.row([
      PosColumn(text: 'TOTAL', width: 7, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: NumberFormatter.formatCurrency(sale.total),
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
