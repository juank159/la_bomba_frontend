import 'package:get/get.dart';

import '../../../../app/core/di/service_locator.dart';
import '../controllers/vegetables_controller.dart';
import '../../domain/usecases/get_vegetable_items_usecase.dart';
import '../../domain/usecases/save_vegetable_item_usecase.dart';
import '../../domain/usecases/delete_vegetable_item_usecase.dart';
import '../../domain/usecases/create_vegetable_sale_usecase.dart';
import '../../domain/usecases/get_vegetable_sales_usecase.dart';
import '../../data/services/scale_service.dart';
import '../../data/services/vegetable_printer_service.dart';

/// GetX binding for the Vegetables (Verduras) feature
class VegetablesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VegetablesController>(
      () => VegetablesController(
        getVegetableItemsUseCase: getIt<GetVegetableItemsUseCase>(),
        saveVegetableItemUseCase: getIt<SaveVegetableItemUseCase>(),
        deleteVegetableItemUseCase: getIt<DeleteVegetableItemUseCase>(),
        createVegetableSaleUseCase: getIt<CreateVegetableSaleUseCase>(),
        getVegetableSalesUseCase: getIt<GetVegetableSalesUseCase>(),
        getVegetableSaleByIdUseCase: getIt<GetVegetableSaleByIdUseCase>(),
        scaleService: getIt<ScaleService>(),
        printerService: getIt<VegetablePrinterService>(),
      ),
      fenix: true,
    );
  }
}
