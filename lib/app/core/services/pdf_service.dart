import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../features/orders/domain/entities/order.dart' as order_entity;

class PdfService {
  /// Generate PDF document for an order
  Future<Uint8List> generateOrderPdf(order_entity.Order order) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(order, fontBold, font),
            pw.SizedBox(height: 20),

            // Order Information
            _buildOrderInfo(order, fontBold, font),
            pw.SizedBox(height: 20),

            // Items Table
            _buildItemsTable(order, fontBold, font),
            pw.SizedBox(height: 20),

            // Footer
            _buildFooter(fontBold, font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Build PDF header
  pw.Widget _buildHeader(
    order_entity.Order order,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E3F2FD'),
        border: pw.Border.all(color: PdfColor.fromHex('#2196F3'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PEDIDO ABASTOS LA BOMBA',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  color: PdfColor.fromHex('#1976D2'),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: order.status == order_entity.OrderStatus.completed
                      ? PdfColor.fromHex('#4CAF50')
                      : PdfColor.fromHex('#FF9800'),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Text(
                  order.status.displayName.toUpperCase(),
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // pw.Text(
          //   'ID: ${order.id}',
          //   style: pw.TextStyle(
          //     font: font,
          //     fontSize: 12,
          //     color: PdfColor.fromHex('#666666'),
          //   ),
          // ),
        ],
      ),
    );
  }

  /// Build order information section
  pw.Widget _buildOrderInfo(
    order_entity.Order order,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL PEDIDO',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 16,
              color: PdfColor.fromHex('#333333'),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Descripción:',
                      order.description,
                      fontBold,
                      font,
                    ),
                    if (order.hasProvider)
                      _buildInfoRow(
                        'Proveedor:',
                        order.provider!,
                        fontBold,
                        font,
                      ),
                    _buildInfoRow(
                      'Fecha de creación:',
                      order.formattedCreatedAt,
                      fontBold,
                      font,
                    ),
                    if (order.createdBy != null)
                      _buildInfoRow(
                        'Creado por:',
                        order.createdBy!.displayName,
                        fontBold,
                        font,
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Total artículos:',
                      '${order.totalItems}',
                      fontBold,
                      font,
                    ),
                    // _buildInfoRow(
                    //   'Cantidad existente:',
                    //   '${order.totalExistingQuantity}',
                    //   fontBold,
                    //   font,
                    // ),
                    if (order.totalRequestedQuantity > 0)
                      _buildInfoRow(
                        'Cantidad solicitada:',
                        '${order.totalRequestedQuantity}',
                        fontBold,
                        font,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build info row
  pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
                color: PdfColor.fromHex('#666666'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: PdfColor.fromHex('#333333'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build items table
  pw.Widget _buildItemsTable(
    order_entity.Order order,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ARTÍCULOS DEL PEDIDO',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 16,
            color: PdfColor.fromHex('#333333'),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0')),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Producto
            1: const pw.FlexColumnWidth(1.5), // Unidad
            2: const pw.FlexColumnWidth(1), // Existente
            3: const pw.FlexColumnWidth(1), // Solicitado
            4: const pw.FlexColumnWidth(1), // Diferencia
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
              children: [
                _buildTableCell('PRODUCTO', fontBold, isHeader: true),
                _buildTableCell('UNIDAD', fontBold, isHeader: true),
                _buildTableCell('EXISTENTE', fontBold, isHeader: true),
                _buildTableCell('SOLICITADO', fontBold, isHeader: true),
                _buildTableCell('DIFERENCIA', fontBold, isHeader: true),
              ],
            ),
            // Data rows
            ...order.items
                .map(
                  (item) => pw.TableRow(
                    children: [
                      _buildTableCell(item.productDescription, font),
                      _buildTableCell(
                        item.measurementUnit.shortDisplayName,
                        font,
                      ),
                      _buildTableCell('${item.existingQuantity}', font),
                      _buildTableCell('${item.requestedQuantity ?? 0}', font),
                      _buildTableCell(
                        item.hasQuantityDifference
                            ? '${item.isQuantityIncreasing ? '+' : '-'}${item.quantityDifference.abs()}'
                            : '-',
                        font,
                        color: item.hasQuantityDifference
                            ? (item.isQuantityIncreasing
                                  ? PdfColor.fromHex('#4CAF50')
                                  : PdfColor.fromHex('#F44336'))
                            : null,
                      ),
                    ],
                  ),
                )
                .toList(),
          ],
        ),
      ],
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          color:
              color ??
              (isHeader
                  ? PdfColor.fromHex('#333333')
                  : PdfColor.fromHex('#666666')),
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  /// Build footer
  pw.Widget _buildFooter(pw.Font fontBold, pw.Font font) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F9F9F9'),
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Sistema de Pedidos',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfColor.fromHex('#1976D2'),
                ),
              ),
              pw.Text(
                'Documento generado automáticamente',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColor.fromHex('#666666'),
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generado el:',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColor.fromHex('#666666'),
                ),
              ),
              pw.Text(
                dateFormat.format(now),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: PdfColor.fromHex('#333333'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Share PDF document
  Future<void> shareOrderPdf(order_entity.Order order) async {
    try {
      final pdfData = await generateOrderPdf(order);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/pedido_${order.id}.pdf');

      // Write PDF to file
      await file.writeAsBytes(pdfData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Pedido - ${order.description}',
        text: 'Adjunto el pedido "${order.description}" en formato PDF.',
      );
    } catch (e) {
      throw Exception('Error al compartir PDF: $e');
    }
  }

  /// Print PDF document
  Future<void> printOrderPdf(order_entity.Order order) async {
    try {
      final pdfData = await generateOrderPdf(order);

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'pedido_${order.id}',
      );
    } catch (e) {
      throw Exception('Error al imprimir PDF: $e');
    }
  }

  /// Save PDF to device
  Future<String> saveOrderPdf(order_entity.Order order) async {
    try {
      final pdfData = await generateOrderPdf(order);

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pedido_${order.id}.pdf');

      // Write PDF to file
      await file.writeAsBytes(pdfData);

      return file.path;
    } catch (e) {
      throw Exception('Error al guardar PDF: $e');
    }
  }
}
