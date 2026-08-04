import 'package:get/get.dart';

import '../../../../app/core/di/service_locator.dart';
import '../controllers/invoices_controller.dart';
import '../../domain/usecases/create_invoice_usecase.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/cancel_invoice_usecase.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../clients/domain/usecases/get_clients_usecase.dart';
import '../../../credits/domain/usecases/payment_method_usecases.dart';

/// GetX binding for the Invoices (Facturación) feature
class InvoicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InvoicesController>(
      () => InvoicesController(
        createInvoiceUseCase: getIt<CreateInvoiceUseCase>(),
        getInvoicesUseCase: getIt<GetInvoicesUseCase>(),
        getInvoiceByIdUseCase: getIt<GetInvoiceByIdUseCase>(),
        cancelInvoiceUseCase: getIt<CancelInvoiceUseCase>(),
        getProductsUseCase: getIt<GetProductsUseCase>(),
        getClientsUseCase: getIt<GetClientsUseCase>(),
        getAllPaymentMethodsUseCase: getIt<GetAllPaymentMethodsUseCase>(),
      ),
      fenix: true,
    );
  }
}
