//lib /features/suppliers/presentation/pages/suppliers_list_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/suppliers_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/usecases/get_suppliers_usecase.dart';
import '../../domain/usecases/create_supplier_usecase.dart';
import '../../domain/usecases/update_supplier_usecase.dart';
import '../../domain/usecases/delete_supplier_usecase.dart';
import '../../../../app/core/di/service_locator.dart';
import '../widgets/supplier_card.dart';

/// SuppliersListPage - Main page showing list of suppliers with search and pagination
/// Features:
/// - Search by name, phone, email or address with debouncing
/// - Pull-to-refresh functionality
/// - Infinite scroll pagination
/// - Empty and error states
/// - Role-based access (all roles can view, admin and supervisor can create/edit)
class SuppliersListPage extends StatefulWidget {
  const SuppliersListPage({super.key});

  @override
  State<SuppliersListPage> createState() => _SuppliersListPageState();
}

class _SuppliersListPageState extends State<SuppliersListPage> {
  late SuppliersController controller;
  late ScrollController scrollController;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    // Initialize suppliers controller with dependencies
    Get.put(
      SuppliersController(
        getSuppliersUseCase: getIt<GetSuppliersUseCase>(),
        getSupplierByIdUseCase: getIt<GetSupplierByIdUseCase>(),
        createSupplierUseCase: getIt<CreateSupplierUseCase>(),
        updateSupplierUseCase: getIt<UpdateSupplierUseCase>(),
        deleteSupplierUseCase: getIt<DeleteSupplierUseCase>(),
      ),
      permanent: true,
    );
    controller = Get.find<SuppliersController>();
    scrollController = ScrollController();
    searchController = TextEditingController();

    // Setup scroll listener for pagination
    scrollController.addListener(_onScroll);

    // Setup search controller listener
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    searchController.removeListener(_onSearchChanged);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  /// Handle scroll events for pagination
  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      controller.loadMoreSuppliers();
    }
  }

  /// Handle search text changes
  void _onSearchChanged() {
    controller.searchSuppliers(searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar with title and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Proveedores'),
      centerTitle: true,
      elevation: 0,
      actions: [
        // More options menu
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Actualizar'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConfig.paddingMedium),
      color: Get.theme.colorScheme.surface,
      child: CustomInput(
        controller: searchController,
        hintText: 'Buscar por nombre, teléfono, email...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Obx(
          () => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    controller.clearSearch();
                  },
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Build main body with suppliers list
  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value && controller.suppliers.isEmpty) {
        return const LoadingWidget(message: 'Cargando proveedores...');
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.suppliers.isEmpty) {
        return _buildErrorState();
      }

      if (controller.suppliers.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshSuppliers,
        child: ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount:
              controller.suppliers.length +
              (controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= controller.suppliers.length) {
              return const Padding(
                padding: EdgeInsets.all(AppConfig.paddingMedium),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final supplier = controller.suppliers[index];
            return SupplierCard(
              supplier: supplier,
              onTap: () => _navigateToSupplierDetail(supplier.id),
            );
          },
        ),
      );
    });
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConfig.paddingMedium),
          Text(
            'No hay proveedores registrados',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppConfig.paddingSmall),
          Text(
            'Crea tu primer proveedor usando el botón +',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Get.theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Get.theme.colorScheme.error,
          ),
          const SizedBox(height: AppConfig.paddingMedium),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConfig.paddingLarge,
            ),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: AppConfig.paddingMedium),
          ElevatedButton.icon(
            onPressed: () => controller.loadSuppliers(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Build floating action button (only for admin)
  Widget? _buildFloatingActionButton() {
    // Check if AuthController is available
    try {
      final authController = Get.find<AuthController>();

      // Only show FAB to administrators
      if (!authController.isAdmin) {
        return null;
      }

      return FloatingActionButton(
        onPressed: _showCreateSupplierDialog,
        tooltip: 'Crear proveedor',
        child: const Icon(Icons.add),
      );
    } catch (e) {
      // If AuthController is not found, don't show FAB
      return null;
    }
  }

  /// Handle menu selection
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        controller.refreshSuppliers();
        break;
    }
  }

  /// Navigate to supplier detail page
  void _navigateToSupplierDetail(String supplierId) {
    Get.toNamed('/suppliers/$supplierId');
  }

  /// Show create supplier dialog
  void _showCreateSupplierDialog() {
    final nombreController = TextEditingController();
    final celularController = TextEditingController();
    final emailController = TextEditingController();
    final direccionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Crear Proveedor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomInput(
                controller: nombreController,
                hintText: 'Nombre *',
                prefixIcon: const Icon(Icons.person),
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              CustomInput(
                controller: celularController,
                hintText: 'Celular',
                prefixIcon: const Icon(Icons.phone),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              CustomInput(
                controller: emailController,
                hintText: 'Email',
                prefixIcon: const Icon(Icons.email),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppConfig.paddingMedium),
              CustomInput(
                controller: direccionController,
                hintText: 'Dirección',
                prefixIcon: const Icon(Icons.location_on),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isCreating.value
                  ? null
                  : () async {
                      if (nombreController.text.trim().isEmpty) {
                        Get.snackbar(
                          'Error',
                          'El nombre es obligatorio',
                          snackPosition: SnackPosition.TOP,
                        );
                        return;
                      }

                      print('🔵 Calling createSupplier...');
                      final success = await controller.createSupplier(
                        nombre: nombreController.text.trim(),
                        celular: celularController.text.trim().isNotEmpty
                            ? celularController.text.trim()
                            : null,
                        email: emailController.text.trim().isNotEmpty
                            ? emailController.text.trim()
                            : null,
                        direccion: direccionController.text.trim().isNotEmpty
                            ? direccionController.text.trim()
                            : null,
                      );

                      print('🔵 createSupplier returned: $success');
                      if (success) {
                        print('🔵 Calling Get.back() to close dialog...');
                        Get.back();
                        print('🔵 Get.back() called');
                      } else {
                        print('🔴 Creation failed, not closing dialog');
                      }
                    },
              child: controller.isCreating.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear'),
            ),
          ),
        ],
      ),
    );
  }
}
