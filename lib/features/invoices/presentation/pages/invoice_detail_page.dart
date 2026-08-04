// lib/features/invoices/presentation/pages/invoice_detail_page.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/services/preferences_service.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../data/services/printer_service.dart';
import '../../domain/entities/invoice.dart';
import '../controllers/invoices_controller.dart';

/// Detail page for a single invoice: line items, totals, client, payment
/// method, plus cancel and print (ESC/POS thermal receipt) actions.
class InvoiceDetailPage extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  final PrinterService _printerService = getIt<PrinterService>();
  final PreferencesService _preferencesService = getIt<PreferencesService>();
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<InvoicesController>().loadInvoiceById(widget.invoiceId);
    });
  }

  Future<void> _confirmCancel(BuildContext context, Invoice invoice) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Anular factura'),
        content: Text(
          '¿Seguro que deseas anular la factura ${invoice.formattedNumber}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            style: TextButton.styleFrom(foregroundColor: Get.theme.colorScheme.error),
            child: const Text('Sí, anular'),
          ),
        ],
      ),
    );

    if (result == true) {
      await Get.find<InvoicesController>().cancelInvoice(invoice.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvoicesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Factura'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Obx(() {
            final invoice = controller.selectedInvoice.value;
            if (invoice == null || invoice.isCancelled) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Anular factura',
              onPressed: () => _confirmCancel(context, invoice),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingInvoiceDetail.value) {
            return const LoadingWidget();
          }

          final invoice = controller.selectedInvoice.value;
          if (invoice == null) {
            return const Center(child: Text('Factura no encontrada'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConfig.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(invoice),
                const SizedBox(height: AppConfig.paddingMedium),
                _buildInfoCard(invoice),
                const SizedBox(height: AppConfig.paddingMedium),
                _buildItemsCard(invoice),
                const SizedBox(height: AppConfig.paddingMedium),
                _buildTotalsCard(invoice),
                const SizedBox(height: AppConfig.paddingMedium),
                _buildPrintButton(context, invoice),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(Invoice invoice) {
    final isCancelled = invoice.isCancelled;
    return Row(
      children: [
        Expanded(
          child: Text(
            invoice.formattedNumber,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isCancelled
                ? Get.theme.colorScheme.error.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            invoice.status.displayName,
            style: TextStyle(
              color: isCancelled ? Get.theme.colorScheme.error : Colors.green[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Invoice invoice) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(Icons.calendar_today, invoice.formattedCreatedAtWithTime),
            _infoRow(Icons.person_outline, invoice.client?.nombre ?? 'Sin cliente asociado'),
            _infoRow(
              Icons.payments_outlined,
              invoice.paymentMethod != null
                  ? '${invoice.paymentMethod!.displayIcon} ${invoice.paymentMethod!.name}'
                  : 'Método de pago no disponible',
            ),
            _infoRow(Icons.badge_outlined, 'Registrada por ${invoice.createdBy}'),
            if (invoice.isCancelled && invoice.cancelledBy != null)
              _infoRow(
                Icons.cancel_outlined,
                'Anulada por ${invoice.cancelledBy}',
                color: Get.theme.colorScheme.error,
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Get.theme.disabledColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Invoice invoice) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Productos', style: Get.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...invoice.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text('${item.quantity}x ${item.description}'),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        NumberFormatter.formatCurrency(item.total),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(Invoice invoice) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingMedium),
        child: Column(
          children: [
            _totalsRow('Subtotal', invoice.subtotal),
            _totalsRow('IVA', invoice.tax),
            const Divider(),
            _totalsRow('Total', invoice.total, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _totalsRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context, Invoice invoice) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La impresión no está disponible en la versión web. Usa la app móvil o de escritorio.',
          ),
        ),
      );
      return;
    }

    final ip = _preferencesService.getPrinterIp();
    if (ip == null || ip.trim().isEmpty) {
      final configured = await Navigator.of(context).pushNamed(AppRoutes.printerSettings);
      if (configured == null) return;
    }

    final savedIp = _preferencesService.getPrinterIp();
    if (savedIp == null || savedIp.trim().isEmpty) return;

    setState(() => _isPrinting = true);
    try {
      await _printerService.printInvoice(
        invoice,
        ip: savedIp,
        port: _preferencesService.getPrinterPort(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recibo enviado a la impresora')),
      );
    } on PrinterException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Widget _buildPrintButton(BuildContext context, Invoice invoice) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isPrinting ? null : () => _handlePrint(context, invoice),
            icon: _isPrinting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            label: const Text('Imprimir recibo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Configurar impresora',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.printerSettings),
        ),
      ],
    );
  }
}
