import 'package:get/get.dart';

import '../../../../app/core/di/service_locator.dart';
import '../controllers/orders_controller.dart';
import '../../domain/usecases/get_orders_usecase.dart' as get_orders;
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/update_order_usecase.dart';
import '../../domain/usecases/delete_order_usecase.dart';
import '../../domain/usecases/update_quantities_usecase.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../suppliers/domain/usecases/get_suppliers_usecase.dart';

/// GetX binding for Orders feature
class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    // Register OrdersController with all its dependencies
    Get.lazyPut<OrdersController>(
      () => OrdersController(
        getOrdersUseCase: getIt<get_orders.GetOrdersUseCase>(),
        getOrderByIdUseCase: getIt<get_orders.GetOrderByIdUseCase>(),
        createOrderUseCase: getIt<CreateOrderUseCase>(),
        updateOrderUseCase: getIt<UpdateOrderUseCase>(),
        deleteOrderUseCase: getIt<DeleteOrderUseCase>(),
        updateQuantitiesUseCase: getIt<UpdateQuantitiesUseCase>(),
        getProductsUseCase: getIt<GetProductsUseCase>(),
        getSuppliersUseCase: getIt<GetSuppliersUseCase>(),
      ),
      fenix: true, // Keep instance alive even when not in use
    );
  }
}