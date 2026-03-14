//lib/app/shared/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../../core/controllers/theme_controller.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/admin_tasks/presentation/controllers/admin_tasks_controller.dart';
import '../../../features/supervisor/presentation/controllers/supervisor_controller.dart';
import '../../../features/supervisor/presentation/bindings/supervisor_binding.dart';
import '../../../features/credits/presentation/pages/client_balances_page.dart';
import '../../../features/admin/presentation/pages/admin_settings_page.dart';
import '../../core/network/dio_client.dart';
import '../../core/di/service_locator.dart';

/// Navigation drawer widget for the app
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  AuthController get _authController => Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    // Inicializar controllers proactivamente basado en el rol
    _initializeControllersForRole();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            _buildDrawerHeader(context),

            // Navigation items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _buildNavigationItems(),
              ),
            ),

            // Footer with logout
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  /// Build the drawer header with user information
  Widget _buildDrawerHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar and close button row
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person_outline,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConfig.paddingSmall),

              // User info
              Text(
                _authController.userDisplayName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppConfig.titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (_authController.user?.username ?? "").isNotEmpty
                    ? '${_authController.user?.username ?? ""}@ejemplo.com'
                    : 'usuario@ejemplo.com',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: AppConfig.bodyFontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConfig.paddingMedium),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConfig.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      (_authController.user?.role.displayName ?? "")
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppConfig.captionFontSize - 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConfig.paddingSmall),
            ],
          ),
        ),
    );
  }

  /// Build a navigation item for the drawer
  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
    int? badgeCount,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final textColor = theme.colorScheme.onSurface;
        final subtitleColor = theme.colorScheme.onSurfaceVariant;
        final disabledColor = theme.disabledColor;

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppConfig.paddingSmall,
            vertical: 1,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConfig.paddingSmall,
                  vertical: AppConfig.paddingSmall,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: enabled
                            ? primaryColor.withValues(alpha: 0.1)
                            : disabledColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: enabled ? primaryColor : disabledColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConfig.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: AppConfig.bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: enabled ? textColor : disabledColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: AppConfig.captionFontSize,
                              color: enabled ? subtitleColor : disabledColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                    if (!enabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Próximamente',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build the drawer footer with change password and logout options
  Widget _buildDrawerFooter() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final errorColor = theme.colorScheme.error;
        final primaryColor = theme.colorScheme.primary;
        final subtitleColor = theme.colorScheme.onSurfaceVariant;
        final borderColor = theme.colorScheme.outlineVariant;

        return Container(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Change password
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showChangePasswordDialog(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingSmall,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.lock_reset_outlined, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: AppConfig.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cambiar Contraseña',
                                style: TextStyle(fontSize: AppConfig.bodyFontSize, fontWeight: FontWeight.w600, color: primaryColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Actualizar tu contraseña',
                                style: TextStyle(fontSize: AppConfig.captionFontSize, color: subtitleColor),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: subtitleColor, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Logout
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showLogoutDialog(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConfig.paddingSmall,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.logout_outlined, color: errorColor, size: 20),
                        ),
                        const SizedBox(width: AppConfig.paddingMedium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cerrar Sesión',
                                style: TextStyle(fontSize: AppConfig.bodyFontSize, fontWeight: FontWeight.w600, color: errorColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Salir de la aplicación',
                                style: TextStyle(fontSize: AppConfig.captionFontSize, color: subtitleColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigate to products screen
  void _navigateToProducts() {
    Get.back(); // Close drawer
    Get.offAllNamed('/products');
  }

  /// Navigate to orders screen
  void _navigateToOrders() {
    Get.back(); // Close drawer
    Get.offAllNamed('/orders');
  }

  /// Navigate to clients screen
  void _navigateToClients() {
    Get.back(); // Close drawer
    Get.offAllNamed('/clients');
  }

  /// Navigate to suppliers screen
  void _navigateToSuppliers() {
    Get.back(); // Close drawer
    Get.offAllNamed('/suppliers');
  }

  /// Navigate to credits screen (Admin only)
  void _navigateToCredits() {
    Get.back(); // Close drawer
    Get.offAllNamed('/credits');
  }

  /// Navigate to client balances screen (Admin only)
  void _navigateToClientBalances() {
    Get.back(); // Close drawer
    Get.to(() => ClientBalancesPage());
  }

  /// Navigate to expenses screen (Admin only)
  void _navigateToExpenses() {
    Get.back(); // Close drawer
    Get.offAllNamed('/expenses');
  }

  /// Navigate to incomes screen (Admin only)
  void _navigateToIncomes() {
    Get.back(); // Close drawer
    Get.offAllNamed('/incomes');
  }

  /// Navigate to admin settings screen (Admin only)
  void _navigateToAdminSettings() {
    Get.back(); // Close drawer
    Get.to(() => const AdminSettingsPage());
  }

  /// Show coming soon dialog
  void _showComingSoon(String feature) {
    Get.back(); // Close drawer
    Get.snackbar(
      'Próximamente',
      '$feature estará disponible pronto',
      icon: Icon(Icons.info_outline, color: Colors.blue),
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      colorText: Colors.blue[800],
      duration: const Duration(seconds: 2),
    );
  }

  /// Build navigation items based on user role
  List<Widget> _buildNavigationItems() {
    List<Widget> items = [];

    // Admin has access to EVERYTHING
    if (_authController.isAdmin) {
      items.addAll([
        // Basic navigation for admin
        _buildNavigationItem(
          icon: Icons.inventory_2_outlined,
          title: 'Productos',
          subtitle: 'Ver catálogo de productos',
          onTap: () => _navigateToProducts(),
        ),
        const Divider(),
        _buildNavigationItem(
          icon: Icons.shopping_cart_outlined,
          title: 'Pedidos',
          subtitle: 'Gestionar pedidos',
          onTap: () => _navigateToOrders(),
        ),
        _buildNavigationItem(
          icon: Icons.people_outlined,
          title: 'Clientes',
          subtitle: 'Gestionar clientes',
          onTap: () => _navigateToClients(),
        ),
        _buildNavigationItem(
          icon: Icons.business_outlined,
          title: 'Proveedores',
          subtitle: 'Gestionar proveedores',
          onTap: () => _navigateToSuppliers(),
        ),

        // Supervisor functionality for admin
        _buildAdminSupervisorTasksItem(),

        // Admin tasks
        _buildAdminTasksItem(),

        // Additional admin features
        _buildNavigationItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Créditos',
          subtitle: 'Gestionar créditos y pagos',
          onTap: () => _navigateToCredits(),
          enabled: true,
        ),
        _buildNavigationItem(
          icon: Icons.savings_outlined,
          title: 'Saldos de Clientes',
          subtitle: 'Saldos a favor y devoluciones',
          onTap: () => _navigateToClientBalances(),
          enabled: true,
        ),
        _buildNavigationItem(
          icon: Icons.receipt_long_outlined,
          title: 'Gastos',
          subtitle: 'Registrar gastos',
          onTap: () => _navigateToExpenses(),
          enabled: true,
        ),
        _buildNavigationItem(
          icon: Icons.trending_up_outlined,
          title: 'Ingresos',
          subtitle: 'Registrar ventas diarias',
          onTap: () => _navigateToIncomes(),
          enabled: true,
        ),

        const Divider(),
        _buildNavigationItem(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Administración',
          subtitle: 'Configuración del sistema',
          onTap: () => _navigateToAdminSettings(),
          enabled: true,
        ),
        _buildThemeItem(),
      ]);
    }
    // Supervisor specific items
    else if (_authController.isSupervisor) {
      items.addAll([
        _buildNavigationItem(
          icon: Icons.inventory_2_outlined,
          title: 'Productos',
          subtitle: 'Ver catálogo de productos',
          onTap: () => _navigateToProducts(),
        ),
        const Divider(),
        _buildNavigationItem(
          icon: Icons.shopping_cart_outlined,
          title: 'Pedidos',
          subtitle: 'Gestionar pedidos',
          onTap: () => _navigateToOrders(),
        ),
        _buildNavigationItem(
          icon: Icons.people_outlined,
          title: 'Clientes',
          subtitle: 'Gestionar clientes',
          onTap: () => _navigateToClients(),
        ),
        _buildNavigationItem(
          icon: Icons.business_outlined,
          title: 'Proveedores',
          subtitle: 'Gestionar proveedores',
          onTap: () => _navigateToSuppliers(),
        ),

        // Mis Tareas con contador reactivo
        _buildSupervisorTasksItem(),

        const Divider(),
        _buildThemeItem(),
      ]);
    }
    // Employee specific items
    else if (_authController.isEmployee) {
      items.addAll([
        _buildNavigationItem(
          icon: Icons.inventory_2_outlined,
          title: 'Productos',
          subtitle: 'Ver catálogo de productos',
          onTap: () => _navigateToProducts(),
        ),
        const Divider(),
        _buildNavigationItem(
          icon: Icons.shopping_cart_outlined,
          title: 'Pedidos',
          subtitle: 'Gestionar pedidos',
          onTap: () => _navigateToOrders(),
        ),
        _buildNavigationItem(
          icon: Icons.people_outlined,
          title: 'Clientes',
          subtitle: 'Ver clientes',
          onTap: () => _navigateToClients(),
        ),
        _buildNavigationItem(
          icon: Icons.business_outlined,
          title: 'Proveedores',
          subtitle: 'Ver proveedores',
          onTap: () => _navigateToSuppliers(),
        ),

        const Divider(),
        _buildThemeItem(),
      ]);
    }

    return items;
  }

  /// Navigate to supervisor main page
  void _navigateToSupervisor() {
    Get.back(); // Close drawer
    Get.offAllNamed('/supervisor');
  }

  /// Navigate to admin tasks screen (Admin only)
  void _navigateToAdminTasks() {
    Get.back(); // Close drawer
    Get.offAllNamed('/admin-tasks');
  }

  /// Build supervisor tasks item for supervisor role
  Widget _buildSupervisorTasksItem() {
    // Intentar obtener el controller y inicializarlo si no existe
    SupervisorController? controller;
    try {
      if (Get.isRegistered<SupervisorController>()) {
        controller = Get.find<SupervisorController>();

        // Retornar con badge reactivo
        return Obx(() {
          final count = controller!.pendingTemporaryProductsCount;
          print('🔵 DRAWER SUPERVISOR - Contador de tareas: $count');
          print('🔵 DRAWER SUPERVISOR - Lista de tareas: ${controller.pendingTemporaryProducts.length}');
          return _buildNavigationItem(
            icon: Icons.task_outlined,
            title: 'Mis Tareas',
            subtitle: 'Productos nuevos pendientes',
            onTap: () => _navigateToSupervisor(),
            badgeCount: count,
          );
        });
      } else {
        print('⚠️ DRAWER SUPERVISOR - SupervisorController NO está registrado');
      }
    } catch (e) {
      // Error obteniendo controller
      print('❌ DRAWER SUPERVISOR - Error obteniendo SupervisorController: $e');
    }

    // Si no está registrado o hubo error, mostrar sin badge
    print('⚠️ DRAWER SUPERVISOR - Mostrando item SIN badge');
    return _buildNavigationItem(
      icon: Icons.task_outlined,
      title: 'Mis Tareas',
      subtitle: 'Productos nuevos pendientes',
      onTap: () => _navigateToSupervisor(),
    );
  }

  /// Build admin supervisor tasks item for admin role
  Widget _buildAdminSupervisorTasksItem() {
    SupervisorController? controller;
    try {
      if (Get.isRegistered<SupervisorController>()) {
        controller = Get.find<SupervisorController>();

        return Obx(() {
          final count = controller!.pendingTemporaryProductsCount;
          return _buildNavigationItem(
            icon: Icons.supervisor_account_outlined,
            title: 'Tareas Supervisor',
            subtitle: 'Productos nuevos pendientes',
            onTap: () => _navigateToSupervisor(),
            badgeCount: count,
          );
        });
      }
    } catch (e) {
      print('Error obteniendo SupervisorController en drawer (admin): $e');
    }

    return _buildNavigationItem(
      icon: Icons.supervisor_account_outlined,
      title: 'Tareas Supervisor',
      subtitle: 'Productos nuevos pendientes',
      onTap: () => _navigateToSupervisor(),
    );
  }

  /// Build admin tasks item for admin role
  Widget _buildAdminTasksItem() {
    AdminTasksController? controller;
    try {
      if (Get.isRegistered<AdminTasksController>()) {
        controller = Get.find<AdminTasksController>();

        return Obx(() {
          final count = controller!.pendingCount;
          return _buildNavigationItem(
            icon: Icons.task_outlined,
            title: 'Mis Tareas',
            subtitle: 'Productos temporales pendientes',
            onTap: () => _navigateToAdminTasks(),
            badgeCount: count,
          );
        });
      }
    } catch (e) {
      print('Error obteniendo AdminTasksController en drawer: $e');
    }

    return _buildNavigationItem(
      icon: Icons.task_outlined,
      title: 'Mis Tareas',
      subtitle: 'Productos temporales pendientes',
      onTap: () => _navigateToAdminTasks(),
    );
  }

  /// Initialize controllers proactively based on user role
  void _initializeControllersForRole() {
    try {
      // Para Supervisor: inicializar SupervisorController
      if (_authController.isSupervisor) {
        if (!Get.isRegistered<SupervisorController>()) {
          // Inicializar el binding que registra el controller
          SupervisorBinding().dependencies();

          // Forzar la creación del controller accediendo a él
          try {
            final controller = Get.find<SupervisorController>();
            // El controller ya está inicializado y debería estar cargando datos
            print('SupervisorController inicializado para supervisor. Tareas pendientes: ${controller.pendingTemporaryProductsCount}');
          } catch (e) {
            print('Error accediendo al SupervisorController después del binding: $e');
          }
        }
      }

      // Para Admin: inicializar ambos controllers
      if (_authController.isAdmin) {
        if (!Get.isRegistered<SupervisorController>()) {
          SupervisorBinding().dependencies();

          try {
            final controller = Get.find<SupervisorController>();
            print('SupervisorController inicializado para admin. Tareas pendientes: ${controller.pendingTemporaryProductsCount}');
          } catch (e) {
            print('Error accediendo al SupervisorController después del binding (admin): $e');
          }
        }
        // AdminTasksController se inicializa en su propia página
        // pero podríamos inicializarlo aquí también si es necesario
      }
    } catch (e) {
      print('Error inicializando controllers en drawer: $e');
    }
  }

  /// Build theme selector item
  Widget _buildThemeItem() {
    try {
      final themeController = Get.find<ThemeController>();

      return Obx(() {
        return _buildNavigationItem(
          icon: themeController.themeModeIcon,
          title: 'Tema',
          subtitle: '${themeController.themeModeString} • ${themeController.themeColorString}',
          onTap: () => _showThemeDialog(),
        );
      });
    } catch (e) {
      // If ThemeController is not registered, show a static item
      return _buildNavigationItem(
        icon: Icons.brightness_auto,
        title: 'Tema',
        subtitle: 'Cambiar apariencia',
        onTap: () => _showThemeDialog(),
      );
    }
  }

  /// Show theme selection dialog
  void _showThemeDialog() {
    Get.back(); // Close drawer

    try {
      final themeController = Get.find<ThemeController>();
      final theme = Get.theme;
      final isSmallScreen = Get.width < 600;

      Get.dialog(
        AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: theme.colorScheme.primary,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Text(
                  'Personalizar Tema',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brightness Section
                Text(
                  'Modo de Apariencia',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Obx(() => _buildThemeOption(
                  icon: Icons.light_mode,
                  title: 'Claro',
                  subtitle: 'Apariencia clara',
                  color: Colors.orange,
                  isSelected: themeController.themeMode == ThemeMode.light,
                  onTap: () => themeController.setLightTheme(),
                )),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Obx(() => _buildThemeOption(
                  icon: Icons.dark_mode,
                  title: 'Oscuro',
                  subtitle: 'Apariencia oscura',
                  color: Colors.indigo,
                  isSelected: themeController.themeMode == ThemeMode.dark,
                  onTap: () => themeController.setDarkTheme(),
                )),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Obx(() => _buildThemeOption(
                  icon: Icons.brightness_auto,
                  title: 'Sistema',
                  subtitle: 'Seguir configuración del sistema',
                  color: Colors.teal,
                  isSelected: themeController.themeMode == ThemeMode.system,
                  onTap: () => themeController.setSystemTheme(),
                )),

                SizedBox(height: isSmallScreen ? 16 : 20),
                Divider(color: theme.colorScheme.outlineVariant),
                SizedBox(height: isSmallScreen ? 16 : 20),

                // Color Section
                Text(
                  'Color del Tema',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Wrap(
                  spacing: isSmallScreen ? 8 : 12,
                  runSpacing: isSmallScreen ? 8 : 12,
                  children: [
                    Obx(() => _buildColorOption(
                      color: AppConfig.blueColor,
                      label: 'Azul',
                      colorName: 'blue',
                      isSelected: themeController.themeColor == 'blue',
                      onTap: () => themeController.setThemeColor('blue'),
                    )),
                    Obx(() => _buildColorOption(
                      color: AppConfig.greenColor,
                      label: 'Verde',
                      colorName: 'green',
                      isSelected: themeController.themeColor == 'green',
                      onTap: () => themeController.setThemeColor('green'),
                    )),
                    Obx(() => _buildColorOption(
                      color: AppConfig.purpleColor,
                      label: 'Morado',
                      colorName: 'purple',
                      isSelected: themeController.themeColor == 'purple',
                      onTap: () => themeController.setThemeColor('purple'),
                    )),
                    Obx(() => _buildColorOption(
                      color: AppConfig.redColor,
                      label: 'Rojo',
                      colorName: 'red',
                      isSelected: themeController.themeColor == 'red',
                      onTap: () => themeController.setThemeColor('red'),
                    )),
                    Obx(() => _buildColorOption(
                      color: AppConfig.orangeColor,
                      label: 'Naranja',
                      colorName: 'orange',
                      isSelected: themeController.themeColor == 'orange',
                      onTap: () => themeController.setThemeColor('orange'),
                    )),
                    Obx(() => _buildColorOption(
                      color: AppConfig.pinkColor,
                      label: 'Rosa',
                      colorName: 'pink',
                      isSelected: themeController.themeColor == 'pink',
                      onTap: () => themeController.setThemeColor('pink'),
                    )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo abrir el selector de tema',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red[800],
      );
    }
  }

  /// Build a theme option widget
  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Get.theme;
    final isSmallScreen = Get.width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: isSmallScreen ? 20 : 24,
              ),
          ],
        ),
      ),
    );
  }

  /// Build a color option widget
  Widget _buildColorOption({
    required Color color,
    required String label,
    required String colorName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = Get.width < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isSmallScreen ? 80 : 95,
        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Get.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : Get.theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isSmallScreen ? 36 : 40,
              height: isSmallScreen ? 36 : 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    )
                  : null,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? color
                    : Get.theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Show change password dialog
  void _showChangePasswordDialog() {
    Get.back(); // Close drawer
    Get.dialog(
      _ChangePasswordDialog(),
      barrierDismissible: false,
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    Get.back(); // Close drawer
    Get.dialog(
      AlertDialog(
        title: Text(
          '¿Cerrar Sesión?',
          style: TextStyle(
            fontSize: AppConfig.titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(fontSize: AppConfig.bodyFontSize),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: AppConfig.bodyFontSize,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog
              await _authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: AppConfig.bodyFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Change password dialog as a StatefulWidget for proper lifecycle management
class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMsg = '';
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final dioClient = getIt<DioClient>();
      final response = await dioClient.post(
        '/auth/change-password',
        data: {
          'currentPassword': _currentPasswordController.text.trim(),
          'newPassword': _newPasswordController.text.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.of(context).pop();
        Get.snackbar(
          'Contraseña Actualizada',
          'Tu contraseña ha sido cambiada exitosamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('Unauthorized') || msg.contains('incorrecta')) {
        setState(() => _errorMsg = 'La contraseña actual es incorrecta');
      } else if (msg.contains('400') || msg.contains('6 caracteres')) {
        setState(() => _errorMsg = 'La nueva contraseña debe tener al menos 6 caracteres');
      } else {
        setState(() => _errorMsg = 'Error de conexion. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lock_reset, color: theme.colorScheme.primary, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cambiar Contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text(
                  'Ingresa tu contraseña actual y la nueva',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa tu contraseña actual';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // New password
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa la nueva contraseña';
                  if (v.trim().length < 6) return 'Minimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Confirm password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  prefixIcon: const Icon(Icons.lock_clock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Confirma la nueva contraseña';
                  if (v.trim() != _newPasswordController.text.trim()) return 'Las contraseñas no coinciden';
                  return null;
                },
                onFieldSubmitted: (_) => _changePassword(),
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMsg, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _changePassword,
          icon: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check, size: 18),
          label: Text(_isLoading ? 'Guardando...' : 'Cambiar Contraseña'),
        ),
      ],
    );
  }
}
