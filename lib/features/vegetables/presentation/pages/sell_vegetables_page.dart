// lib/features/vegetables/presentation/pages/sell_vegetables_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../vegetable_cash_sessions/domain/usecases/vegetable_cash_sessions_usecases.dart';
import '../../../credits/domain/entities/payment_method.dart';
import '../../domain/entities/vegetable_item.dart';
import '../controllers/vegetables_controller.dart';

/// POS-style screen to sell vegetables: tap a weighted item to capture the
/// live scale reading, tap a fixed-price item to add a unit, then charge
/// and print the receipt.
class SellVegetablesPage extends StatefulWidget {
  const SellVegetablesPage({super.key});

  @override
  State<SellVegetablesPage> createState() => _SellVegetablesPageState();
}

class _SellVegetablesPageState extends State<SellVegetablesPage> {
  late final TextEditingController searchController;
  // null = todavía no se sabe (mientras no se sepa, no se deja vender).
  bool? _hasOpenCashSession;
  bool _isStaleSession = false;

  /// Habilita vender: tiene que haber una caja abierta y que sea la de
  /// hoy - si quedó una caja de un día anterior sin cerrar, tampoco deja
  /// vender hasta que se cierre y se abra una nueva.
  bool get _canSell => _hasOpenCashSession == true && !_isStaleSession;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<VegetablesController>();
    searchController = TextEditingController(text: controller.itemsSearchQuery.value);
    searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadItems();
      controller.loadCategories();
      controller.loadPaymentMethods();
      if (!controller.isScaleConnected.value) {
        controller.connectScale();
      }
      _checkCashSession();
    });
  }

  Future<void> _checkCashSession() async {
    final result = await getIt<GetCurrentCashSessionUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) {}, // si falla la consulta, se queda como "no se sabe" (bloqueado)
      (summary) => setState(() {
        _hasOpenCashSession = summary.isOpen;
        _isStaleSession = summary.isStale;
      }),
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Get.find<VegetablesController>().searchItems(searchController.text);
  }

  void _clearSearch() => searchController.clear();

  /// Se llama al intentar salir de la pantalla (gesto/botón de retroceso).
  /// Esta pantalla casi siempre es la raíz de la pila (se llega por el
  /// drawer con offAllNamed), así que normalmente no hay nada a qué volver
  /// con pop() — solo confirmamos y vaciamos el carrito si hace falta.
  Future<void> _confirmDiscard(VegetablesController controller) async {
    final canPop = Navigator.of(context).canPop();

    if (controller.cartIsEmpty) {
      if (canPop) Navigator.of(context).pop();
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Descartar venta?'),
        content: Text('Tienes ${controller.cart.length} producto(s) en el carrito. Si sales ahora se perderán.'),
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

    if (confirmed == true && mounted) {
      controller.clearCart();
      if (canPop) Navigator.of(context).pop();
    }
  }

  Future<void> _addWeightedItem(VegetablesController controller, VegetableItem item) async {
    final existingLine = controller.cart.firstWhereOrNull((line) => line.item.id == item.id);
    final existingWeight = existingLine?.weightKg ?? 0;

    final weightController = TextEditingController(
      text: controller.liveWeight.value != null ? controller.liveWeight.value!.toStringAsFixed(3) : '',
    );

    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final entered = double.tryParse(weightController.text.trim().replaceAll(',', '.')) ?? 0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(item.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (existingWeight > 0)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppConfig.paddingMedium),
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    ),
                    child: Text(
                      'Ya tienes ${existingWeight.toStringAsFixed(3)} kg de ${item.name} en el carrito. '
                      'Este peso se suma, no lo reemplaza.',
                      style: Get.textTheme.bodySmall,
                    ),
                  ),
                Obx(() {
                  final connected = controller.isScaleConnected.value;
                  final weight = controller.liveWeight.value;
                  return Container(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    decoration: BoxDecoration(
                      color: (connected ? Get.theme.colorScheme.primary : Get.theme.disabledColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          connected ? Icons.scale : Icons.scale_outlined,
                          color: connected ? Get.theme.colorScheme.primary : Get.theme.disabledColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            connected
                                ? (weight != null ? '${weight.toStringAsFixed(3)} kg en báscula' : 'Esperando lectura...')
                                : 'Báscula no conectada',
                          ),
                        ),
                        if (connected && weight != null)
                          TextButton(
                            onPressed: () => setDialogState(() => weightController.text = weight.toStringAsFixed(3)),
                            child: const Text('Usar'),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: weightController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    labelText: existingWeight > 0 ? 'Peso a sumar (kg)' : 'Peso (kg)',
                    hintText: 'Ej: 0.350',
                    prefixIcon: const Icon(Icons.scale_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${NumberFormatter.formatCurrency(item.pricePerKg)} / kg',
                  style: Get.textTheme.bodySmall,
                ),
                if (existingWeight > 0 && entered > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Quedará: ${(existingWeight + entered).toStringAsFixed(3)} kg',
                    style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
                child: Text(existingWeight > 0 ? 'Sumar al carrito' : 'Agregar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final weight = double.tryParse(weightController.text.trim().replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      safeSnackbar('Peso inválido', 'Ingresa un peso mayor a 0', snackPosition: SnackPosition.TOP);
      return;
    }

    controller.addWeightedItemToCart(item, weight);
  }

  /// Pregunta cómo pagó el cliente: efectivo (directo, es el caso normal)
  /// o transferencia (un segundo paso para elegir a qué cuenta - Nequi,
  /// Bancolombia, etc.). Esto es lo que le permite al cierre de caja
  /// separar cuánto hay en efectivo real de cuánto llegó a un banco.
  Future<PaymentMethod?> _pickPaymentMethod(VegetablesController controller) async {
    final cashMethods = controller.cashPaymentMethods;
    final transferMethods = controller.transferPaymentMethods;

    // Caso normal: un solo método de efectivo. Si por configuración hay
    // más de uno raro, o ninguno, se cae al flujo de elegir cualquiera.
    final defaultCash = cashMethods.length == 1 ? cashMethods.first : null;
    bool showingTransfers = false;

    return Get.dialog<PaymentMethod>(
      StatefulBuilder(
        builder: (context, setStepState) {
              if (!showingTransfers) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('¿Cómo pagó el cliente?'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: defaultCash != null
                              ? () => Navigator.of(context, rootNavigator: true).pop(defaultCash)
                              : () => setStepState(() => showingTransfers = true),
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('Efectivo'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => setStepState(() => showingTransfers = true),
                          icon: const Icon(Icons.account_balance_outlined),
                          label: const Text('Transferencia'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                );
              }

              final options = defaultCash != null ? transferMethods : controller.paymentMethods;

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('¿A qué cuenta?'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((method) {
                      return ListTile(
                        leading: Text(method.displayIcon, style: const TextStyle(fontSize: 20)),
                        title: Text(method.name),
                        onTap: () => Navigator.of(context, rootNavigator: true).pop(method),
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => setStepState(() => showingTransfers = false),
                    child: const Text('Atrás'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              );
        },
      ),
    );
  }

  /// Cobra la venta y, si [print] es true, envía el recibo a la impresora
  /// térmica configurada. El resultado de la impresión se muestra con
  /// ScaffoldMessenger (inmediato, no se puede perder) en vez del
  /// safeSnackbar del controller, que se agenda con un delay y puede
  /// quedarse sin mostrarse si no hay Overlay disponible justo en ese
  /// momento — que es justo lo que hacía parecer que "no pasaba nada".
  Future<void> _checkoutAndMaybePrint(VegetablesController controller, {required bool print}) async {
    if (!_canSell) {
      safeSnackbar(
        _hasOpenCashSession == false ? 'Caja cerrada' : 'Caja sin cerrar',
        _hasOpenCashSession == false
            ? 'Debes abrir la caja antes de vender.'
            : 'Tienes una caja abierta de un día anterior. Ciérrala y abre una nueva para hoy.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final paymentMethod = await _pickPaymentMethod(controller);
    if (paymentMethod == null || !mounted) return;

    final sale = await controller.checkout(paymentMethod.id);
    if (sale == null || !print || !mounted) return;

    final error = await controller.printSale(sale);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Recibo enviado a la impresora'),
        backgroundColor: error != null ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmDiscard(controller);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vender Verduras'),
          elevation: 0,
          actions: [
            Obx(() => IconButton(
                  tooltip: controller.isScaleConnected.value ? 'Báscula conectada' : 'Conectar báscula',
                  icon: Icon(controller.isScaleConnected.value ? Icons.scale : Icons.scale_outlined),
                  color: controller.isScaleConnected.value ? Get.theme.colorScheme.primary : null,
                  onPressed: () => Get.toNamed(AppRoutes.scaleSettings),
                )),
          ],
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              if (_hasOpenCashSession != null && !_canSell) _buildCashSessionBlockBanner(),
              Obx(() {
                if (controller.isLoadingItems.value && controller.items.isEmpty) return const SizedBox.shrink();
                if (controller.items.isEmpty) return const SizedBox.shrink();
                return _buildSearchBar(controller);
              }),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingItems.value && controller.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConfig.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildItemsByCategory(controller),
                        const SizedBox(height: AppConfig.paddingLarge),
                        _buildCartSection(controller),
                      ],
                    ),
                  );
                }),
              ),
              _buildCheckoutBar(controller),
            ],
          ),
        ),
      ),
    );
  }

  /// Bloquea de verdad la venta: sin caja abierta hoy no se puede vender.
  /// Distingue dos casos: nunca se abrió caja hoy, o quedó una caja
  /// abierta de un día anterior sin cerrar (hay que cerrarla primero).
  Widget _buildCashSessionBlockBanner() {
    final message = _hasOpenCashSession == false
        ? 'No has abierto caja. No puedes vender hasta abrirla.'
        : 'Tienes una caja abierta de un día anterior sin cerrar. Ciérrala y abre una nueva para poder vender hoy.';
    final actionLabel = _hasOpenCashSession == false ? 'Abrir Caja' : 'Ir a Caja';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppConfig.paddingMedium,
        AppConfig.paddingMedium,
        AppConfig.paddingMedium,
        0,
      ),
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: Get.theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Get.theme.colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Get.toNamed(AppRoutes.vegetableCashSession);
              _checkCashSession();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  /// Buscador instantáneo por nombre o categoría - mismo mecanismo que el
  /// catálogo (filtra en el cliente, sin red) para encontrar un producto
  /// rápido en medio de la venta.
  Widget _buildSearchBar(VegetablesController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConfig.paddingMedium,
        AppConfig.paddingMedium,
        AppConfig.paddingMedium,
        0,
      ),
      child: CustomInput(
        controller: searchController,
        hintText: 'Buscar producto...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Obx(() {
          if (controller.itemsSearchQuery.value.isEmpty) return const SizedBox.shrink();
          return IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch);
        }),
      ),
    );
  }

  /// Productos agrupados por categoría (ej. "Verduras", "Frutas"), con un
  /// encabezado por sección - más rápido de escanear visualmente que una
  /// sola grilla larga cuando el catálogo crece.
  Widget _buildItemsByCategory(VegetablesController controller) {
    if (controller.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No hay productos activos en el catálogo'),
      );
    }

    final grouped = controller.itemsByCategory;

    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 40, color: Get.theme.disabledColor),
              const SizedBox(height: 8),
              Text('Sin resultados para "${controller.itemsSearchQuery.value}"'),
              const SizedBox(height: 8),
              TextButton(onPressed: _clearSearch, child: const Text('Limpiar búsqueda')),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: Get.textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildItemsGrid(controller, entry.value),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Grilla de tarjetas (con foto si el producto tiene una) en vez de un
  /// Wrap de cajas de ancho fijo - se acomoda mejor a distintos anchos de
  /// pantalla y se ve más como un punto de venta real.
  Widget _buildItemsGrid(VegetablesController controller, List<VegetableItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) => _buildItemCard(controller, items[index]),
    );
  }

  Widget _buildItemCard(VegetablesController controller, VegetableItem item) {
    final priceLabel = item.pricingType.isWeight
        ? '${NumberFormatter.formatCurrency(item.pricePerKg)}/kg'
        : NumberFormatter.formatCurrency(item.fixedPrice);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
      child: InkWell(
        onTap: () => item.pricingType.isWeight
            ? _addWeightedItem(controller, item)
            : controller.addFixedItemToCart(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: item.hasImage
                  ? Image.network(
                      item.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Get.theme.colorScheme.primary.withValues(alpha: 0.08),
                        child: Icon(
                          item.pricingType.isWeight ? Icons.scale_outlined : Icons.sell_outlined,
                          size: 32,
                          color: Get.theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: Get.theme.colorScheme.primary.withValues(alpha: 0.08),
                      child: Icon(
                        item.pricingType.isWeight ? Icons.scale_outlined : Icons.sell_outlined,
                        size: 32,
                        color: Get.theme.colorScheme.primary,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(priceLabel, style: Get.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection(VegetablesController controller) {
    return Obx(() {
      if (controller.cart.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_basket_outlined, size: 40, color: Get.theme.disabledColor),
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
          Text('En el carrito', style: Get.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...controller.cart.map((line) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
              child: ListTile(
                title: Text(line.item.name),
                subtitle: Text(line.quantityLabel),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormatter.formatCurrency(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                      onPressed: () => controller.removeFromCart(line.item.id),
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

  Widget _buildCheckoutBar(VegetablesController controller) {
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  NumberFormatter.formatCurrency(controller.cartTotal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final busy = controller.cartIsEmpty || controller.isCreatingSale.value || controller.isPrintingSale.value || !_canSell;
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _checkoutAndMaybePrint(controller, print: false),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Cobrar', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : () => _checkoutAndMaybePrint(controller, print: true),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      icon: (controller.isCreatingSale.value || controller.isPrintingSale.value)
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
}
