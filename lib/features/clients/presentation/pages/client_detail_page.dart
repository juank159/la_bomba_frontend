//lib /features/clients/presentation/pages/client_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedidos_frontend/app/config/routes.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_input.dart';
import '../controllers/clients_controller.dart';
import '../../domain/entities/client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// ClientDetailPage - Page showing client details with edit functionality
class ClientDetailPage extends StatefulWidget {
  final String clientId;

  const ClientDetailPage({super.key, required this.clientId});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  late ClientsController controller;
  late TextEditingController nombreController;
  late TextEditingController celularController;
  late TextEditingController emailController;
  late TextEditingController direccionController;

  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ClientsController>();
    nombreController = TextEditingController();
    celularController = TextEditingController();
    emailController = TextEditingController();
    direccionController = TextEditingController();

    // Clear previous client data and load new one after build
    controller.clearSelectedClient();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getClientById(widget.clientId);
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

  void _loadClientData(Client client) {
    nombreController.text = client.nombre;
    celularController.text = client.celular ?? '';
    emailController.text = client.email ?? '';
    direccionController.text = client.direccion ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget(message: 'Cargando cliente...');
        }

        final client = controller.selectedClient.value;
        if (client == null) {
          return _buildErrorState();
        }

        // Load client data into controllers
        if (!isEditing) {
          _loadClientData(client);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConfig.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientHeader(client),
              const SizedBox(height: AppConfig.paddingLarge),
              _buildClientForm(client),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Detalle del Cliente'),
      centerTitle: true,
      actions: [
        Obx(() {
          final client = controller.selectedClient.value;
          if (client == null) return const SizedBox.shrink();

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
                      _loadClientData(client);
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

  Widget _buildClientHeader(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Get.theme.colorScheme.primaryContainer,
              child: Text(
                client.initials,
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
                    client.nombre,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.statusText,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: client.isActive ? Colors.green : Colors.red,
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

  Widget _buildClientForm(Client client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Cliente',
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
          const Text('No se pudo cargar el cliente'),
          const SizedBox(height: AppConfig.paddingMedium),
          ElevatedButton.icon(
            onPressed: () => controller.getClientById(widget.clientId),
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

    final success = await controller.updateClient(
      id: widget.clientId,
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
      Get.offNamed(AppRoutes.clients);
      //Get.back(); // Navigate back to clients list
    }
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este cliente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Close dialog
              final success = await controller.deleteClient(widget.clientId);
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
