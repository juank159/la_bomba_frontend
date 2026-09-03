import '../../../../app/core/services/printer_destination.dart';
import '../../../../app/core/services/receipt_template.dart';
import '../../../../app/core/services/thermal_printer_sender.dart';
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

/// Prints vegetable sale receipts to the same thermal printer used by the
/// invoicing (Facturación) module — reuses the destination (network or
/// USB) saved in PreferencesService, configured from the same "Impresora
/// Térmica" screen. Kept as its own service (not a shared PrinterService)
/// since the receipt layout is different (weight/unit lines, no IVA); the
/// actual "how do we reach the printer" logic lives in the shared
/// [ThermalPrinterSender].
abstract class VegetablePrinterService {
  Future<void> printSale(VegetableSale sale, {required PrinterDestination destination});
}

class EscPosVegetablePrinterService implements VegetablePrinterService {
  final ThermalPrinterSender _sender;

  const EscPosVegetablePrinterService(this._sender);

  @override
  Future<void> printSale(VegetableSale sale, {required PrinterDestination destination}) async {
    final bytes = await _buildReceiptBytes(sale);
    try {
      await _sender.send(bytes, destination);
    } on ThermalPrinterSenderException catch (e) {
      throw VegetablePrinterException(e.message);
    }
  }

  Future<List<int>> _buildReceiptBytes(VegetableSale sale) {
    return ReceiptTemplate.build(
      subtitle: 'Venta de Verduras',
      number: sale.formattedNumber,
      dateTime: sale.formattedCreatedAtWithTime,
      infoLines: ['Atendido por: ${sale.soldBy}', 'Pago: ${sale.paymentMethodName}'],
      items: sale.items
          .map((item) => ReceiptItemLine(
                description: item.description,
                quantityAndPriceLabel: item.pricingType.isWeight
                    ? '${item.quantityLabel} x ${NumberFormatter.formatCurrency(item.unitPrice)}/kg'
                    : '${item.quantityLabel} x ${NumberFormatter.formatCurrency(item.unitPrice)}',
                totalLabel: NumberFormatter.formatCurrency(item.total),
              ))
          .toList(),
      totalLabel: NumberFormatter.formatCurrency(sale.total),
    );
  }
}
