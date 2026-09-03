// lib/app/core/services/receipt_template.dart

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// One printable line item on a receipt: what it was, the "qty x price"
/// label, and the line total.
class ReceiptItemLine {
  final String description;
  final String quantityAndPriceLabel;
  final String totalLabel;

  const ReceiptItemLine({
    required this.description,
    required this.quantityAndPriceLabel,
    required this.totalLabel,
  });
}

/// Builds the 80mm ESC/POS receipt bytes shared by every feature that
/// prints a sale (Facturación, Verduras, ...), so the printed design -
/// header, sizes, spacing - is defined once and stays identical across the
/// whole app instead of drifting as each feature copy-pastes its own
/// version. Only what's feature-specific (subtitle, extra info lines like
/// client/payment method, how each line item is labeled) is passed in.
class ReceiptTemplate {
  static Future<List<int>> build({
    required String subtitle,
    required String number,
    required String dateTime,
    List<String> infoLines = const [],
    required List<ReceiptItemLine> items,
    required String totalLabel,
    String footer = '¡Gracias por su compra!',
  }) async {
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
    bytes.addAll(generator.text(subtitle, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.hr());

    bytes.addAll(generator.text(
      number,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ));
    bytes.addAll(generator.text(dateTime, styles: const PosStyles(align: PosAlign.center)));
    for (final line in infoLines) {
      bytes.addAll(generator.text(line));
    }

    bytes.addAll(generator.hr());

    for (final item in items) {
      bytes.addAll(generator.text(item.description, styles: const PosStyles(bold: true)));
      bytes.addAll(generator.row([
        PosColumn(text: item.quantityAndPriceLabel, width: 7),
        PosColumn(text: item.totalLabel, width: 5, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }

    bytes.addAll(generator.hr());

    bytes.addAll(generator.row([
      PosColumn(text: 'TOTAL', width: 7, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
        text: totalLabel,
        width: 5,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]));

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(footer, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.feed(3));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
