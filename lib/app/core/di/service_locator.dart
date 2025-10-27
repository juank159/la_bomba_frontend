//library: frontend/lib/app/core/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../storage/secure_storage.dart';
import '../services/text_to_speech_service.dart';
import '../services/pdf_service.dart';
import '../services/preferences_service.dart';
import '../controllers/theme_controller.dart';
import '../../../features/products/data/datasources/products_remote_datasource.dart';
import '../../../features/products/data/repositories/products_repository_impl.dart';
import '../../../features/products/domain/repositories/products_repository.dart';
import '../../../features/products/domain/usecases/get_products_usecase.dart';
import '../../../features/products/domain/usecases/update_product_usecase.dart';
import '../../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../features/auth/domain/usecases/login_usecase.dart';
import '../../../features/auth/domain/usecases/logout_usecase.dart';
import '../../../features/auth/domain/usecases/request_password_reset_usecase.dart';
import '../../../features/auth/domain/usecases/verify_reset_code_usecase.dart';
import '../../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import 'package:get/get.dart';
import '../../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../../features/orders/domain/repositories/orders_repository.dart';
import '../../../features/orders/domain/usecases/get_orders_usecase.dart';
import '../../../features/orders/domain/usecases/create_order_usecase.dart';
import '../../../features/orders/domain/usecases/update_order_usecase.dart';
import '../../../features/orders/domain/usecases/delete_order_usecase.dart';
import '../../../features/orders/domain/usecases/update_quantities_usecase.dart';
import '../../../features/orders/domain/usecases/get_order_grouped_by_supplier_usecase.dart';
import '../../../features/orders/domain/usecases/assign_supplier_to_item_usecase.dart';
import '../../../features/supervisor/data/datasources/supervisor_remote_data_source.dart';
import '../../../features/supervisor/data/repositories/supervisor_repository_impl.dart';
import '../../../features/supervisor/domain/repositories/supervisor_repository.dart';
import '../../../features/supervisor/domain/usecases/get_pending_tasks.dart';
import '../../../features/supervisor/domain/usecases/get_completed_tasks.dart';
import '../../../features/supervisor/domain/usecases/complete_task.dart';
import '../../../features/supervisor/domain/usecases/get_task_stats.dart';
import '../../../features/supervisor/domain/usecases/create_task.dart';
import '../../../features/clients/data/datasources/clients_remote_datasource.dart';
import '../../../features/clients/data/repositories/clients_repository_impl.dart';
import '../../../features/clients/domain/repositories/clients_repository.dart';
import '../../../features/clients/domain/usecases/get_clients_usecase.dart';
import '../../../features/clients/domain/usecases/create_client_usecase.dart';
import '../../../features/clients/domain/usecases/update_client_usecase.dart';
import '../../../features/clients/domain/usecases/delete_client_usecase.dart';
import '../../../features/suppliers/data/datasources/suppliers_remote_datasource.dart';
import '../../../features/suppliers/data/repositories/suppliers_repository_impl.dart';
import '../../../features/suppliers/domain/repositories/suppliers_repository.dart';
import '../../../features/suppliers/domain/usecases/get_suppliers_usecase.dart';
import '../../../features/suppliers/domain/usecases/create_supplier_usecase.dart';
import '../../../features/suppliers/domain/usecases/update_supplier_usecase.dart';
import '../../../features/suppliers/domain/usecases/delete_supplier_usecase.dart';
import '../../../features/credits/data/datasources/credits_remote_datasource.dart';
import '../../../features/credits/data/repositories/credits_repository_impl.dart';
import '../../../features/credits/domain/repositories/credits_repository.dart';
import '../../../features/credits/domain/usecases/credits_usecases.dart';
import '../../../features/expenses/data/datasources/expenses_remote_datasource.dart';
import '../../../features/expenses/data/repositories/expenses_repository_impl.dart';
import '../../../features/expenses/domain/repositories/expenses_repository.dart';
import '../../../features/expenses/domain/usecases/expenses_usecases.dart';
// Client Balance
import '../../../features/credits/data/datasources/client_balance_remote_datasource.dart';
import '../../../features/credits/data/repositories/client_balance_repository_impl.dart';
import '../../../features/credits/domain/repositories/client_balance_repository.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> initServiceLocator() async {
  // External dependencies
  getIt.registerLazySingleton(() => Dio());
  getIt.registerLazySingleton(() => const FlutterSecureStorage());
  getIt.registerLazySingleton(() => Connectivity());
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Core dependencies
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));

  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt()));

  getIt.registerLazySingleton<SecureStorage>(() => SecureStorageImpl(getIt()));

  // Services
  getIt.registerLazySingleton<TextToSpeechService>(() => TextToSpeechService());
  getIt.registerLazySingleton<PdfService>(() => PdfService());

  // Preferences Service (must be initialized)
  final preferencesService = PreferencesService();
  await preferencesService.init();
  getIt.registerLazySingleton<PreferencesService>(() => preferencesService);

  // Theme Controller with GetX
  Get.put(
    ThemeController(preferencesService: getIt()),
    permanent: true,
  );

  // Auth dependencies
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => LoginUseCase(getIt()));

  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));

  // Password recovery use cases
  getIt.registerLazySingleton(() => RequestPasswordResetUseCase(getIt()));

  getIt.registerLazySingleton(() => VerifyResetCodeUseCase(getIt()));

  getIt.registerLazySingleton(() => ResetPasswordUseCase(getIt()));

  // Register AuthController with GetX
  Get.put(
    AuthController(
      loginUseCase: getIt(),
      logoutUseCase: getIt(),
      authRepository: getIt(),
    ),
    permanent: true,
  );

  // Products dependencies
  getIt.registerLazySingleton<ProductsRemoteDataSource>(
    () => ProductsRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<ProductsRepository>(
    () => ProductsRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => GetProductsUseCase(getIt()));
  
  getIt.registerLazySingleton(() => GetProductByIdUseCase(getIt()));

  getIt.registerLazySingleton(() => UpdateProductUseCase(getIt()));

  // Orders dependencies
  getIt.registerLazySingleton<OrdersRemoteDataSource>(
    () => OrdersRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => GetOrdersUseCase(getIt()));

  getIt.registerLazySingleton(() => GetOrderByIdUseCase(getIt()));

  getIt.registerLazySingleton(() => CreateOrderUseCase(getIt()));

  getIt.registerLazySingleton(() => UpdateOrderUseCase(getIt()));

  getIt.registerLazySingleton(() => DeleteOrderUseCase(getIt()));

  getIt.registerLazySingleton(() => UpdateQuantitiesUseCase(getIt()));

  getIt.registerLazySingleton(() => GetOrderGroupedBySupplierUseCase(getIt()));

  getIt.registerLazySingleton(() => AssignSupplierToItemUseCase(getIt()));

  // Supervisor dependencies
  getIt.registerLazySingleton<SupervisorRemoteDataSource>(
    () => SupervisorRemoteDataSourceImpl(
      dioClient: getIt(),
    ),
  );

  getIt.registerLazySingleton<SupervisorRepository>(
    () => SupervisorRepositoryImpl(
      remoteDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => GetPendingTasks(getIt()));

  getIt.registerLazySingleton(() => GetCompletedTasks(getIt()));

  getIt.registerLazySingleton(() => CompleteTask(getIt()));

  getIt.registerLazySingleton(() => GetTaskStats(getIt()));

  getIt.registerLazySingleton(() => CreateTask(getIt()));

  // Clients dependencies
  getIt.registerLazySingleton<ClientsRemoteDataSource>(
    () => ClientsRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<ClientsRepository>(
    () => ClientsRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => GetClientsUseCase(getIt()));

  getIt.registerLazySingleton(() => GetClientByIdUseCase(getIt()));

  getIt.registerLazySingleton(() => CreateClientUseCase(getIt()));

  getIt.registerLazySingleton(() => UpdateClientUseCase(getIt()));

  getIt.registerLazySingleton(() => DeleteClientUseCase(getIt()));

  // Suppliers dependencies
  getIt.registerLazySingleton<SuppliersRemoteDataSource>(
    () => SuppliersRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<SuppliersRepository>(
    () => SuppliersRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => GetSuppliersUseCase(getIt()));

  getIt.registerLazySingleton(() => GetSupplierByIdUseCase(getIt()));

  getIt.registerLazySingleton(() => CreateSupplierUseCase(getIt()));

  getIt.registerLazySingleton(() => UpdateSupplierUseCase(getIt()));

  getIt.registerLazySingleton(() => DeleteSupplierUseCase(getIt()));

  // Credits dependencies
  getIt.registerLazySingleton<CreditsRemoteDataSource>(
    () => CreditsRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<CreditsRepository>(
    () => CreditsRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => GetCreditsUseCase(getIt()));

  getIt.registerLazySingleton(() => GetCreditByIdUseCase(getIt()));

  getIt.registerLazySingleton(() => CreateCreditUseCase(getIt()));

  getIt.registerLazySingleton(() => UpdateCreditUseCase(getIt()));

  getIt.registerLazySingleton(() => AddPaymentUseCase(getIt()));

  getIt.registerLazySingleton(() => RemovePaymentUseCase(getIt()));

  getIt.registerLazySingleton(() => DeleteCreditUseCase(getIt()));

  getIt.registerLazySingleton(() => GetPendingCreditByClientUseCase(getIt()));

  getIt.registerLazySingleton(() => AddAmountToCreditUseCase(getIt()));

  // Expenses dependencies
  getIt.registerLazySingleton<ExpensesRemoteDataSource>(
    () => ExpensesRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<ExpensesRepository>(
    () => ExpensesRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerLazySingleton(() => GetExpensesUseCase(getIt()));

  getIt.registerLazySingleton(() => GetExpenseByIdUseCase(getIt()));

  getIt.registerLazySingleton(() => CreateExpenseUseCase(getIt()));

  getIt.registerLazySingleton(() => UpdateExpenseUseCase(getIt()));

  getIt.registerLazySingleton(() => DeleteExpenseUseCase(getIt()));

  // ============================================================================
  // Client Balance (Saldo a Favor)
  // ============================================================================

  // DataSource
  getIt.registerLazySingleton<ClientBalanceRemoteDataSource>(
    () => ClientBalanceRemoteDataSourceImpl(getIt()),
  );

  // Repository
  getIt.registerLazySingleton<ClientBalanceRepository>(
    () => ClientBalanceRepositoryImpl(
      remoteDataSource: getIt<ClientBalanceRemoteDataSource>(),
    ),
  );

  print('✅ Service Locator initialized successfully');
}

/// Cleanup all dependencies
Future<void> cleanupServiceLocator() async {
  await getIt.reset();
  print('✅ Service Locator cleaned up successfully');
}
