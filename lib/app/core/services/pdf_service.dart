import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../features/orders/domain/entities/order.dart' as order_entity;
import '../../../features/orders/domain/entities/order_item.dart';

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
            0: const pw.FlexColumnWidth(4), // Producto
            1: const pw.FlexColumnWidth(2), // Unidad
            2: const pw.FlexColumnWidth(1.5), // Solicitado
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
              children: [
                _buildTableCell('PRODUCTO', fontBold, isHeader: true),
                _buildTableCell('UNIDAD', fontBold, isHeader: true),
                _buildTableCell('SOLICITADO', fontBold, isHeader: true),
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
                      _buildTableCell('${item.requestedQuantity ?? 0}', font),
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

  /// Generate PDF document for items of a specific supplier
  Future<Uint8List> generateOrderPdfBySupplier(
    order_entity.Order order,
    String supplierName,
    List<OrderItem> items,
  ) async {
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
            _buildHeaderForSupplier(order, supplierName, fontBold, font),
            pw.SizedBox(height: 20),

            // Order Information
            _buildOrderInfoForSupplier(order, supplierName, items, fontBold, font),
            pw.SizedBox(height: 20),

            // Items Table
            _buildItemsTableForSupplier(items, fontBold, font),
            pw.SizedBox(height: 20),

            // Footer
            _buildFooter(fontBold, font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Build PDF header for supplier-specific document
  pw.Widget _buildHeaderForSupplier(
    order_entity.Order order,
    String supplierName,
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
          pw.Text(
            'PEDIDO ABASTOS LA BOMBA',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 24,
              color: PdfColor.fromHex('#1976D2'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'PROVEEDOR: $supplierName',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: PdfColor.fromHex('#333333'),
                  ),
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
        ],
      ),
    );
  }

  /// Build order information section for supplier
  pw.Widget _buildOrderInfoForSupplier(
    order_entity.Order order,
    String supplierName,
    List<OrderItem> items,
    pw.Font fontBold,
    pw.Font font,
  ) {
    double totalRequestedQty = 0;
    for (var item in items) {
      totalRequestedQty += item.requestedQuantity ?? 0;
    }

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
                      'Productos:',
                      '${items.length}',
                      fontBold,
                      font,
                    ),
                    if (totalRequestedQty > 0)
                      _buildInfoRow(
                        'Cantidad solicitada:',
                        '$totalRequestedQty',
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

  /// Build items table for supplier
  pw.Widget _buildItemsTableForSupplier(
    List<OrderItem> items,
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
            0: const pw.FlexColumnWidth(4), // Producto
            1: const pw.FlexColumnWidth(2), // Unidad
            2: const pw.FlexColumnWidth(1.5), // Solicitado
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
              children: [
                _buildTableCell('PRODUCTO', fontBold, isHeader: true),
                _buildTableCell('UNIDAD', fontBold, isHeader: true),
                _buildTableCell('SOLICITADO', fontBold, isHeader: true),
              ],
            ),
            // Data rows
            ...items
                .map(
                  (OrderItem item) => pw.TableRow(
                    children: [
                      _buildTableCell(item.productDescription, font),
                      _buildTableCell(
                        item.measurementUnit.shortDisplayName,
                        font,
                      ),
                      _buildTableCell('${item.requestedQuantity ?? 0}', font),
                    ],
                  ),
                )
                .toList(),
          ],
        ),
      ],
    );
  }

  /// Share multiple PDFs grouped by supplier
  Future<void> shareOrderPdfsBySupplier(order_entity.Order order) async {
    try {
      // Group items by supplier
      final Map<String, List<OrderItem>> groupedItems = {};

      for (var item in order.items) {
        final supplierKey = item.supplier?.nombre ?? 'Sin Asignar';
        if (!groupedItems.containsKey(supplierKey)) {
          groupedItems[supplierKey] = [];
        }
        groupedItems[supplierKey]!.add(item);
      }

      // Generate PDF for each supplier
      final List<XFile> pdfFiles = [];
      final directory = await getTemporaryDirectory();

      for (var entry in groupedItems.entries) {
        final supplierName = entry.key;
        final items = entry.value;

        // Generate PDF
        final pdfData = await generateOrderPdfBySupplier(order, supplierName, items);

        // Save to temporary file
        final sanitizedName = supplierName.replaceAll(RegExp(r'[^\w\s-]'), '');
        final file = File('${directory.path}/pedido_${order.id}_$sanitizedName.pdf');
        await file.writeAsBytes(pdfData);

        pdfFiles.add(XFile(file.path));
      }

      // Share all PDFs
      await Share.shareXFiles(
        pdfFiles,
        subject: 'Pedidos por Proveedor - ${order.description}',
        text: 'Adjunto los pedidos agrupados por proveedor para "${order.description}".',
      );
    } catch (e) {
      throw Exception('Error al compartir PDFs por proveedor: $e');
    }
  }

  /// Get list of suppliers in the order
  Map<String, List<OrderItem>> getSupplierGroups(order_entity.Order order) {
    final Map<String, List<OrderItem>> groupedItems = {};

    for (var item in order.items) {
      final supplierKey = item.supplier?.nombre ?? 'Sin Asignar';
      if (!groupedItems.containsKey(supplierKey)) {
        groupedItems[supplierKey] = [];
      }
      groupedItems[supplierKey]!.add(item);
    }

    return groupedItems;
  }

  /// Share PDF for a specific supplier
  Future<void> shareOrderPdfForSupplier(
    order_entity.Order order,
    String supplierName,
  ) async {
    try {
      // Get items for this supplier
      final groupedItems = getSupplierGroups(order);
      final items = groupedItems[supplierName];

      if (items == null || items.isEmpty) {
        throw Exception('No se encontraron artículos para el proveedor $supplierName');
      }

      // Generate PDF for this supplier
      final pdfData = await generateOrderPdfBySupplier(order, supplierName, items);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final sanitizedName = supplierName.replaceAll(RegExp(r'[^\w\s-]'), '');
      final file = File('${directory.path}/pedido_${order.id}_$sanitizedName.pdf');

      // Write PDF to file
      await file.writeAsBytes(pdfData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Pedido $supplierName - ${order.description}',
        text: 'Adjunto el pedido para $supplierName: "${order.description}".',
      );
    } catch (e) {
      throw Exception('Error al compartir PDF del proveedor: $e');
    }
  }

  /// Share order PDF (single or multiple based on whether order has general supplier)
  /// NOTE: This method is deprecated. Use shareOrderPdf or show supplier selection dialog for mixed orders.
  Future<void> shareOrderPdfSmart(order_entity.Order order) async {
    if (order.hasProvider) {
      // Order has a general supplier, share single PDF
      await shareOrderPdf(order);
    } else {
      // Order has no general supplier, share multiple PDFs grouped by supplier
      await shareOrderPdfsBySupplier(order);
    }
  }
}
