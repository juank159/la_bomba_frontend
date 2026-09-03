// lib/features/invoices/presentation/pages/create_invoice_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../credits/domain/entities/payment_method.dart';
import '../../../orders/presentation/widgets/barcode_scanner_overlay.dart';
import '../controllers/invoices_controller.dart';
import '../utils/invoice_print_helper.dart';
import '../../../../app/config/routes.dart';

/// POS-style page to build and check out a new invoice: scan or search
/// products, optionally attach a client, pick a payment method and charge.
class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final TextEditingController _productSearchController = TextEditingController();
  final TextEditingController _clientSearchController = TextEditingController();
  final RxList<Product> _productResults = <Product>[].obs;
  final RxBool _isSearchingProducts = false.obs;
  final RxBool _showClientSearch = false.obs;
  final ScrollController _cartScrollController = ScrollController();
  StreamSubscription<List<InvoiceCartLine>>? _cartSubscription;
  int _lastCartLength = 0;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    // Cuando se agrega un producto NUEVO (no cuando solo cambia la cantidad
    // de uno existente), el carrito puede crecer más allá de lo visible en
    // pantalla. Escuchamos el carrito reactivo del controlador y hacemos
    // scroll automático al final para que el producto recién agregado
    // siempre quede visible sin que el usuario tenga que buscarlo.
    final controller = Get.find<InvoicesController>();
    _lastCartLength = controller.cart.length;
    _cartSubscription = controller.cart.listen((items) {
      if (items.length > _lastCartLength) {
        _scrollCartToBottom();
      }
      _lastCartLength = items.length;
    });
  }

  void _scrollCartToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cartScrollController.hasClients) return;
      _cartScrollController.animateTo(
        _cartScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _clientSearchController.dispose();
    _cartScrollController.dispose();
    _cartSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onProductSearchChanged(String query) async {
    final controller = Get.find<InvoicesController>();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _productResults.clear();
      return;
    }

    _isSearchingProducts.value = true;
    final result = await controller.getProductsUseCase(
      GetProductsParams(page: 0, limit: 20, search: trimmed),
    );
    result.fold(
      (failure) => _productResults.clear(),
      (products) => _productResults.assignAll(products),
    );
    _isSearchingProducts.value = false;
  }

  /// Lista de (etiqueta, precio) para los precios que realmente tiene
  /// configurados [product] (precioA siempre, precioB/precioC si existen).
  List<(String, double)> _priceOptionsFor(Product product) {
    return [
      ('Público', product.precioA),
      if (product.precioB != null) ('Mayorista', product.precioB!),
      if (product.precioC != null) ('Super Mayorista', product.precioC!),
    ];
  }

  /// Diálogo compartido para elegir uno de los precios de [product], con
  /// [initialSelection] preseleccionado. Se usa tanto al agregar un
  /// producto nuevo como al cambiar el precio de una línea ya agregada.
  /// Devuelve null si el usuario cancela.
  Future<double?> _pickPrice(
    Product product,
    double initialSelection, {
    required String confirmLabel,
  }) {
    double selected = initialSelection;
    return Get.dialog<double>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(product.description),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: _priceOptionsFor(product).map((option) {
                final (label, price) = option;
                return RadioListTile<double>(
                  value: price,
                  groupValue: selected,
                  title: Text(label),
                  subtitle: Text(NumberFormatter.formatCurrency(price)),
                  onChanged: (value) => setDialogState(() => selected = value!),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(selected),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Agrega [product] al carrito. Si el producto tiene más de un precio
  /// (precioB y/o precioC además del precioA obligatorio), primero
  /// pregunta cuál usar - con el precio público (precioA) preseleccionado
  /// por defecto, para no interrumpir el caso común de un solo precio.
  Future<void> _addProductWithPricePicker(InvoicesController controller, Product product) async {
    if (product.precioB == null && product.precioC == null) {
      controller.addProductToCart(product, unitPrice: product.precioA);
      return;
    }

    final chosen = await _pickPrice(product, product.precioA, confirmLabel: 'Agregar');
    if (chosen == null) return;
    controller.addProductToCart(product, unitPrice: chosen);
  }

  /// Cambia el precio de una línea ya agregada al carrito (sin tocar su
  /// cantidad). Si al cambiarlo queda al mismo precio que otra línea del
  /// mismo producto, el controller las fusiona en una sola.
  Future<void> _editLinePrice(InvoicesController controller, InvoiceCartLine line) async {
    if (line.product.precioB == null && line.product.precioC == null) return;

    final chosen = await _pickPrice(line.product, line.unitPrice, confirmLabel: 'Cambiar precio');
    if (chosen == null || chosen == line.unitPrice) return;
    controller.updateCartLineUnitPrice(line, chosen);
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final controller = Get.find<InvoicesController>();
    if (controller.cartIsEmpty) return true;

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Descartar factura?'),
        content: Text(
          'Tienes ${controller.cart.length} producto(s) en el carrito. Si sales ahora se perderán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            style: TextButton.styleFrom(foregroundColor: Get.theme.colorScheme.error),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvoicesController>();

    return WillPopScope(
      onWillPop: () => _confirmDiscard(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva Factura'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _confirmDiscard(context);
              // Navigator nativo (no Get.back()): evita el bug de overlay
              // corrupto de GetX documentado en el resto de la app.
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _cartScrollController,
                      padding: const EdgeInsets.all(AppConfig.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductSearchSection(controller),
                          const SizedBox(height: AppConfig.paddingMedium),
                          _buildClientSection(controller),
                          const SizedBox(height: AppConfig.paddingMedium),
                          _buildCartSection(controller),
                        ],
                      ),
                    ),
                  ),
                  _buildCheckoutBar(controller),
                ],
              ),

              // Barcode Scanner Overlay
              Obx(() {
                if (controller.isScanningBarcode.value) {
                  return BarcodeScannerOverlay(
                    onBarcodeDetected: controller.handleBarcodeScanned,
                    onClose: () => controller.isScanningBarcode.value = false,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSearchSection(InvoicesController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _productSearchController,
          decoration: InputDecoration(
            labelText: 'Buscar producto por nombre o código',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Escanear código de barras',
              onPressed: () => controller.isScanningBarcode.value = true,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
          ),
          onChanged: _onProductSearchChanged,
        ),
        Obx(() {
          if (_isSearchingProducts.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_productResults.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              border: Border.all(color: Get.theme.dividerColor),
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _productResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = _productResults[index];
                return ListTile(
                  title: Text(product.description),
                  subtitle: Text(
                    '${product.barcode} · ${NumberFormatter.formatCurrency(product.precioA)}',
                  ),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () {
                    _productSearchController.clear();
                    _productResults.clear();
                    FocusScope.of(context).unfocus();
                    _addProductWithPricePicker(controller, product);
                  },
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildClientSection(InvoicesController controller) {
    return Obx(() {
      final client = controller.selectedClient.value;

      if (client != null) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(client.nombre),
            subtitle: Text(client.celular ?? 'Sin teléfono'),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => controller.selectClient(null),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (!_showClientSearch.value) {
              return OutlinedButton.icon(
                onPressed: () => _showClientSearch.value = true,
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Asociar cliente (opcional)'),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _clientSearchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Buscar cliente por nombre',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _showClientSearch.value = false;
                        _clientSearchController.clear();
                        controller.clients.clear();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    ),
                  ),
                  onChanged: controller.searchClients,
                ),
                Obx(() {
                  if (controller.clients.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      border: Border.all(color: Get.theme.dividerColor),
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: controller.clients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = controller.clients[index];
                        return ListTile(
                          title: Text(c.nombre),
                          subtitle: Text(c.celular ?? ''),
                          onTap: () {
                            controller.selectClient(c);
                            _showClientSearch.value = false;
                            _clientSearchController.clear();
                            controller.clients.clear();
                          },
                        );
                      },
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      );
    });
  }

  /// Muestra un diálogo compacto para confirmar/cambiar el método de pago
  /// (por defecto "Efectivo") justo antes de cobrar. Se hace como diálogo
  /// -en vez de dejarlo fijo en pantalla- para no ocupar espacio permanente.
  Future<bool> _confirmPaymentMethod(
    BuildContext context,
    InvoicesController controller,
  ) async {
    if (controller.paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay métodos de pago configurados')),
      );
      return false;
    }

    PaymentMethod? tempSelection = controller.selectedPaymentMethod.value ??
        controller.paymentMethods.first;

    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Método de pago'),
            content: DropdownButtonFormField<PaymentMethod>(
              initialValue: tempSelection,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                ),
              ),
              items: controller.paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text('${method.displayIcon} ${method.name}'),
                );
              }).toList(),
              onChanged: (value) => setDialogState(() => tempSelection = value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && tempSelection != null) {
      controller.selectPaymentMethod(tempSelection);
      return true;
    }
    return false;
  }

  /// Aclaración visual en el carrito cuando la línea no está al precio
  /// público (precioA) por defecto, para que el cajero note que se
  /// facturará a mayorista/super mayorista.
  String _priceTierSuffix(InvoiceCartLine line) {
    if (line.unitPrice == line.product.precioB) return ' (Mayorista)';
    if (line.unitPrice == line.product.precioC) return ' (Super Mayorista)';
    return '';
  }

  Widget _buildCartSection(InvoicesController controller) {
    return Obx(() {
      if (controller.cart.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Get.theme.disabledColor),
                const SizedBox(height: 8),
                Text('Carrito vacío', style: Get.textTheme.bodyMedium),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Productos (${controller.cartItemCount})', style: Get.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...controller.cart.map((line) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: nombre + eliminar. Separada de la fila de
                    // cantidades para que ambas tengan suficiente espacio y
                    // no se desborden en pantallas de celular angostas.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            line.product.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => controller.removeCartLine(line),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Get.theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    (line.product.precioB == null && line.product.precioC == null)
                        ? Text(
                            '${NumberFormatter.formatCurrency(line.unitPrice)} c/u',
                            style: Get.textTheme.bodySmall,
                          )
                        : InkWell(
                            onTap: () => _editLinePrice(controller, line),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${NumberFormatter.formatCurrency(line.unitPrice)} c/u${_priceTierSuffix(line)}',
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.underline,
                                    decorationStyle: TextDecorationStyle.dotted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit_outlined, size: 12, color: Get.theme.colorScheme.primary),
                              ],
                            ),
                          ),
                    const SizedBox(height: 8),
                    // Fila 2: stepper de cantidad (compacto, sin IconButtons
                    // de 48px que se comían el espacio) + total de la línea.
                    Row(
                      children: [
                        _QuantityStepper(
                          quantity: line.quantity,
                          onDecrement: () => controller.updateCartLineQuantity(line, line.quantity - 1),
                          onIncrement: () => controller.updateCartLineQuantity(line, line.quantity + 1),
                        ),
                        const Spacer(),
                        Text(
                          NumberFormatter.formatCurrency(line.total),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  /// Cobra la factura y, si [print] es true, la imprime de inmediato. En
  /// ambos casos navega al detalle de la factura al terminar (ahí también
  /// hay un botón manual de "Imprimir recibo" por si hace falta reimprimir).
  Future<void> _checkout(InvoicesController controller, {required bool print}) async {
    final confirmed = await _confirmPaymentMethod(context, controller);
    if (!confirmed) return;

    final invoice = await controller.checkout();
    if (invoice == null || !mounted) return;

    if (print) {
      setState(() => _isPrinting = true);
      try {
        await printInvoiceWithFallback(context, invoice);
      } finally {
        if (mounted) setState(() => _isPrinting = false);
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.invoiceDetail, arguments: invoice.id);
    }
  }

  Widget _buildCheckoutBar(InvoicesController controller) {
    return Obx(() {
      return Container(
        padding: EdgeInsets.only(
          left: AppConfig.paddingMedium,
          right: AppConfig.paddingMedium,
          top: AppConfig.paddingMedium,
          bottom: AppConfig.paddingMedium + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _totalsRow('Total', controller.cartTotal, isBold: true),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final busy = controller.cartIsEmpty || controller.isCreatingInvoice.value || _isPrinting;
              final borderRadius = BorderRadius.circular(AppConfig.borderRadius);
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _checkout(controller, print: false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: borderRadius),
                      ),
                      child: const Text('Cobrar', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : () => _checkout(controller, print: true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: borderRadius),
                      ),
                      icon: (controller.isCreatingInvoice.value || _isPrinting)
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.print_outlined, size: 20),
                      label: const Text('Cobrar e Imprimir', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );
    });
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
}

/// Stepper de cantidad compacto (pastilla con -/+). Reemplaza los dos
/// IconButton() de 48x48 que se usaban antes: en pantallas de celular
/// angostas ese ancho fijo desbordaba la fila y el botón "-" quedaba
/// invisible (aunque seguía respondiendo al tap por el área táctil mínima).
/// Con InkWell + Padding el ancho total es ~40% menor y siempre visible.
class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _stepperButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16),
      ),
    );
  }
}
