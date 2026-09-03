import 'package:get/get.dart';

import '../../../../app/core/di/service_locator.dart';
import '../controllers/vegetables_controller.dart';
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

/// GetX binding for the Vegetables (Verduras) feature
class VegetablesBinding extends Bindings {
  @override
  void dependencies() {
    // VegetablesController mantiene la conexión en vivo con la báscula
    // (puerto serial). Debe sobrevivir mientras se navega entre las
    // pantallas de verduras (venta, configuración de báscula, catálogo,
    // etc.); si se registrara con lazyPut/fenix, GetX lo destruiría al
    // salir de una de esas pantallas y onClose() cerraría la báscula real,
    // dejando "báscula no conectada" en el resto de pantallas aunque el
    // puerto siga guardado correctamente.
    if (!Get.isRegistered<VegetablesController>()) {
      Get.put<VegetablesController>(
        VegetablesController(
          getVegetableCategoriesUseCase: getIt<GetVegetableCategoriesUseCase>(),
          saveVegetableCategoryUseCase: getIt<SaveVegetableCategoryUseCase>(),
          deleteVegetableCategoryUseCase: getIt<DeleteVegetableCategoryUseCase>(),
          getVegetableItemsUseCase: getIt<GetVegetableItemsUseCase>(),
          saveVegetableItemUseCase: getIt<SaveVegetableItemUseCase>(),
          deleteVegetableItemUseCase: getIt<DeleteVegetableItemUseCase>(),
          createVegetableSaleUseCase: getIt<CreateVegetableSaleUseCase>(),
          getVegetableSalesUseCase: getIt<GetVegetableSalesUseCase>(),
          getVegetableSaleByIdUseCase: getIt<GetVegetableSaleByIdUseCase>(),
          createVegetableOrderUseCase: getIt<CreateVegetableOrderUseCase>(),
          getVegetableOrdersUseCase: getIt<GetVegetableOrdersUseCase>(),
          getVegetableOrderByIdUseCase: getIt<GetVegetableOrderByIdUseCase>(),
          scaleService: getIt<ScaleService>(),
          printerService: getIt<VegetablePrinterService>(),
          orderPdfService: getIt<VegetableOrderPdfService>(),
        ),
        permanent: true,
      );
    }
  }
}
