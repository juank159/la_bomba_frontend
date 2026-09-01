import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../products/domain/entities/product.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../clients/domain/entities/client.dart';
import '../../../clients/domain/usecases/get_clients_usecase.dart';
import '../../../credits/domain/entities/payment_method.dart';
import '../../../credits/domain/usecases/payment_method_usecases.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoices_repository.dart';
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';

/// Wraps Get.snackbar() so a missing Overlay can't crash the calling code.
/// See orders_controller.dart's safeSnackbar for the full incident writeup:
/// Get.snackbar() enqueues its actual Overlay lookup on a later frame, so a
/// synchronous try/catch around it doesn't catch anything - the fix is to
/// defer the call itself until the current frame/navigation has settled.
///
/// Extra hardening for Invoices specifically: several call sites here fire
/// right on page entry (onInit()/initState()), immediately after
/// Get.offAllNamed() tore down the previous route's whole widget tree. Even
/// one addPostFrameCallback frame later, GetX's navigator key may not have
/// finished attaching the new route's Overlay yet, and Get.snackbar()'s
/// internal GetQueue schedules the real Overlay lookup on a further
/// microtask outside this function's try/catch - so a plain postFrameCallback
/// isn't always enough. Adding a short delay (route transitions in this app
/// take 300ms) gives the new Overlay time to mount before we touch it.
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

/// A single line in the invoice being built (not yet persisted)
class InvoiceCartLine {
  final Product product;
  final int quantity;

  const InvoiceCartLine({required this.product, required this.quantity});

  // precioA ya incluye el IVA: el total de la línea es siempre precio*cantidad,
  // y el IVA se extrae de ahí (no se suma encima).
  double get total => product.precioA * quantity;
  double get taxAmount => total - total / (1 + product.iva / 100);
  double get subtotal => total - taxAmount;

  InvoiceCartLine copyWith({Product? product, int? quantity}) {
    return InvoiceCartLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Controller for the invoicing (Facturación) feature: cart-based POS flow
/// plus invoice listing, detail and cancellation.
class InvoicesController extends GetxController {
  final CreateInvoiceUseCase createInvoiceUseCase;
  final GetInvoicesUseCase getInvoicesUseCase;
  final GetInvoiceByIdUseCase getInvoiceByIdUseCase;
  final CancelInvoiceUseCase cancelInvoiceUseCase;
  final GetProductsUseCase getProductsUseCase;
  final GetClientsUseCase getClientsUseCase;
  final GetAllPaymentMethodsUseCase getAllPaymentMethodsUseCase;

  InvoicesController({
    required this.createInvoiceUseCase,
    required this.getInvoicesUseCase,
    required this.getInvoiceByIdUseCase,
    required this.cancelInvoiceUseCase,
    required this.getProductsUseCase,
    required this.getClientsUseCase,
    required this.getAllPaymentMethodsUseCase,
  });

  // ---- Cart / POS state ----
  final RxList<InvoiceCartLine> cart = <InvoiceCartLine>[].obs;
  final Rx<Client?> selectedClient = Rx<Client?>(null);
  final Rx<PaymentMethod?> selectedPaymentMethod = Rx<PaymentMethod?>(null);
  final RxBool isScanningBarcode = false.obs;
  final RxBool isSearchingProduct = false.obs;
  final RxBool isCreatingInvoice = false.obs;

  // ---- Payment methods / clients ----
  final RxList<PaymentMethod> paymentMethods = <PaymentMethod>[].obs;
  final RxList<Client> clients = <Client>[].obs;
  final RxBool isLoadingPaymentMethods = false.obs;
  final RxBool isLoadingClients = false.obs;

  // ---- Invoice list / detail state ----
  final RxList<Invoice> invoices = <Invoice>[].obs;
  final Rx<Invoice?> selectedInvoice = Rx<Invoice?>(null);
  final RxBool isLoadingInvoices = false.obs;
  final RxBool isLoadingInvoiceDetail = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPaymentMethods();
  }

  // ==========================================================================
  // Cart totals
  // ==========================================================================

  double get cartSubtotal => cart.fold(0.0, (sum, line) => sum + line.subtotal);
  double get cartTax => cart.fold(0.0, (sum, line) => sum + line.taxAmount);
  double get cartTotal => cart.fold(0.0, (sum, line) => sum + line.total);
  int get cartItemCount => cart.fold(0, (sum, line) => sum + line.quantity);
  bool get cartIsEmpty => cart.isEmpty;

  // ==========================================================================
  // Barcode scanning / product lookup
  // ==========================================================================

  Future<void> handleBarcodeScanned(String barcode) async {
    isScanningBarcode.value = false;

    final code = barcode.trim();
    if (code.isEmpty) return;

    try {
      isSearchingProduct.value = true;

      final result = await getProductsUseCase(
        GetProductsParams(page: 0, limit: 50, search: code),
      );

      result.fold(
        (failure) {
          safeSnackbar(
            'Error de búsqueda',
            'Error al buscar el producto: ${failure.message}',
            snackPosition: SnackPosition.TOP,
          );
        },
        (products) {
          final match = products.where((p) => p.barcode == code).isNotEmpty
              ? products.firstWhere((p) => p.barcode == code)
              : (products.isNotEmpty ? products.first : null);

          if (match == null) {
            safeSnackbar(
              'Producto no encontrado',
              'No se encontró ningún producto con el código $code',
              snackPosition: SnackPosition.TOP,
            );
            return;
          }

          addProductToCart(match);
        },
      );
    } finally {
      isSearchingProduct.value = false;
    }
  }

  // ==========================================================================
  // Cart operations
  // ==========================================================================

  void addProductToCart(Product product, {int quantity = 1}) {
    final index = cart.indexWhere((line) => line.product.id == product.id);

    if (index >= 0) {
      final existing = cart[index];
      cart[index] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      cart.add(InvoiceCartLine(product: product, quantity: quantity));
    }

    // Nota: no se usa safeSnackbar() aquí a propósito. Este método se llama
    // justo después de Get.offAllNamed('/invoices/create'), que acaba de
    // destruir toda la pila de rutas anterior; en ese instante el Overlay
    // que GetX necesita para el snackbar aún no está listo y la llamada
    // truena con "No Overlay widget found" incluso diferida con
    // addPostFrameCallback (el fallo real ocurre dentro del GetQueue interno
    // de GetX, en un microtask fuera del try/catch de safeSnackbar).
    // El producto agregado ya es visible de inmediato en la lista del
    // carrito, así que el toast no hace falta para dar feedback al usuario.
  }

  void updateCartQuantity(String productId, int quantity) {
    final index = cart.indexWhere((line) => line.product.id == productId);
    if (index < 0) return;

    if (quantity <= 0) {
      cart.removeAt(index);
    } else {
      cart[index] = cart[index].copyWith(quantity: quantity);
    }
  }

  void removeFromCart(String productId) {
    cart.removeWhere((line) => line.product.id == productId);
  }

  void clearCart() {
    cart.clear();
    selectedClient.value = null;
    _selectDefaultPaymentMethod();
  }

  /// Selecciona "Efectivo" como método de pago por defecto (o el primero
  /// disponible si no existe uno llamado así).
  void _selectDefaultPaymentMethod() {
    if (paymentMethods.isEmpty) {
      selectedPaymentMethod.value = null;
      return;
    }

    selectedPaymentMethod.value = paymentMethods.firstWhere(
      (m) => m.name.trim().toLowerCase() == 'efectivo',
      orElse: () => paymentMethods.first,
    );
  }

  void selectClient(Client? client) {
    selectedClient.value = client;
  }

  void selectPaymentMethod(PaymentMethod? method) {
    selectedPaymentMethod.value = method;
  }

  // ==========================================================================
  // Checkout
  // ==========================================================================

  Future<Invoice?> checkout() async {
    if (cart.isEmpty) {
      safeSnackbar(
        'Carrito vacío',
        'Agrega al menos un producto antes de facturar',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    }

    if (selectedPaymentMethod.value == null) {
      safeSnackbar(
        'Método de pago requerido',
        'Selecciona un método de pago para continuar',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    }

    try {
      isCreatingInvoice.value = true;

      final params = CreateInvoiceParams(
        clientId: selectedClient.value?.id,
        paymentMethodId: selectedPaymentMethod.value!.id,
        items: cart
            .map((line) => CreateInvoiceItemParams(
                  productId: line.product.id,
                  quantity: line.quantity,
                ))
            .toList(),
      );

      final result = await createInvoiceUseCase(params);

      return result.fold(
        (failure) {
          safeSnackbar(
            'Error al crear la factura',
            failure.message,
            snackPosition: SnackPosition.TOP,
          );
          return null;
        },
        (invoice) {
          clearCart();
          invoices.insert(0, invoice);
          safeSnackbar(
            'Factura creada',
            'Factura ${invoice.formattedNumber} creada correctamente',
            snackPosition: SnackPosition.TOP,
          );
          return invoice;
        },
      );
    } finally {
      isCreatingInvoice.value = false;
    }
  }

  // ==========================================================================
  // Payment methods / clients loading
  // ==========================================================================

  Future<void> loadPaymentMethods() async {
    try {
      isLoadingPaymentMethods.value = true;
      final result = await getAllPaymentMethodsUseCase();
      result.fold(
        (failure) {
          safeSnackbar(
            'Error',
            'Error al cargar métodos de pago: ${failure.message}',
            snackPosition: SnackPosition.TOP,
          );
        },
        (methods) {
          paymentMethods.assignAll(methods.where((m) => m.isActive));
          if (selectedPaymentMethod.value == null) {
            _selectDefaultPaymentMethod();
          }
        },
      );
    } finally {
      isLoadingPaymentMethods.value = false;
    }
  }

  Future<void> searchClients(String query) async {
    try {
      isLoadingClients.value = true;
      final result = await getClientsUseCase(
        GetClientsParams(search: query, limit: 20),
      );
      result.fold(
        (failure) => clients.clear(),
        (loadedClients) => clients.assignAll(loadedClients),
      );
    } finally {
      isLoadingClients.value = false;
    }
  }

  // ==========================================================================
  // Invoice list / detail
  // ==========================================================================

  Future<void> loadInvoices() async {
    try {
      isLoadingInvoices.value = true;
      errorMessage.value = '';

      final result = await getInvoicesUseCase();
      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          safeSnackbar(
            'Error',
            'Error al cargar facturas: ${failure.message}',
            snackPosition: SnackPosition.TOP,
          );
        },
        (loadedInvoices) => invoices.assignAll(loadedInvoices),
      );
    } finally {
      isLoadingInvoices.value = false;
    }
  }

  Future<void> loadInvoiceById(String id) async {
    try {
      isLoadingInvoiceDetail.value = true;
      selectedInvoice.value = null;

      final result = await getInvoiceByIdUseCase(GetInvoiceByIdParams(id: id));
      result.fold(
        (failure) {
          safeSnackbar(
            'Error',
            'Error al cargar la factura: ${failure.message}',
            snackPosition: SnackPosition.TOP,
          );
        },
        (invoice) => selectedInvoice.value = invoice,
      );
    } finally {
      isLoadingInvoiceDetail.value = false;
    }
  }

  Future<bool> cancelInvoice(String id) async {
    final result = await cancelInvoiceUseCase(id);

    return result.fold(
      (failure) {
        safeSnackbar(
          'Error',
          'No se pudo anular la factura: ${failure.message}',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      },
      (updatedInvoice) {
        selectedInvoice.value = updatedInvoice;
        final index = invoices.indexWhere((inv) => inv.id == updatedInvoice.id);
        if (index >= 0) {
          invoices[index] = updatedInvoice;
        }
        safeSnackbar(
          'Factura anulada',
          'La factura ${updatedInvoice.formattedNumber} fue anulada',
          snackPosition: SnackPosition.TOP,
        );
        return true;
      },
    );
  }
}
