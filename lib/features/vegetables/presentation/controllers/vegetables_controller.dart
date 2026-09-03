import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/core/di/service_locator.dart';
import '../../../../app/core/services/preferences_service.dart';
import '../../domain/entities/vegetable_category.dart';
import '../../domain/entities/vegetable_item.dart';
import '../../domain/entities/vegetable_order.dart';
import '../../domain/entities/vegetable_order_item.dart';
import '../../domain/entities/vegetable_sale.dart';
import '../../domain/repositories/vegetables_repository.dart';
import '../../domain/usecases/get_vegetable_categories_usecase.dart';
import '../../domain/usecases/save_vegetable_category_usecase.dart';
import '../../domain/usecases/delete_vegetable_category_usecase.dart';
import '../../domain/usecases/get_vegetable_items_usecase.dart';
import '../../domain/usecases/save_vegetable_item_usecase.dart';
import '../../domain/usecases/delete_vegetable_item_usecase.dart';
import '../../domain/usecases/create_vegetable_sale_usecase.dart';
import '../../domain/usecases/get_vegetable_sales_usecase.dart';
import '../../domain/usecases/create_vegetable_order_usecase.dart';
import '../../domain/usecases/get_vegetable_orders_usecase.dart';
import '../../data/services/scale_service.dart';
import '../../data/services/vegetable_printer_service.dart';
import '../../data/services/vegetable_order_pdf_service.dart';

/// Wraps Get.snackbar() so a missing Overlay can't crash the calling code.
/// Same defensive pattern as invoices_controller.dart's safeSnackbar - see
/// that file for the full incident writeup on why a plain Get.snackbar()
/// right after navigation can throw "No Overlay widget found".
void safeSnackbar(
  String title,
  String message, {
  SnackPosition? snackPosition,
  Color? backgroundColor,
  Color? colorText,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(milliseconds: 350));
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: snackPosition,
        backgroundColor: backgroundColor,
        colorText: colorText,
      );
    } catch (_) {
      // No Overlay available right now - not worth crashing over a toast.
    }
  });
}

/// A single line in the vegetable sale being built (not yet persisted)
class VegetableCartLine {
  final VegetableItem item;
  final double? weightKg;
  final int? quantity;

  const VegetableCartLine({required this.item, this.weightKg, this.quantity});

  double get total {
    if (item.pricingType.isWeight) {
      return (item.pricePerKg ?? 0) * (weightKg ?? 0);
    }
    return (item.fixedPrice ?? 0) * (quantity ?? 1);
  }

  String get quantityLabel {
    if (item.pricingType.isWeight) {
      return '${(weightKg ?? 0).toStringAsFixed(3)} kg';
    }
    return '${quantity ?? 1} un';
  }

  VegetableCartLine copyWith({double? weightKg, int? quantity}) {
    return VegetableCartLine(
      item: item,
      weightKg: weightKg ?? this.weightKg,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// A single line in the vegetable order (pedido) being built, not yet
/// persisted. Either references a catalog product or is a one-off manual
/// entry (occasional product not yet in the catalog).
class VegetableOrderCartLine {
  final String? vegetableItemId;
  final String description;
  final double quantity;
  final VegetableOrderUnit unit;

  const VegetableOrderCartLine({
    this.vegetableItemId,
    required this.description,
    required this.quantity,
    required this.unit,
  });

  String get quantityLabel {
    final formatted = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(3);
    return '$formatted ${unit.shortDisplayName}';
  }
}

/// Controller for the vegetables (verduras) module: catalog management,
/// scale-assisted cart/checkout, sales history and restock orders (pedidos).
class VegetablesController extends GetxController {
  final GetVegetableCategoriesUseCase getVegetableCategoriesUseCase;
  final SaveVegetableCategoryUseCase saveVegetableCategoryUseCase;
  final DeleteVegetableCategoryUseCase deleteVegetableCategoryUseCase;
  final GetVegetableItemsUseCase getVegetableItemsUseCase;
  final SaveVegetableItemUseCase saveVegetableItemUseCase;
  final DeleteVegetableItemUseCase deleteVegetableItemUseCase;
  final CreateVegetableSaleUseCase createVegetableSaleUseCase;
  final GetVegetableSalesUseCase getVegetableSalesUseCase;
  final GetVegetableSaleByIdUseCase getVegetableSaleByIdUseCase;
  final CreateVegetableOrderUseCase createVegetableOrderUseCase;
  final GetVegetableOrdersUseCase getVegetableOrdersUseCase;
  final GetVegetableOrderByIdUseCase getVegetableOrderByIdUseCase;
  final ScaleService scaleService;
  final VegetablePrinterService printerService;
  final VegetableOrderPdfService orderPdfService;
  final PreferencesService preferencesService = getIt<PreferencesService>();

  VegetablesController({
    required this.getVegetableCategoriesUseCase,
    required this.saveVegetableCategoryUseCase,
    required this.deleteVegetableCategoryUseCase,
    required this.getVegetableItemsUseCase,
    required this.saveVegetableItemUseCase,
    required this.deleteVegetableItemUseCase,
    required this.createVegetableSaleUseCase,
    required this.getVegetableSalesUseCase,
    required this.getVegetableSaleByIdUseCase,
    required this.createVegetableOrderUseCase,
    required this.getVegetableOrdersUseCase,
    required this.getVegetableOrderByIdUseCase,
    required this.scaleService,
    required this.printerService,
    required this.orderPdfService,
  });

  // ---- Categorías ----
  final RxList<VegetableCategory> categories = <VegetableCategory>[].obs;
  final RxBool isLoadingCategories = false.obs;
  final RxBool isSavingCategory = false.obs;

  // ---- Catálogo ----
  final RxList<VegetableItem> items = <VegetableItem>[].obs;
  final RxBool isLoadingItems = false.obs;
  final RxBool isSavingItem = false.obs;
  final RxString itemsSearchQuery = ''.obs;

  // ---- Carrito / venta ----
  final RxList<VegetableCartLine> cart = <VegetableCartLine>[].obs;
  final RxBool isCreatingSale = false.obs;

  // ---- Báscula ----
  final RxBool isScaleConnected = false.obs;
  final Rx<double?> liveWeight = Rx<double?>(null);
  final RxString scaleError = ''.obs;
  StreamSubscription<double>? _scaleSubscription;

  // ---- Impresión de recibo ----
  final RxBool isPrintingSale = false.obs;

  // ---- Historial de ventas ----
  final RxList<VegetableSale> sales = <VegetableSale>[].obs;
  final Rx<VegetableSale?> selectedSale = Rx<VegetableSale?>(null);
  final RxBool isLoadingSales = false.obs;
  final RxBool isLoadingSaleDetail = false.obs;

  // ---- Pedidos (lista de reabastecimiento) ----
  final RxList<VegetableOrderCartLine> orderCart = <VegetableOrderCartLine>[].obs;
  final RxBool isCreatingOrder = false.obs;
  final RxList<VegetableOrder> orders = <VegetableOrder>[].obs;
  final Rx<VegetableOrder?> selectedOrder = Rx<VegetableOrder?>(null);
  final RxBool isLoadingOrders = false.obs;
  final RxBool isLoadingOrderDetail = false.obs;

  @override
  void onClose() {
    disconnectScale();
    super.onClose();
  }

  // ==========================================================================
  // Categorías
  // ==========================================================================

  Future<void> loadCategories({bool includeInactive = false}) async {
    try {
      isLoadingCategories.value = true;
      final result = await getVegetableCategoriesUseCase(includeInactive: includeInactive);
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar las categorías: ${failure.message}', snackPosition: SnackPosition.TOP),
        (loaded) => categories.assignAll(loaded),
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<bool> saveCategory({String? id, required VegetableCategoryParams params}) async {
    try {
      isSavingCategory.value = true;
      final result = await saveVegetableCategoryUseCase(id: id, params: params);
      return result.fold(
        (failure) {
          safeSnackbar('Error', failure.message, snackPosition: SnackPosition.TOP);
          return false;
        },
        (saved) {
          final index = categories.indexWhere((c) => c.id == saved.id);
          if (index >= 0) {
            categories[index] = saved;
          } else {
            categories.add(saved);
          }
          safeSnackbar(
            id == null ? 'Categoría creada' : 'Categoría actualizada',
            saved.name,
            snackPosition: SnackPosition.TOP,
          );
          return true;
        },
      );
    } finally {
      isSavingCategory.value = false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    final result = await deleteVegetableCategoryUseCase(id);
    return result.fold(
      (failure) {
        safeSnackbar('Error', 'No se pudo eliminar la categoría: ${failure.message}', snackPosition: SnackPosition.TOP);
        return false;
      },
      (_) {
        categories.removeWhere((c) => c.id == id);
        return true;
      },
    );
  }

  // ==========================================================================
  // Catálogo
  // ==========================================================================

  /// Productos agrupados por categoría (para la pantalla de venta), en el
  /// mismo orden en que llegaron las categorías; los sin categoría quedan
  /// al final bajo "Sin categoría". Respeta [itemsSearchQuery]: al buscar,
  /// agrupa sobre [filteredItems] en vez de la lista completa.
  Map<String, List<VegetableItem>> get itemsByCategory {
    final Map<String, List<VegetableItem>> grouped = {};
    final source = filteredItems;

    for (final category in categories) {
      final itemsInCategory = source.where((i) => i.categoryId == category.id).toList();
      if (itemsInCategory.isNotEmpty) {
        grouped[category.name] = itemsInCategory;
      }
    }

    final uncategorized = source.where((i) => i.categoryId == null).toList();
    if (uncategorized.isNotEmpty) {
      grouped['Sin categoría'] = uncategorized;
    }

    return grouped;
  }

  /// Búsqueda local del catálogo (por nombre y categoría): el catálogo de
  /// verduras ya está completo en memoria y suele ser chico, así que
  /// filtrar en el cliente da resultados instantáneos mientras se escribe
  /// - sin ida y vuelta al servidor como en el buscador de productos.
  void searchItems(String query) {
    itemsSearchQuery.value = query;
  }

  void clearItemsSearch() => itemsSearchQuery.value = '';

  List<VegetableItem> get filteredItems {
    final query = itemsSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((item) {
      final matchesName = item.name.toLowerCase().contains(query);
      final matchesCategory = item.category?.name.toLowerCase().contains(query) ?? false;
      return matchesName || matchesCategory;
    }).toList();
  }

  Future<void> loadItems({bool includeInactive = false}) async {
    try {
      isLoadingItems.value = true;
      final result = await getVegetableItemsUseCase(includeInactive: includeInactive);
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar el catálogo: ${failure.message}', snackPosition: SnackPosition.TOP),
        (loaded) => items.assignAll(loaded),
      );
    } finally {
      isLoadingItems.value = false;
    }
  }

  Future<bool> saveItem({String? id, required VegetableItemParams params}) async {
    try {
      isSavingItem.value = true;
      final result = await saveVegetableItemUseCase(id: id, params: params);
      return result.fold(
        (failure) {
          safeSnackbar('Error', failure.message, snackPosition: SnackPosition.TOP);
          return false;
        },
        (saved) {
          final index = items.indexWhere((i) => i.id == saved.id);
          if (index >= 0) {
            items[index] = saved;
          } else {
            items.add(saved);
          }
          safeSnackbar(
            id == null ? 'Producto creado' : 'Producto actualizado',
            saved.name,
            snackPosition: SnackPosition.TOP,
          );
          return true;
        },
      );
    } finally {
      isSavingItem.value = false;
    }
  }

  Future<bool> deleteItem(String id) async {
    final result = await deleteVegetableItemUseCase(id);
    return result.fold(
      (failure) {
        safeSnackbar('Error', 'No se pudo eliminar el producto: ${failure.message}', snackPosition: SnackPosition.TOP);
        return false;
      },
      (_) {
        items.removeWhere((i) => i.id == id);
        return true;
      },
    );
  }

  // ==========================================================================
  // Báscula
  // ==========================================================================

  Future<void> connectScale() async {
    final portName = preferencesService.getScalePort();
    if (portName == null || portName.isEmpty) {
      scaleError.value = 'No has configurado el puerto de la báscula';
      return;
    }
    final baudRate = preferencesService.getScaleBaudRate();

    try {
      scaleError.value = '';
      scaleService.connect(portName: portName, baudRate: baudRate);
      isScaleConnected.value = true;

      _scaleSubscription?.cancel();
      _scaleSubscription = scaleService.weightStream.listen(
        (weight) => liveWeight.value = weight,
        onError: (Object error) {
          scaleError.value = error.toString();
        },
      );
    } catch (e) {
      isScaleConnected.value = false;
      scaleError.value = e.toString();
    }
  }

  void disconnectScale() {
    _scaleSubscription?.cancel();
    _scaleSubscription = null;
    scaleService.disconnect();
    isScaleConnected.value = false;
    liveWeight.value = null;
  }

  // ==========================================================================
  // Carrito
  // ==========================================================================

  /// Agrega un producto de precio fijo (1 unidad, o suma si ya está en el carrito)
  void addFixedItemToCart(VegetableItem item) {
    final index = cart.indexWhere((line) => line.item.id == item.id);
    if (index >= 0) {
      final existing = cart[index];
      cart[index] = existing.copyWith(quantity: (existing.quantity ?? 1) + 1);
    } else {
      cart.add(VegetableCartLine(item: item, quantity: 1));
    }
  }

  /// Agrega o reemplaza el peso de un producto pesado en el carrito
  void addWeightedItemToCart(VegetableItem item, double weightKg) {
    final index = cart.indexWhere((line) => line.item.id == item.id);
    if (index >= 0) {
      cart[index] = cart[index].copyWith(weightKg: weightKg);
    } else {
      cart.add(VegetableCartLine(item: item, weightKg: weightKg));
    }
  }

  void updateFixedItemQuantity(String itemId, int quantity) {
    final index = cart.indexWhere((line) => line.item.id == itemId);
    if (index < 0) return;
    if (quantity <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = cart[index].copyWith(quantity: quantity);
    }
  }

  void removeFromCart(String itemId) {
    cart.removeWhere((line) => line.item.id == itemId);
  }

  void clearCart() {
    cart.clear();
  }

  double get cartTotal => cart.fold(0.0, (sum, line) => sum + line.total);
  bool get cartIsEmpty => cart.isEmpty;

  // ==========================================================================
  // Checkout
  // ==========================================================================

  Future<VegetableSale?> checkout() async {
    if (cart.isEmpty) {
      safeSnackbar('Carrito vacío', 'Agrega al menos un producto antes de vender', snackPosition: SnackPosition.TOP);
      return null;
    }

    try {
      isCreatingSale.value = true;

      final params = cart
          .map((line) => CreateVegetableSaleItemParams(
                vegetableItemId: line.item.id,
                weightKg: line.item.pricingType.isWeight ? line.weightKg : null,
                quantity: line.item.pricingType.isFixed ? line.quantity : null,
              ))
          .toList();

      final result = await createVegetableSaleUseCase(params);

      return result.fold(
        (failure) {
          safeSnackbar('Error al registrar la venta', failure.message, snackPosition: SnackPosition.TOP);
          return null;
        },
        (sale) {
          clearCart();
          sales.insert(0, sale);
          safeSnackbar('Venta registrada', 'Venta ${sale.formattedNumber} registrada correctamente', snackPosition: SnackPosition.TOP);
          return sale;
        },
      );
    } finally {
      isCreatingSale.value = false;
    }
  }

  /// Imprime el recibo usando la misma impresora configurada globalmente
  /// para toda la app (red o USB, guardada en PreferencesService).
  ///
  /// Devuelve `null` si imprimió correctamente, o un mensaje de error si
  /// falló. Se devuelve en vez de mostrarse aquí con safeSnackbar porque
  /// ese snackbar se agenda con un delay (addPostFrameCallback + 350ms) y
  /// puede perderse en silencio si no hay Overlay disponible en ese
  /// instante (ver safeSnackbar arriba) - la pantalla lo muestra con
  /// ScaffoldMessenger, que es inmediato y no falla de esa forma.
  Future<String?> printSale(VegetableSale sale) async {
    if (kIsWeb) {
      return 'La impresión térmica no está disponible en la versión web.';
    }

    final destination = preferencesService.getPrinterDestination();
    if (destination == null) {
      return 'Configura tu impresora en Facturación > Impresora Térmica';
    }

    try {
      isPrintingSale.value = true;
      await printerService.printSale(sale, destination: destination);
      return null;
    } on VegetablePrinterException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      isPrintingSale.value = false;
    }
  }

  // ==========================================================================
  // Historial de ventas
  // ==========================================================================

  Future<void> loadSales() async {
    try {
      isLoadingSales.value = true;
      final result = await getVegetableSalesUseCase();
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar las ventas: ${failure.message}', snackPosition: SnackPosition.TOP),
        (loaded) => sales.assignAll(loaded),
      );
    } finally {
      isLoadingSales.value = false;
    }
  }

  Future<void> loadSaleById(String id) async {
    try {
      isLoadingSaleDetail.value = true;
      selectedSale.value = null;
      final result = await getVegetableSaleByIdUseCase(id);
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar la venta: ${failure.message}', snackPosition: SnackPosition.TOP),
        (sale) => selectedSale.value = sale,
      );
    } finally {
      isLoadingSaleDetail.value = false;
    }
  }

  // ==========================================================================
  // Pedidos (lista de reabastecimiento)
  // ==========================================================================

  void addCatalogItemToOrder(VegetableItem item, double quantity, VegetableOrderUnit unit) {
    orderCart.add(VegetableOrderCartLine(
      vegetableItemId: item.id,
      description: item.name,
      quantity: quantity,
      unit: unit,
    ));
  }

  void addCustomItemToOrder(String description, double quantity, VegetableOrderUnit unit) {
    orderCart.add(VegetableOrderCartLine(description: description, quantity: quantity, unit: unit));
  }

  void removeFromOrderCart(int index) {
    if (index < 0 || index >= orderCart.length) return;
    orderCart.removeAt(index);
  }

  void clearOrderCart() => orderCart.clear();

  bool get orderCartIsEmpty => orderCart.isEmpty;

  /// Registra el pedido y de inmediato abre el diálogo de impresión del PDF.
  Future<VegetableOrder?> submitOrder() async {
    if (orderCart.isEmpty) {
      safeSnackbar('Pedido vacío', 'Agrega al menos un producto antes de generar el pedido', snackPosition: SnackPosition.TOP);
      return null;
    }

    try {
      isCreatingOrder.value = true;

      final params = orderCart
          .map((line) => CreateVegetableOrderItemParams(
                vegetableItemId: line.vegetableItemId,
                description: line.vegetableItemId == null ? line.description : null,
                quantity: line.quantity,
                unit: line.unit,
              ))
          .toList();

      final result = await createVegetableOrderUseCase(params);

      return await result.fold(
        (failure) async {
          safeSnackbar('Error al registrar el pedido', failure.message, snackPosition: SnackPosition.TOP);
          return null;
        },
        (order) async {
          clearOrderCart();
          orders.insert(0, order);
          safeSnackbar('Pedido registrado', 'Pedido ${order.formattedNumber} registrado correctamente', snackPosition: SnackPosition.TOP);
          await printOrder(order);
          return order;
        },
      );
    } finally {
      isCreatingOrder.value = false;
    }
  }

  Future<void> printOrder(VegetableOrder order) async {
    try {
      await orderPdfService.printOrder(order);
    } catch (e) {
      safeSnackbar('Error al generar el PDF', e.toString(), snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> shareOrderPdf(VegetableOrder order) async {
    try {
      await orderPdfService.shareOrderPdf(order);
    } catch (e) {
      safeSnackbar('Error al generar el PDF', e.toString(), snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> loadOrders() async {
    try {
      isLoadingOrders.value = true;
      final result = await getVegetableOrdersUseCase();
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar los pedidos: ${failure.message}', snackPosition: SnackPosition.TOP),
        (loaded) => orders.assignAll(loaded),
      );
    } finally {
      isLoadingOrders.value = false;
    }
  }

  Future<void> loadOrderById(String id) async {
    try {
      isLoadingOrderDetail.value = true;
      selectedOrder.value = null;
      final result = await getVegetableOrderByIdUseCase(id);
      result.fold(
        (failure) => safeSnackbar('Error', 'Error al cargar el pedido: ${failure.message}', snackPosition: SnackPosition.TOP),
        (order) => selectedOrder.value = order,
      );
    } finally {
      isLoadingOrderDetail.value = false;
    }
  }
}
