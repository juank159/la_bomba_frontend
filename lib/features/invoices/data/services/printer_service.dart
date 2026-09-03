import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../../app/core/services/printer_destination.dart';
import '../../../../app/core/services/receipt_template.dart';
import '../../../../app/core/services/thermal_printer_sender.dart';
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
/// the concrete ESC/POS + transport implementation (SOLID: dependency
/// inversion so the presentation layer never talks to the transport
/// directly).
abstract class PrinterService {
  /// Prints a formatted 80mm receipt for [invoice] to [destination]
  /// (network or USB). Throws [PrinterException] on failure.
  Future<void> printInvoice(Invoice invoice, {required PrinterDestination destination});

  /// Sends a short test ticket to verify the printer is reachable and
  /// configured correctly. Returns true on success.
  Future<bool> testConnection({required PrinterDestination destination});
}

/// ESC/POS implementation. Builds the receipt bytes and hands them to the
/// shared [ThermalPrinterSender], which knows how to actually reach the
/// printer (network socket or Windows USB) - this class only cares about
/// what the receipt looks like.
class EscPosPrinterService implements PrinterService {
  final ThermalPrinterSender _sender;

  const EscPosPrinterService(this._sender);

  @override
  Future<void> printInvoice(Invoice invoice, {required PrinterDestination destination}) async {
    final bytes = await _buildReceiptBytes(invoice);
    await _send(bytes, destination);
  }

  @override
  Future<bool> testConnection({required PrinterDestination destination}) async {
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

      await _send(bytes, destination);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _send(List<int> bytes, PrinterDestination destination) async {
    try {
      await _sender.send(bytes, destination);
    } on ThermalPrinterSenderException catch (e) {
      throw PrinterException(e.message);
    }
  }

  Future<List<int>> _buildReceiptBytes(Invoice invoice) {
    return ReceiptTemplate.build(
      subtitle: 'Factura de Venta',
      number: invoice.formattedNumber,
      dateTime: invoice.formattedCreatedAtWithTime,
      infoLines: [
        if (invoice.client != null) 'Cliente: ${invoice.client!.nombre}',
        'Atendido por: ${invoice.createdBy}',
        if (invoice.paymentMethod != null) 'Pago: ${invoice.paymentMethod!.name}',
      ],
      items: invoice.items
          .map((item) => ReceiptItemLine(
                description: item.description,
                quantityAndPriceLabel: '${item.quantity} x ${NumberFormatter.formatCurrency(item.unitPrice)}',
                totalLabel: NumberFormatter.formatCurrency(item.total),
              ))
          .toList(),
      totalLabel: NumberFormatter.formatCurrency(invoice.total),
    );
  }
}
