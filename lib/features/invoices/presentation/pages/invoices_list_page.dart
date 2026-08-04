// lib/features/invoices/presentation/pages/invoices_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../domain/entities/invoice.dart';
import '../controllers/invoices_controller.dart';

/// Invoices list page (Facturación) - shows all invoices with quick access
/// to create a new one via the POS-style checkout flow.
class InvoicesListPage extends StatefulWidget {
  const InvoicesListPage({super.key});

  @override
  State<InvoicesListPage> createState() => _InvoicesListPageState();
}

class _InvoicesListPageState extends State<InvoicesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<InvoicesController>().loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvoicesController>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Facturación'),
        elevation: 0,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.printerSettings),
            tooltip: 'Configurar impresora',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadInvoices(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createInvoice),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Factura'),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingInvoices.value && controller.invoices.isEmpty) {
            return const LoadingWidget();
          }

          if (controller.invoices.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: controller.loadInvoices,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConfig.paddingMedium),
              itemCount: controller.invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final invoice = controller.invoices[index];
                return _InvoiceCard(
                  invoice: invoice,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.invoiceDetail,
                    arguments: invoice.id,
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Get.theme.disabledColor),
            const SizedBox(height: 16),
            Text('No hay facturas todavía', style: Get.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Toca "Nueva Factura" para registrar tu primera venta',
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCancelled = invoice.isCancelled;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isCancelled
              ? Get.theme.colorScheme.error.withOpacity(0.1)
              : Get.theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(
            isCancelled ? Icons.cancel_outlined : Icons.receipt_long,
            color: isCancelled ? Get.theme.colorScheme.error : Get.theme.colorScheme.primary,
          ),
        ),
        title: Text(
          invoice.formattedNumber,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${invoice.client?.nombre ?? "Sin cliente"} · ${invoice.formattedCreatedAtWithTime}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormatter.formatCurrency(invoice.total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (isCancelled)
              Text(
                'Anulada',
                style: TextStyle(color: Get.theme.colorScheme.error, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
