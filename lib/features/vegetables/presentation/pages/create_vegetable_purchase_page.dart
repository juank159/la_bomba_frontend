// lib/features/vegetables/presentation/pages/create_vegetable_purchase_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/routes.dart';
import '../../../../app/core/utils/number_formatter.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/entities/vegetable_purchase.dart';
import '../controllers/vegetables_controller.dart';

/// Registra una compra real de mercancía: selecciona productos ya
/// existentes en el catálogo (misma búsqueda/filtro por categoría que
/// "Vender Verduras"), indica cantidad y costo pagado. Al guardar, suma
/// automáticamente al inventario de cada producto.
///
/// Con [editingPurchaseId], la misma pantalla sirve para corregir una
/// compra ya registrada (ej. un valor mal digitado): precarga el carrito
/// con las líneas actuales de esa compra y, al guardar, reemplaza esas
/// líneas en vez de crear una compra nueva (ver
/// VegetablesController.updatePurchase). No se puede cambiar el origen
/// del dinero (caja/externo) al editar.
class CreateVegetablePurchasePage extends StatefulWidget {
  final String? editingPurchaseId;
  const CreateVegetablePurchasePage({super.key, this.editingPurchaseId});

  bool get isEditing => editingPurchaseId != null;

  @override
  State<CreateVegetablePurchasePage> createState() => _CreateVegetablePurchasePageState();
}

class _CreateVegetablePurchasePageState extends State<CreateVegetablePurchasePage> {
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<VegetablesController>();
    searchController = TextEditingController(text: controller.itemsSearchQuery.value);
    searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.clearPurchaseCart();
      controller.loadCategories();

      if (widget.isEditing) {
        // includeInactive: true - si el producto se desactivó después de
        // esa compra, igual tiene que poder verse/editarse esa línea.
        await Future.wait([
          controller.loadItems(includeInactive: true),
          controller.loadPurchaseById(widget.editingPurchaseId!),
        ]);
        if (mounted) _prefillCartFromExistingPurchase(controller);
      } else {
        controller.loadItems();
      }
    });
  }

  /// Carga en el carrito de edición las líneas de la compra que se está
  /// corrigiendo, buscando cada producto en el catálogo ya cargado (con
  /// inactivos incluidos - ver initState).
  void _prefillCartFromExistingPurchase(VegetablesController controller) {
    final purchase = controller.selectedPurchase.value;
    if (purchase == null || purchase.id != widget.editingPurchaseId) return;

    for (final line in purchase.items) {
      if (line.isFreePurchase) {
        controller.addFreePurchaseToCart(line.description, line.total);
        continue;
      }
      final item = controller.items.firstWhereOrNull((i) => i.id == line.vegetableItemId);
      if (item == null) continue; // el producto ya no existe en el catálogo
      controller.addToPurchaseCart(item, line.quantity!, line.unitCost!);
    }
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

  Future<bool> _confirmDiscard(VegetablesController controller) async {
    if (controller.purchaseCartIsEmpty) return true;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Descartar compra?'),
        content: Text('Tienes ${controller.purchaseCart.length} producto(s) sin guardar. Si sales ahora se perderán.'),
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
    return confirmed ?? false;
  }

  /// Pregunta de dónde salió la plata para pagar la compra, justo antes de
  /// registrarla: si es de la caja, el cierre de turno la va a descontar
  /// del efectivo esperado (igual que un gasto pagado de caja) - así el
  /// cajero no queda descuadrado.
  Future<PurchaseFundingSource?> _pickFundingSource() {
    PurchaseFundingSource selected = PurchaseFundingSource.external;

    return Get.dialog<PurchaseFundingSource>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('¿De dónde salió la plata?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Si es de la caja, se descuenta del efectivo esperado al cerrar el turno.',
                  style: Get.textTheme.bodySmall,
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                SegmentedButton<PurchaseFundingSource>(
                  segments: const [
                    ButtonSegment(
                      value: PurchaseFundingSource.caja,
                      label: Text('Caja'),
                      icon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    ButtonSegment(
                      value: PurchaseFundingSource.external,
                      label: Text('Externo'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {selected},
                  onSelectionChanged: (selection) => setDialogState(() => selected = selection.first),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(selected),
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Compra libre: agrega al carrito un monto total con descripción a
  /// mano, sin asociarlo a ningún producto del catálogo - ej. algo puntual
  /// que no vale la pena cargar como producto. No afecta inventario. Se
  /// guarda y aparece en el historial igual que cualquier otra compra.
  Future<void> _promptFreePurchase(VegetablesController controller) async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String? errorText;

    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Compra libre'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para registrar algo puntual que no está en el catálogo. No afecta el inventario.',
                  style: Get.textTheme.bodySmall,
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: descriptionController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: bolsas para empacar',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (descriptionController.text.trim().isEmpty) {
                    setDialogState(() => errorText = 'Ingresa una descripción');
                    return;
                  }
                  if (PriceFormatter.parse(amountController.text.trim()) <= 0) {
                    safeSnackbar('Monto inválido', 'Ingresa un monto mayor a 0', snackPosition: SnackPosition.TOP);
                    return;
                  }
                  Navigator.of(context, rootNavigator: true).pop(true);
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    controller.addFreePurchaseToCart(
      descriptionController.text.trim(),
      PriceFormatter.parse(amountController.text.trim()),
    );
  }

  Future<void> _pickQuantityAndCost(
    VegetablesController controller,
    VegetableItem item, {
    double? initialQuantity,
    double? initialUnitCost,
  }) async {
    final quantityController = TextEditingController(
      text: initialQuantity != null ? NumberFormatter.formatQuantity(initialQuantity) : '',
    );
    final costController = TextEditingController(
      text: initialUnitCost != null && initialUnitCost > 0 ? PriceFormatter.formatForDisplay(initialUnitCost) : '',
    );
    final costFocusNode = FocusNode();
    String? errorText;
    // Con el teclado abierto, el primer toque sobre "Agregar" a veces solo
    // le quita el foco al campo de texto (lo cierra) en vez de también
    // disparar el botón - comportamiento típico de navegadores/Flutter Web
    // cuando el toque cae fuera de un campo enfocado. onPointerDown
    // reacciona al toque inicial (antes de ese "robo" de foco), así que la
    // acción se dispara de una - la bandera evita que se dispare dos veces
    // si de todos modos también llega el onPressed normal.
    var submitted = false;

    void submit(BuildContext dialogContext, void Function(void Function()) setDialogState) {
      if (submitted) return;
      final quantity = double.tryParse(quantityController.text.trim().replaceAll(',', '.'));
      if (quantity == null || quantity <= 0) {
        setDialogState(() => errorText = 'Ingresa una cantidad válida');
        return;
      }
      submitted = true;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(dialogContext, rootNavigator: true).pop(true);
    }

    final confirmed = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(item.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock actual: ${NumberFormatter.formatQuantity(item.stock)} ${item.stockUnitLabel}',
                    style: Get.textTheme.bodySmall),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: quantityController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => costFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'Cantidad comprada',
                    suffixText: item.stockUnitLabel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: AppConfig.paddingMedium),
                TextField(
                  controller: costController,
                  focusNode: costFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [PriceInputFormatter()],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(context, setDialogState),
                  decoration: InputDecoration(
                    labelText: item.pricingType.isWeight ? 'Costo pagado por kg' : 'Costo pagado por unidad',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Cancelar'),
              ),
              Listener(
                onPointerDown: (_) => submit(context, setDialogState),
                child: ElevatedButton(
                  onPressed: () => submit(context, setDialogState),
                  child: const Text('Agregar'),
                ),
              ),
            ],
          );
        },
      ),
    );

    costFocusNode.dispose();

    if (confirmed != true) return;

    final quantity = double.tryParse(quantityController.text.trim().replaceAll(',', '.')) ?? 0;
    final unitCost = PriceFormatter.parse(costController.text.trim());
    if (quantity <= 0) return;

    // Si initialQuantity viene seteado, se abrió tocando una línea que YA
    // está en el carrito (para corregirla) - hay que REEMPLAZAR el valor,
    // no sumarle encima (ver updatePurchaseCartLine). Tocar una tarjeta del
    // catálogo (initialQuantity null) sigue sumando, como antes.
    if (initialQuantity != null) {
      controller.updatePurchaseCartLine(item, quantity, unitCost);
    } else {
      controller.addToPurchaseCart(item, quantity, unitCost);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VegetablesController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard(controller) && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Editar Compra' : 'Nueva Compra'),
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Compra libre',
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => _promptFreePurchase(controller),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConfig.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(controller),
                      const SizedBox(height: AppConfig.paddingMedium),
                      _buildCatalog(controller),
                      const SizedBox(height: AppConfig.paddingLarge),
                      _buildCart(controller),
                    ],
                  ),
                ),
              ),
              _buildCheckoutBar(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(VegetablesController controller) {
    return CustomInput(
      controller: searchController,
      hintText: 'Buscar producto...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: Obx(() {
        if (controller.itemsSearchQuery.value.isEmpty) return const SizedBox.shrink();
        return IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch);
      }),
    );
  }

  Widget _buildCatalog(VegetablesController controller) {
    return Obx(() {
      if (controller.isLoadingItems.value && controller.items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final grouped = controller.itemsByCategory;

      if (grouped.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 40, color: Get.theme.disabledColor),
                const SizedBox(height: 8),
                Text(
                  controller.itemsSearchQuery.value.isEmpty
                      ? 'No hay productos activos en el catálogo'
                      : 'Sin resultados para "${controller.itemsSearchQuery.value}"',
                ),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((item) => _buildCatalogCard(controller, item)).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildCatalogCard(VegetablesController controller, VegetableItem item) {
    final outOfStock = item.isOutOfStock;
    return InkWell(
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      onTap: () => _pickQuantityAndCost(controller, item),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppConfig.paddingSmall),
        decoration: BoxDecoration(
          border: Border.all(color: outOfStock ? Get.theme.colorScheme.error : Get.theme.dividerColor),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.pricingType.isWeight ? Icons.scale_outlined : Icons.sell_outlined,
              color: Get.theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              outOfStock
                  ? 'Sin stock'
                  : 'Stock: ${NumberFormatter.formatQuantity(item.stock)} ${item.stockUnitLabel}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: outOfStock ? FontWeight.w600 : null,
                color: outOfStock ? Get.theme.colorScheme.error : Get.theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart(VegetablesController controller) {
    return Obx(() {
      if (controller.purchaseCart.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.shopping_basket_outlined, size: 40, color: Get.theme.disabledColor),
                const SizedBox(height: 8),
                Text('Carrito de compra vacío', style: Get.textTheme.bodyMedium),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En la compra', style: Get.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...controller.purchaseCart.map((line) {
            if (line.isFreePurchase) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                child: ListTile(
                  leading: Icon(Icons.shopping_bag_outlined, color: Get.theme.colorScheme.secondary),
                  title: Text(line.name),
                  subtitle: const Text('Compra libre'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormatter.formatCurrency(line.total),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                        onPressed: () => controller.removeFromPurchaseCart(line),
                      ),
                    ],
                  ),
                ),
              );
            }

            final item = line.item!;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
              child: ListTile(
                onTap: () => _pickQuantityAndCost(
                  controller,
                  item,
                  initialQuantity: line.quantity,
                  initialUnitCost: line.unitCost,
                ),
                title: Text(item.name),
                subtitle: Text(
                  '${NumberFormatter.formatQuantity(line.quantity ?? 0)} ${item.stockUnitLabel} x ${NumberFormatter.formatCurrency(line.unitCost ?? 0)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      NumberFormatter.formatCurrency(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Get.theme.colorScheme.error),
                      onPressed: () => controller.removeFromPurchaseCart(line),
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
                  NumberFormatter.formatCurrency(controller.purchaseCartTotal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.purchaseCartIsEmpty || controller.isCreatingPurchase.value
                    ? null
                    : () async {
                        VegetablePurchase? purchase;
                        if (widget.isEditing) {
                          purchase = await controller.updatePurchase(widget.editingPurchaseId!);
                        } else {
                          final fundingSource = await _pickFundingSource();
                          if (fundingSource == null || !mounted) return;
                          purchase = await controller.checkoutPurchase(fundingSource);
                        }
                        if (purchase != null && mounted) {
                          if (widget.isEditing) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushReplacementNamed(AppRoutes.vegetablePurchases);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: controller.isCreatingPurchase.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.isEditing ? 'Guardar Cambios' : 'Registrar Compra', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
