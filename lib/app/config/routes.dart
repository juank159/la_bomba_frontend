import 'package:get/get.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_code_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/bindings/password_recovery_binding.dart';
import '../../features/products/presentation/pages/products_list_page.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/orders/presentation/pages/orders_list_page.dart';
import '../../features/orders/presentation/pages/create_order_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/edit_order_page.dart';
import '../../features/orders/presentation/bindings/orders_binding.dart';
import '../../features/supervisor/presentation/pages/supervisor_main_page.dart';
import '../../features/supervisor/presentation/bindings/supervisor_binding.dart';
import '../../features/admin_tasks/presentation/pages/admin_tasks_page.dart';
import '../../features/admin_tasks/presentation/bindings/admin_tasks_binding.dart';
import '../../features/clients/presentation/pages/clients_list_page.dart';
import '../../features/clients/presentation/pages/client_detail_page.dart';
import '../../features/suppliers/presentation/pages/suppliers_list_page.dart';
import '../../features/suppliers/presentation/pages/supplier_detail_page.dart';
import '../../features/credits/presentation/pages/credits_list_page.dart';
import '../../features/credits/presentation/pages/credit_detail_page.dart';
import '../../features/expenses/presentation/pages/expenses_list_page.dart';
import '../core/guards/auth_guard.dart';

/// Application route names
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  // Password recovery routes
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode = '/verify-code';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/detail';
  static const String createOrder = '/orders/create';
  static const String editOrder = '/orders/edit';
  static const String credits = '/credits';
  static const String creditDetail = '/credit-detail';
  static const String expenses = '/expenses';
  static const String expenseDetail = '/expense-detail';
  static const String todos = '/todos';
  static const String todoDetail = '/todo-detail';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String supervisor = '/supervisor';
  static const String supervisorDashboard = '/supervisor/dashboard';
  static const String adminTasks = '/admin-tasks';
  static const String clients = '/clients';
  static const String clientDetail = '/clients/:id';
  static const String suppliers = '/suppliers';
  static const String supplierDetail = '/suppliers/:id';
}

/// Application pages configuration for GetX routing
class AppPages {
  static const String initial = AppRoutes.splash;
  
  static List<GetPage> routes = [
    // Splash Screen
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Authentication Routes
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.register,
      page: () => const LoginPage(), // TODO: Replace with RegisterPage when implemented
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Password Recovery Routes
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
      binding: PasswordRecoveryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.verifyCode,
      page: () => const VerifyCodePage(),
      binding: PasswordRecoveryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordPage(),
      binding: PasswordRecoveryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Main App Routes
    GetPage(
      name: AppRoutes.home,
      page: () => const ProductsListPage(), // Using products as home for now
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Products Routes
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsListPage(),
      middlewares: [AuthGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.productDetail,
      page: () => ProductDetailPage(
        productId: Get.arguments?['productId'] ?? '13356647-9401-40e5-b68f-eb69f0c03a36',
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Orders Routes
    GetPage(
      name: AppRoutes.orders,
      page: () => const OrdersListPage(),
      binding: OrdersBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.orderDetail,
      page: () => OrderDetailPage(
        orderId: Get.arguments ?? '1',
      ),
      binding: OrdersBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.createOrder,
      page: () => const CreateOrderPage(),
      binding: OrdersBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.editOrder,
      page: () => const EditOrderPage(),
      binding: OrdersBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Credits Routes (Admin only)
    GetPage(
      name: AppRoutes.credits,
      page: () => const CreditsListPage(),
      middlewares: [AuthGuard(), AdminGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: '/credits/:id',
      page: () => CreditDetailPage(
        creditId: Get.parameters['id'] ?? '',
      ),
      middlewares: [AuthGuard(), AdminGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Expenses Routes (Admin only)
    GetPage(
      name: AppRoutes.expenses,
      page: () => const ExpensesListPage(),
      middlewares: [AuthGuard(), AdminGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Todos Routes
    GetPage(
      name: AppRoutes.todos,
      page: () => const ProductsListPage(), // TODO: Replace with TodosListPage when implemented
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.todoDetail,
      page: () => ProductDetailPage(
        productId: Get.parameters['todoId'] ?? '1', // TODO: Replace with TodoDetailPage when implemented
      ),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // User Profile Routes
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProductsListPage(), // TODO: Replace with ProfilePage when implemented
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    GetPage(
      name: AppRoutes.settings,
      page: () => const ProductsListPage(), // TODO: Replace with SettingsPage when implemented
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Supervisor Routes - Unified View
    GetPage(
      name: AppRoutes.supervisor,
      page: () => const SupervisorMainPage(),
      binding: SupervisorBinding(),
      middlewares: [SupervisorGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.supervisorDashboard,
      page: () => const SupervisorMainPage(),
      binding: SupervisorBinding(),
      middlewares: [SupervisorGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Admin Tasks Routes (Admin only)
    GetPage(
      name: AppRoutes.adminTasks,
      page: () => const AdminTasksPage(),
      binding: AdminTasksBinding(),
      middlewares: [AdminGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Clients Routes
    GetPage(
      name: AppRoutes.clients,
      page: () => const ClientsListPage(),
      middlewares: [AuthGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.clientDetail,
      page: () => ClientDetailPage(
        clientId: Get.parameters['id'] ?? '',
      ),
      middlewares: [AuthGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Suppliers Routes
    GetPage(
      name: AppRoutes.suppliers,
      page: () => const SuppliersListPage(),
      middlewares: [AuthGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: AppRoutes.supplierDetail,
      page: () => SupplierDetailPage(
        supplierId: Get.parameters['id'] ?? '',
      ),
      middlewares: [AuthGuard()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
  
  /// Navigate to a specific route
  static void toNamed(String routeName, {dynamic arguments}) {
    Get.toNamed(routeName, arguments: arguments);
  }
  
  /// Navigate to a specific route and clear all previous routes
  static void offAllNamed(String routeName, {dynamic arguments}) {
    Get.offAllNamed(routeName, arguments: arguments);
  }
  
  /// Navigate to a specific route and remove the current route
  static void offNamed(String routeName, {dynamic arguments}) {
    Get.offNamed(routeName, arguments: arguments);
  }
  
  /// Go back to the previous route
  static void back() {
    Get.back();
  }
  
  /// Check if we can go back
  static bool canGoBack() {
    return Get.key.currentState?.canPop() ?? false;
  }
  
  /// Get current route name
  static String? get currentRoute {
    return Get.currentRoute;
  }
  
  /// Navigate to login and clear all routes
  static void toLogin() {
    Get.offAllNamed(AppRoutes.login);
  }
  
  /// Navigate to home and clear all routes
  static void toHome() {
    Get.offAllNamed(AppRoutes.home);
  }
  
  /// Navigate to product detail with product ID
  static void toProductDetail(String productId) {
    Get.toNamed(AppRoutes.productDetail, arguments: {'productId': productId});
  }
  
  /// Navigate to order detail with order ID
  static void toOrderDetail(String orderId) {
    Get.toNamed(AppRoutes.orderDetail, arguments: {'orderId': orderId});
  }
  
  /// Navigate to credit detail with credit ID
  static void toCreditDetail(String creditId) {
    Get.toNamed(AppRoutes.creditDetail, arguments: {'creditId': creditId});
  }
  
  /// Navigate to expense detail with expense ID
  static void toExpenseDetail(String expenseId) {
    Get.toNamed(AppRoutes.expenseDetail, arguments: {'expenseId': expenseId});
  }
  
  /// Navigate to todo detail with todo ID
  static void toTodoDetail(String todoId) {
    Get.toNamed(AppRoutes.todoDetail, arguments: {'todoId': todoId});
  }
}