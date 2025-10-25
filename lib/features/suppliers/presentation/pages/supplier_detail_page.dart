//lib /features/suppliers/presentation/pages/supplier_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidos_frontend/app/config/routes.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../controllers/suppliers_controller.dart';
import '../../domain/entities/supplier.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// SupplierDetailPage - Page showing supplier details with edit functionality
class SupplierDetailPage extends StatefulWidget {
  final String supplierId;

  const SupplierDetailPage({super.key, required this.supplierId});

  @override
  State<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends State<SupplierDetailPage> {
  late SuppliersController controller;
  late TextEditingController nombreController;
  late TextEditingController celularController;
  late TextEditingController emailController;
  late TextEditingController direccionController;

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SuppliersController>();
    nombreController = TextEditingController();
    celularController = TextEditingController();
    emailController = TextEditingController();
    direccionController = TextEditingController();

    // Clear previous supplier data and load new one after build
    controller.clearSelectedSupplier();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getSupplierById(widget.supplierId);
    });
  }

  @override
  void dispose() {
    nombreController.dispose();
    celularController.dispose();
    emailController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  void _loadSupplierData(Supplier supplier) {
    nombreController.text = supplier.nombre;
    celularController.text = supplier.celular ?? '';
    emailController.text = supplier.email ?? '';
    direccionController.text = supplier.direccion ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget(message: 'Cargando proveedor...');
        }

        final supplier = controller.selectedSupplier.value;
        if (supplier == null) {
          return _buildErrorState();
        }

        // Load supplier data into controllers
        if (!isEditing) {
          _loadSupplierData(supplier);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSupplierHeader(supplier),
              const SizedBox(height: AppConfig.paddingLarge),
              _buildSupplierForm(supplier),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Detalle del Proveedor'),
      centerTitle: true,
      actions: [
        Obx(() {
          final supplier = controller.selectedSupplier.value;
          if (supplier == null) return const SizedBox.shrink();

          // Check if user is admin
          bool isAdmin = false;
          try {
            final authController = Get.find<AuthController>();
            isAdmin = authController.isAdmin;
          } catch (e) {
            // AuthController not found, assume not admin
            isAdmin = false;
          }

          // Only admins can edit and delete
          if (!isAdmin) {
            return const SizedBox.shrink();
          }

          if (isEditing) {
            return Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      isEditing = false;
                      _loadSupplierData(supplier);
                    });
                  },
                  tooltip: 'Cancelar',
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveChanges,
                  tooltip: 'Guardar',
                ),
              ],
            );
          }

          return PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSupplierHeader(Supplier supplier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              child: Text(
                supplier.initials,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Get.theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: AppConfig.paddingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.nombre,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplier.statusText,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: supplier.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierForm(Supplier supplier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Proveedor',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            CustomInput(
              controller: nombreController,
              hintText: 'Nombre *',
              prefixIcon: const Icon(Icons.person),
              enabled: isEditing,
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            CustomInput(
              controller: celularController,
              hintText: 'Celular',
              prefixIcon: const Icon(Icons.phone),
              keyboardType: TextInputType.phone,
              enabled: isEditing,
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            CustomInput(
              controller: emailController,
              hintText: 'Email',
              prefixIcon: const Icon(Icons.email),
              keyboardType: TextInputType.emailAddress,
              enabled: isEditing,
            ),
            const SizedBox(height: AppConfig.paddingMedium),
            CustomInput(
              controller: direccionController,
              hintText: 'Dirección',
              prefixIcon: const Icon(Icons.location_on),
              maxLines: 3,
              enabled: isEditing,
            ),
          ],
        ),
      ),
    );
  }

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
          const Text('No se pudo cargar el proveedor'),
          const SizedBox(height: AppConfig.paddingMedium),
          ElevatedButton.icon(
            onPressed: () => controller.getSupplierById(widget.supplierId),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'edit':
        setState(() {
          isEditing = true;
        });
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _saveChanges() async {
    if (nombreController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'El nombre es obligatorio',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final success = await controller.updateSupplier(
      id: widget.supplierId,
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

    if (success) {
      Get.offNamed(AppRoutes.suppliers);
      //Get.back(); // Navigate back to suppliers list
    }
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Proveedor'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este proveedor?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog
              final success = await controller.deleteSupplier(widget.supplierId);
              if (success) {
                Get.back(); // Go back to list
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
