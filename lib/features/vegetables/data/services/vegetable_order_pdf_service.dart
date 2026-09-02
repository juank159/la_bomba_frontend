import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/vegetable_order.dart';

/// Generates and prints the PDF for a vegetable restock order ("pedido").
/// Deliberately simple - a title, the order number/date, and a table of
/// product/quantity/unit - no prices, no supplier, unlike the full Order
/// module's PDF.
class VegetableOrderPdfService {
  Future<Uint8List> generateOrderPdf(VegetableOrder order) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PEDIDO DE VERDURAS Y FRUTAS',
                style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColor.fromHex('#1976D2')),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                order.formattedNumber,
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                order.formattedCreatedAtWithTime,
                style: pw.TextStyle(font: font, fontSize: 11, color: PdfColor.fromHex('#666666')),
              ),
              pw.Text(
                'Hecho por: ${order.createdBy}',
                style: pw.TextStyle(font: font, fontSize: 11, color: PdfColor.fromHex('#666666')),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0')),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
                    children: [
                      _cell('PRODUCTO', fontBold, isHeader: true),
                      _cell('CANTIDAD', fontBold, isHeader: true),
                      _cell('UNIDAD', fontBold, isHeader: true),
                    ],
                  ),
                  ...order.items.map(
                    (item) => pw.TableRow(
                      children: [
                        _cell(item.description, font),
                        _cell(_formatQuantity(item.quantity), font),
                        _cell(item.unit.displayName, font),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Total de productos: ${order.items.length}',
                style: pw.TextStyle(font: fontBold, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _cell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 11,
          color: isHeader ? PdfColor.fromHex('#333333') : PdfColor.fromHex('#222222'),
        ),
      ),
    );
  }

  String _formatQuantity(double quantity) {
    return quantity == quantity.roundToDouble() ? quantity.toStringAsFixed(0) : quantity.toStringAsFixed(3);
  }

  /// Opens the system print dialog / preview for [order]'s PDF. Works on
  /// every platform (Web, desktop, mobile) via the `printing` package -
  /// no platform-specific code needed here, unlike the thermal printer.
  Future<void> printOrder(VegetableOrder order) async {
    final bytes = await generateOrderPdf(order);
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'pedido_${order.formattedNumber}');
  }

  /// Opens the native share/save sheet for [order]'s PDF.
  Future<void> shareOrderPdf(VegetableOrder order) async {
    final bytes = await generateOrderPdf(order);
    await Printing.sharePdf(bytes: bytes, filename: 'pedido_${order.formattedNumber}.pdf');
  }
}
