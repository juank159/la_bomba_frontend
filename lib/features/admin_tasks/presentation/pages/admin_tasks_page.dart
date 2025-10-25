// lib/features/admin_tasks/presentation/pages/admin_tasks_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_tasks_controller.dart';
import '../../domain/entities/temporary_product.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/core/utils/price_input_formatter.dart';
import '../../../../app/core/utils/number_formatter.dart';

class AdminTasksPage extends StatefulWidget {
  const AdminTasksPage({super.key});

  @override
  State<AdminTasksPage> createState() => _AdminTasksPageState();
}

class _AdminTasksPageState extends State<AdminTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdminTasksController>(
      init: Get.put(AdminTasksController()),
      builder: (controller) => Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Tareas de Administrador'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.refreshData(),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.pending_actions), text: 'Pendientes'),
              Tab(icon: Icon(Icons.check_circle), text: 'Completadas'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingTasksTab(controller),
            _buildCompletedTasksTab(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTasksTab(AdminTasksController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.loadPendingTasks(),
      child: Obx(() {
        if (controller.isLoadingPending) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.pendingTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay productos temporales pendientes',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pendingTasks.length,
          itemBuilder: (context, index) {
            final task = controller.pendingTasks[index];
            return _buildTaskCard(task, controller, showActions: true);
          },
        );
      }),
    );
  }

  Widget _buildCompletedTasksTab(AdminTasksController controller) {
    // Load completed tasks when tab is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.completedTasks.isEmpty && !controller.isLoadingCompleted) {
        controller.loadCompletedTasks();
      }
    });

    return RefreshIndicator(
      onRefresh: () => controller.loadCompletedTasks(),
      child: Obx(() {
        if (controller.isLoadingCompleted) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.completedTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay tareas completadas o canceladas',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.completedTasks.length,
          itemBuilder: (context, index) {
            final task = controller.completedTasks[index];
            return _buildCompletedTaskCard(task);
          },
        );
      }),
    );
  }

  Widget _buildTaskCard(
    TemporaryProduct task,
    AdminTasksController controller, {
    required bool showActions,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetails(context, task, controller),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),

              const SizedBox(height: 8),

              if (task.notes != null && task.notes!.isNotEmpty) ...[
                Text(
                  'Notas: ${task.notes}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                task.formattedTimeSinceCreation,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),

              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () =>
                            _showCancelTaskDialog(context, controller, task),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('No llegó'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showCompleteTaskDialog(context, controller, task),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Llegó'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedTaskCard(TemporaryProduct task) {
    Color statusColor;
    IconData statusIcon;

    if (task.isCancelled) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (task.isPendingSupervisor) {
      statusColor = Colors.blue;
      statusIcon = Icons.pending;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCompletedTaskDetails(context, task),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y estado
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),

              const SizedBox(height: 8),

              // Detalles del producto (solo si tiene precios)
              if (task.hasAllRequiredFields) ...[
                // Precios en una sola línea
                Text(
                  'Precio A: ${NumberFormatter.formatCurrency(task.precioA)} | IVA: ${NumberFormatter.formatPercentage(task.iva)}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),

                // Precios adicionales si existen
                if (task.precioB != null || task.precioC != null || task.costo != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (task.precioB != null)
                        Text(
                          'Precio B: ${NumberFormatter.formatCurrency(task.precioB)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      if (task.precioC != null)
                        Text(
                          'Precio C: ${NumberFormatter.formatCurrency(task.precioC)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      if (task.costo != null)
                        Text(
                          'Costo: ${NumberFormatter.formatCurrency(task.costo)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],

              // Información de completado
              if (task.completedByAdminAt != null)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Completado ${_formatCompletionTime(task.completedByAdminAt!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TemporaryProductStatus status) {
    Color chipColor;
    switch (status) {
      case TemporaryProductStatus.pendingAdmin:
        chipColor = Colors.orange;
        break;
      case TemporaryProductStatus.pendingSupervisor:
        chipColor = Colors.blue;
        break;
      case TemporaryProductStatus.completed:
        chipColor = Colors.green;
        break;
      case TemporaryProductStatus.cancelled:
        chipColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatCompletionTime(DateTime completedAt) {
    final now = DateTime.now();
    final difference = now.difference(completedAt);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace unos segundos';
    }
  }

  void _showTaskDetails(
    BuildContext context,
    TemporaryProduct task,
    AdminTasksController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Producto Temporal'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', task.name),
              if (task.description != null)
                _buildDetailRow('Descripción:', task.description!),
              if (task.barcode != null)
                _buildDetailRow('Código de barras:', task.barcode!),
              if (task.notes != null && task.notes!.isNotEmpty)
                _buildDetailRow('Notas:', task.notes!),
              _buildDetailRow('Estado:', task.status.displayName),
              _buildDetailRow('Creado:', task.formattedTimeSinceCreation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (task.isPendingAdmin) ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCancelTaskDialog(context, controller, task);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('No llegó'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCompleteTaskDialog(context, controller, task);
              },
              child: const Text('Llegó'),
            ),
          ],
        ],
      ),
    );
  }

  void _showCompletedTaskDetails(BuildContext context, TemporaryProduct task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del Producto'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', task.name),
              if (task.description != null)
                _buildDetailRow('Descripción:', task.description!),
              if (task.barcode != null)
                _buildDetailRow('Código:', task.barcode!),
              _buildDetailRow('Estado:', task.status.displayName),
              if (task.hasAllRequiredFields) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Información de Precios',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Precio A:',
                  NumberFormatter.formatCurrency(task.precioA),
                ),
                if (task.precioB != null)
                  _buildDetailRow(
                    'Precio B:',
                    NumberFormatter.formatCurrency(task.precioB),
                  ),
                if (task.precioC != null)
                  _buildDetailRow(
                    'Precio C:',
                    NumberFormatter.formatCurrency(task.precioC),
                  ),
                if (task.costo != null)
                  _buildDetailRow(
                    'Costo:',
                    NumberFormatter.formatCurrency(task.costo),
                  ),
                _buildDetailRow(
                  'IVA:',
                  NumberFormatter.formatPercentage(task.iva),
                ),
              ],
              if (task.completedByAdminAt != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Completado:',
                  _formatCompletionTime(task.completedByAdminAt!),
                ),
              ],
              if (task.notes != null && task.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Notas:', task.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCompleteTaskDialog(
    BuildContext context,
    AdminTasksController controller,
    TemporaryProduct task,
  ) {
    final precioAController = TextEditingController();
    final precioBController = TextEditingController();
    final precioCController = TextEditingController();
    final costoController = TextEditingController();
    final ivaController = TextEditingController();
    final descriptionController = TextEditingController(text: task.description);
    final barcodeController = TextEditingController(text: task.barcode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Producto Llegó - Completar Información'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Producto: ${task.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: precioAController,
                keyboardType: TextInputType.number,
                inputFormatters: [PriceInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Precio A (requerido) *',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                  hintText: '10.000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ivaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'IVA % (requerido) *',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioBController,
                keyboardType: TextInputType.number,
                inputFormatters: [PriceInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Precio B (opcional)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                  hintText: '8.000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioCController,
                keyboardType: TextInputType.number,
                inputFormatters: [PriceInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Precio C (opcional)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                  hintText: '5.000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costoController,
                keyboardType: TextInputType.number,
                inputFormatters: [PriceInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Costo (opcional)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                  hintText: '3.000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Código de barras (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isCompletingTask
                  ? null
                  : () {
                      // Parse formatted prices
                      final precioA = precioAController.text.isNotEmpty
                          ? PriceFormatter.parse(precioAController.text)
                          : null;
                      final iva = double.tryParse(ivaController.text);

                      if (precioA == null || precioA == 0 || iva == null) {
                        Get.snackbar(
                          'Error',
                          'Precio A e IVA son requeridos y deben ser mayores a 0',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Get.theme.colorScheme.error
                              .withValues(alpha: 0.1),
                          colorText: Get.theme.colorScheme.error,
                        );
                        return;
                      }

                      Navigator.of(context).pop();
                      controller.completeTask(
                        taskId: task.id,
                        precioA: precioA,
                        iva: iva,
                        precioB: precioBController.text.isNotEmpty
                            ? PriceFormatter.parse(precioBController.text)
                            : null,
                        precioC: precioCController.text.isNotEmpty
                            ? PriceFormatter.parse(precioCController.text)
                            : null,
                        costo: costoController.text.isNotEmpty
                            ? PriceFormatter.parse(costoController.text)
                            : null,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        barcode: barcodeController.text.trim().isEmpty
                            ? null
                            : barcodeController.text.trim(),
                      );
                    },
              child: controller.isCompletingTask
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Completar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelTaskDialog(
    BuildContext context,
    AdminTasksController controller,
    TemporaryProduct task,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Producto No Llegó'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Confirmas que el producto "${task.name}" NO llegó?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: Proveedor canceló pedido',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isCancellingTask
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      controller.cancelTask(
                        taskId: task.id,
                        reason: reasonController.text.trim().isEmpty
                            ? null
                            : reasonController.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: controller.isCancellingTask
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar Cancelación'),
            ),
          ),
        ],
      ),
    );
  }
}
